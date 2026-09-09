import { describe, expect, it } from '@ohos/hypium';
import { buffer } from '@kit.ArkTS';
import { fileIo } from '@kit.CoreFileKit';
import { BackupError, BackupErrorCode } from '../main/ets/model/BackupError';
import {
  BackupFilePort,
  DocumentUriBackupFileGateway
} from '../main/ets/service/BackupFileGateway';

class FakeBackupFilePort implements BackupFilePort {
  readonly input: buffer.Buffer;
  readonly written: number[] = [];
  readonly writeBufferSizes: number[] = [];
  readonly modes: number[] = [];
  maxReadBytes: number = 1024;
  maxWriteBytes: number = 1024;
  reportedSize: number;
  readCallCount: number = 0;
  writeCallCount: number = 0;
  closeCallCount: number = 0;
  failOpen: boolean = false;
  failReadOnCall: number = 0;
  failWriteOnCall: number = 0;
  returnZeroWrite: boolean = false;
  failClose: boolean = false;
  private readOffset: number = 0;

  constructor(text: string) {
    this.input = buffer.from(text, 'utf8');
    this.reportedSize = this.input.length;
  }

  open(uri: string, mode: number): number {
    if (this.failOpen) {
      throw new Error('open failed');
    }
    this.modes.push(mode);
    return 7;
  }

  statSize(fd: number): number {
    return this.reportedSize;
  }

  read(fd: number, target: ArrayBuffer): number {
    this.readCallCount++;
    if (this.failReadOnCall === this.readCallCount) {
      throw new Error('read failed');
    }
    const remaining: number = this.input.length - this.readOffset;
    const count: number = Math.min(remaining, target.byteLength, this.maxReadBytes);
    if (count <= 0) {
      return 0;
    }
    const targetBytes = new Uint8Array(target);
    const inputBytes = new Uint8Array(this.input.buffer, this.input.byteOffset + this.readOffset, count);
    targetBytes.set(inputBytes);
    this.readOffset += count;
    return count;
  }

  write(fd: number, source: ArrayBuffer): number {
    this.writeCallCount++;
    this.writeBufferSizes.push(source.byteLength);
    if (this.failWriteOnCall === this.writeCallCount) {
      throw new Error('write failed');
    }
    if (this.returnZeroWrite) {
      return 0;
    }
    const count: number = Math.min(source.byteLength, this.maxWriteBytes);
    const bytes = new Uint8Array(source, 0, count);
    for (let index = 0; index < bytes.length; index++) {
      this.written.push(bytes[index]);
    }
    return count;
  }

  close(fd: number): void {
    this.closeCallCount++;
    if (this.failClose) {
      throw new Error('close failed');
    }
  }

  writtenText(): string {
    return buffer.from(this.written).toString('utf8');
  }
}

function expectGatewayError(action: () => void, expected: BackupErrorCode): void {
  let actual: BackupErrorCode | null = null;
  try {
    action();
  } catch (error) {
    const backupError = error as BackupError;
    if (backupError instanceof BackupError) {
      actual = backupError.code;
    }
  }
  expect(actual).assertEqual(expected);
}

