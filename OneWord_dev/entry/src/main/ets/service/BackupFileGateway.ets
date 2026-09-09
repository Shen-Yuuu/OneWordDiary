import { buffer } from '@kit.ArkTS';
import { fileIo } from '@kit.CoreFileKit';
import { BackupError, BackupErrorCode } from '../model/BackupError';

export interface BackupFileGateway {
  readUtf8(uri: string, maxBytes: number): string;
  writeUtf8(uri: string, text: string, maxBytes: number): void;
}

export interface BackupFilePort {
  open(uri: string, mode: number): number;
  statSize(fd: number): number;
  read(fd: number, target: ArrayBuffer): number;
  write(fd: number, source: ArrayBuffer): number;
  close(fd: number): void;
}

export class CoreFileKitBackupFilePort implements BackupFilePort {
  open(uri: string, mode: number): number {
    return fileIo.openSync(uri, mode).fd;
  }

  statSize(fd: number): number {
    return fileIo.statSync(fd).size;
  }

  read(fd: number, target: ArrayBuffer): number {
    return fileIo.readSync(fd, target);
  }

  write(fd: number, source: ArrayBuffer): number {
    return fileIo.writeSync(fd, source);
  }

  close(fd: number): void {
    fileIo.closeSync(fd);
  }
}

export class DocumentUriBackupFileGateway implements BackupFileGateway {
  private static readonly DEFAULT_CHUNK_BYTES: number = 16 * 1024;
  private readonly port: BackupFilePort;
  private readonly chunkBytes: number;

  constructor(
    port: BackupFilePort = new CoreFileKitBackupFilePort(),
    chunkBytes: number = DocumentUriBackupFileGateway.DEFAULT_CHUNK_BYTES
  ) {
    this.port = port;
    this.chunkBytes = Math.max(1, chunkBytes);
  }

  readUtf8(uri: string, maxBytes: number): string {
    try {
      const fd: number = this.port.open(uri, fileIo.OpenMode.READ_ONLY);
      let operationError: Error | null = null;
      try {
        const reportedSize: number = this.port.statSize(fd);
        this.ensureWithinLimit(reportedSize, maxBytes);

        const chunks: buffer.Buffer[] = [];
        let totalBytes: number = 0;
        while (true) {
          const remaining: number = maxBytes - totalBytes;
          const targetSize: number = Math.min(this.chunkBytes, Math.max(1, remaining));
          const target: ArrayBuffer = new ArrayBuffer(targetSize);
          const bytesRead: number = this.port.read(fd, target);
          if (bytesRead === 0) {
            break;
          }
          if (bytesRead < 0 || bytesRead > target.byteLength) {
            throw new Error('invalid read result');
          }
          totalBytes += bytesRead;
          this.ensureWithinLimit(totalBytes, maxBytes);
          chunks.push(buffer.from(target, 0, bytesRead));
        }
        return buffer.concat(chunks, totalBytes).toString('utf8');
      } catch (error) {
        const thrown: Error = error as Error;
        operationError = thrown;
        throw thrown;
      } finally {
        try {
          this.port.close(fd);
        } catch (error) {
          if (operationError === null) {
            throw error as Error;
          }
        }
      }
    } catch (error) {
      throw this.mapError(error as Error, BackupErrorCode.READ_FAILED, '备份文件暂时无法读取');
    }
  }

  writeUtf8(uri: string, text: string, maxBytes: number): void {
    const encoded: buffer.Buffer = buffer.from(text, 'utf8');
    try {
      this.ensureWithinLimit(encoded.length, maxBytes);
    } catch (error) {
      throw this.mapError(error as Error, BackupErrorCode.WRITE_FAILED, '备份文件未能写入');
    }

    try {
      const fd: number = this.port.open(uri, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC);
      let operationError: Error | null = null;
      try {
        let writtenBytes: number = 0;
        while (writtenBytes < encoded.length) {
          const end: number = Math.min(writtenBytes + this.chunkBytes, encoded.length);
          const source: ArrayBuffer = buffer.from(encoded.subarray(writtenBytes, end)).buffer;
          const bytesWritten: number = this.port.write(fd, source);
          if (bytesWritten <= 0 || bytesWritten > source.byteLength) {
            throw new Error('invalid write result');
          }
          writtenBytes += bytesWritten;
        }
      } catch (error) {
        const thrown: Error = error as Error;
        operationError = thrown;
        throw thrown;
      } finally {
        try {
          this.port.close(fd);
        } catch (error) {
          if (operationError === null) {
            throw error as Error;
          }
        }
      }
    } catch (error) {
      throw this.mapError(error as Error, BackupErrorCode.WRITE_FAILED, '备份文件未能写入');
    }
  }

  private ensureWithinLimit(size: number, maxBytes: number): void {
    if (maxBytes < 0 || size > maxBytes) {
      throw new BackupError(BackupErrorCode.FILE_TOO_LARGE, '备份文件超过大小上限');
    }
  }

  private mapError(error: Error, fallbackCode: BackupErrorCode, message: string): BackupError {
    if (error instanceof BackupError) {
      return error;
    }
    return new BackupError(fallbackCode, message);
  }
}