export default function backupFileGatewayTest(): void {
  describe('BackupFileGateway', () => {
    it('readsUtf8AcrossPartialReadsAndClosesTheDescriptor', 0, () => {
      const port = new FakeBackupFilePort('静雨');
      port.maxReadBytes = 2;
      const gateway = new DocumentUriBackupFileGateway(port, 2);

      expect(gateway.readUtf8('file://docs/import.oneword', 64)).assertEqual('静雨');
      expect(port.readCallCount > 1).assertTrue();
      expect(port.modes[0]).assertEqual(fileIo.OpenMode.READ_ONLY);
      expect(port.closeCallCount).assertEqual(1);
    });

    it('writesUtf8AcrossPartialWritesAndClosesTheDescriptor', 0, () => {
      const port = new FakeBackupFilePort('');
      port.maxWriteBytes = 2;
      const gateway = new DocumentUriBackupFileGateway(port, 4);

      gateway.writeUtf8('file://docs/export.oneword', '静雨', 64);
      expect(port.writeCallCount > 1).assertTrue();
      expect(port.writeBufferSizes[0]).assertEqual(4);
      expect(port.writeBufferSizes[port.writeBufferSizes.length - 1]).assertEqual(2);
      expect(port.writtenText()).assertEqual('静雨');
      expect(port.modes[0]).assertEqual(fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC);
      expect(port.closeCallCount).assertEqual(1);
    });

    it('rejectsReportedAndStreamedFilesOverTheLimit', 0, () => {
      const reportedTooLarge = new FakeBackupFilePort('静雨');
      reportedTooLarge.reportedSize = 65;
      expectGatewayError(
        (): void => { new DocumentUriBackupFileGateway(reportedTooLarge).readUtf8('file://docs/import.oneword', 64); },
        BackupErrorCode.FILE_TOO_LARGE
      );
      expect(reportedTooLarge.closeCallCount).assertEqual(1);

      const streamedTooLarge = new FakeBackupFilePort('静雨');
      streamedTooLarge.reportedSize = 0;
      expectGatewayError(
        (): void => { new DocumentUriBackupFileGateway(streamedTooLarge, 2).readUtf8('file://docs/import.oneword', 5); },
        BackupErrorCode.FILE_TOO_LARGE
      );
      expect(streamedTooLarge.closeCallCount).assertEqual(1);
    });

    it('acceptsEmptyAndExactlyLimitedFiles', 0, () => {
      const empty = new FakeBackupFilePort('');
      expect(new DocumentUriBackupFileGateway(empty, 2).readUtf8('file://docs/empty.oneword', 5)).assertEqual('');
      expect(empty.closeCallCount).assertEqual(1);

      const exactLimit = new FakeBackupFilePort('12345');
      exactLimit.reportedSize = 0;
      expect(new DocumentUriBackupFileGateway(exactLimit, 2).readUtf8('file://docs/exact.oneword', 5)).assertEqual('12345');
      expect(exactLimit.closeCallCount).assertEqual(1);
    });

    it('mapsReadFailuresAndClosesAfterAnOpen', 0, () => {
      const openFailure = new FakeBackupFilePort('静');
      openFailure.failOpen = true;
      expectGatewayError(
        (): void => { new DocumentUriBackupFileGateway(openFailure).readUtf8('file://docs/import.oneword', 64); },
        BackupErrorCode.READ_FAILED
      );
      expect(openFailure.closeCallCount).assertEqual(0);

      const readFailure = new FakeBackupFilePort('静雨');
      readFailure.maxReadBytes = 2;
      readFailure.failReadOnCall = 2;
      expectGatewayError(
        (): void => { new DocumentUriBackupFileGateway(readFailure, 2).readUtf8('file://docs/import.oneword', 64); },
        BackupErrorCode.READ_FAILED
      );
      expect(readFailure.closeCallCount).assertEqual(1);
    });

    it('mapsWriteAndZeroProgressFailuresAndClosesAfterAnOpen', 0, () => {
      const openFailure = new FakeBackupFilePort('');
      openFailure.failOpen = true;
      expectGatewayError(
        (): void => { new DocumentUriBackupFileGateway(openFailure).writeUtf8('file://docs/export.oneword', '静', 64); },
        BackupErrorCode.WRITE_FAILED
      );
      expect(openFailure.closeCallCount).assertEqual(0);

      const writeFailure = new FakeBackupFilePort('');
      writeFailure.maxWriteBytes = 2;
      writeFailure.failWriteOnCall = 2;
      expectGatewayError(
        (): void => { new DocumentUriBackupFileGateway(writeFailure, 2).writeUtf8('file://docs/export.oneword', '静雨', 64); },
        BackupErrorCode.WRITE_FAILED
      );
      expect(writeFailure.closeCallCount).assertEqual(1);

      const zeroProgress = new FakeBackupFilePort('');
      zeroProgress.returnZeroWrite = true;
      expectGatewayError(
        (): void => { new DocumentUriBackupFileGateway(zeroProgress).writeUtf8('file://docs/export.oneword', '静', 64); },
        BackupErrorCode.WRITE_FAILED
      );
      expect(zeroProgress.closeCallCount).assertEqual(1);
    });

    it('keepsPrimaryErrorsWhenCloseFailsAndMapsCloseOnlyFailures', 0, () => {
      const tooLarge = new FakeBackupFilePort('123456');
      tooLarge.reportedSize = 6;
      tooLarge.failClose = true;
      expectGatewayError(
        (): void => { new DocumentUriBackupFileGateway(tooLarge).readUtf8('file://docs/large.oneword', 5); },
        BackupErrorCode.FILE_TOO_LARGE
      );
      expect(tooLarge.closeCallCount).assertEqual(1);

      const readCloseOnly = new FakeBackupFilePort('ok');
      readCloseOnly.failClose = true;
      expectGatewayError(
        (): void => { new DocumentUriBackupFileGateway(readCloseOnly).readUtf8('file://docs/read.oneword', 5); },
        BackupErrorCode.READ_FAILED
      );

      const writeFailure = new FakeBackupFilePort('');
      writeFailure.failWriteOnCall = 1;
      writeFailure.failClose = true;
      expectGatewayError(
        (): void => { new DocumentUriBackupFileGateway(writeFailure).writeUtf8('file://docs/write.oneword', 'ok', 5); },
        BackupErrorCode.WRITE_FAILED
      );

      const writeCloseOnly = new FakeBackupFilePort('');
      writeCloseOnly.failClose = true;
      expectGatewayError(
        (): void => { new DocumentUriBackupFileGateway(writeCloseOnly).writeUtf8('file://docs/write-close.oneword', 'ok', 5); },
        BackupErrorCode.WRITE_FAILED
      );
    });
  });
}
