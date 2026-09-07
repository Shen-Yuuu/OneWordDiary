import { buffer } from '@kit.ArkTS';
import { fileIo } from '@kit.CoreFileKit';
import {
  BackgroundImageBackupData,
  BackgroundImageBackupStore,
  BackgroundImageError,
  BackgroundImageErrorCode
} from '../model/BackgroundImage';
import { BackupError, BackupErrorCode } from '../model/BackupError';
import { BackupImportPlan, BackupImportResult, DecodedBackup } from '../model/BackupModel';
import { DailyRecord } from '../model/DailyRecord';
import { DiaryRepository } from '../repository/DiaryRepository';
import { SettingsRepository } from '../repository/SettingsRepository';
import { Clock } from '../utils/Clock';
import { BackupCodec } from './BackupCodec';

export class BackupService {
  private readonly diaryRepository: DiaryRepository;
  private readonly settingsRepository: SettingsRepository;
  private readonly clock: Clock;
  private readonly codec: BackupCodec;
  private readonly imageStore: BackgroundImageBackupStore | null;

  constructor(
    diaryRepository: DiaryRepository,
    settingsRepository: SettingsRepository,
    clock: Clock,
    codec: BackupCodec,
    imageStore: BackgroundImageBackupStore | null = null
  ) {
    this.diaryRepository = diaryRepository;
    this.settingsRepository = settingsRepository;
    this.clock = clock;
    this.codec = codec;
    this.imageStore = imageStore;
  }

  async exportToUri(uri: string): Promise<number> {
    try {
      const records = await this.diaryRepository.findPageBefore(null, BackupCodec.MAX_RECORDS + 1);
      const settings = await this.settingsRepository.load();
      const imagesByDate = new Map<string, BackgroundImageBackupData>();
      let encodedImageBytes = 0;
      for (let index = 0; index < records.length; index++) {
        const record = records[index];
        if (record.backgroundImageId === null || record.backgroundImageId === undefined) continue;
        if (this.imageStore === null) {
          throw new BackupError(BackupErrorCode.IMAGE_MISSING,
            '日记包含背景图片，但图片存储暂不可用，未导出不完整备份');
        }
        let data: BackgroundImageBackupData;
        try {
          data = await this.imageStore.readForBackup(record.backgroundImageId);
        } catch (error) {
          throw new BackupError(BackupErrorCode.IMAGE_MISSING,
            '日记背景图片缺失或已损坏，未导出不完整备份');
        }
        encodedImageBytes += data.dataBase64.length;
        if (encodedImageBytes > BackupCodec.MAX_FILE_BYTES) {
          throw new BackupError(BackupErrorCode.FILE_TOO_LARGE, '含图片的备份不能超过 64 MiB');
        }
        imagesByDate.set(record.localDate, data);
      }
      const text = this.codec.encode(records, settings.stylePresetId, this.clock.now(), imagesByDate);
      const file = fileIo.openSync(uri, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.TRUNC);
      try {
        const expectedBytes = buffer.byteLength(text, 'utf8');
        const writtenBytes = fileIo.writeSync(file.fd, text, { encoding: 'utf-8' });
        if (writtenBytes !== expectedBytes) {
          throw new BackupError(BackupErrorCode.WRITE_FAILED, '备份文件未能完整写入');
        }
      } finally {
        fileIo.closeSync(file);
      }
      return records.length;
    } catch (error) {
      if (error instanceof BackupError) throw error;
      throw new BackupError(BackupErrorCode.WRITE_FAILED, '备份文件未能写入');
    }
  }

  async prepareImportFromUri(uri: string): Promise<BackupImportPlan> {
    let text: string;
    try {
      const stat = fileIo.statSync(uri);
      if (stat.size > BackupCodec.MAX_FILE_BYTES) {
        throw new BackupError(BackupErrorCode.FILE_TOO_LARGE, '备份文件超过 64 MiB');
      }
      text = fileIo.readTextSync(uri, { encoding: 'utf-8' });
    } catch (error) {
      if (error instanceof BackupError) throw error;
      throw new BackupError(BackupErrorCode.READ_FAILED, '备份文件暂时无法读取');
    }
    return this.prepareImportFromText(text);
  }

  async prepareImportFromText(text: string): Promise<BackupImportPlan> {
    if (buffer.byteLength(text, 'utf8') > BackupCodec.MAX_FILE_BYTES) {
      throw new BackupError(BackupErrorCode.FILE_TOO_LARGE, '备份文件超过 64 MiB');
    }
    return this.createImportPlan(this.codec.decode(text));
  }

  async applyImport(plan: BackupImportPlan): Promise<BackupImportResult> {
    const stagedIds: string[] = [];
    const skippedStagedIds: string[] = [];
    const stagedRecords: DailyRecord[] = [];
    let importedCount = 0;
    let skippedCount = plan.skippedCount;
    const localCountBefore = await this.diaryRepository.countAll();
    try {
      for (let index = 0; index < plan.records.length; index++) {
        const sourceRecord = plan.records[index];
        const imageData = plan.imagesByDate.get(sourceRecord.localDate);
        let newImageId: string | null = null;
        if (imageData !== undefined) {
          if (this.imageStore === null) {
            throw new BackupError(BackupErrorCode.INVALID_IMAGE, '无法恢复备份中的背景图片');
          }
          newImageId = await this.imageStore.importFromBackup(imageData);
          stagedIds.push(newImageId);
        }
        stagedRecords.push(this.withBackground(sourceRecord, newImageId));
      }
      await this.diaryRepository.runInTransaction(async (): Promise<void> => {
        for (let index = 0; index < stagedRecords.length; index++) {
          const record = stagedRecords[index];
          const existing = await this.diaryRepository.findByDate(record.localDate);
          if (existing !== null) {
            skippedCount++;
            if (record.backgroundImageId !== null && record.backgroundImageId !== undefined) {
              skippedStagedIds.push(record.backgroundImageId);
            }
          } else {
            await this.diaryRepository.insert(record);
            importedCount++;
          }
        }
      });
    } catch (error) {
      if (this.imageStore !== null) {
        try {
          this.imageStore.removeMany(stagedIds);
        } catch (cleanupError) {
        }
      }
      if (error instanceof BackupError) throw error;
      if (error instanceof BackgroundImageError) {
        if (error.code === BackgroundImageErrorCode.INVALID_IMAGE ||
          error.code === BackgroundImageErrorCode.ANIMATED_IMAGE ||
          error.code === BackgroundImageErrorCode.DIMENSIONS_TOO_LARGE ||
          error.code === BackgroundImageErrorCode.OUTPUT_TOO_LARGE) {
          throw new BackupError(BackupErrorCode.INVALID_IMAGE, error.message);
        }
        throw new BackupError(BackupErrorCode.IMPORT_FAILED, '无法保存备份中的背景图片');
      }
      throw new BackupError(BackupErrorCode.IMPORT_FAILED, '导入未完成，本机记录保持不变');
    }

    if (this.imageStore !== null && skippedStagedIds.length > 0) {
      try {
        this.imageStore.removeMany(skippedStagedIds);
      } catch (cleanupError) {
      }
    }

    let styleRestored = false;
    if (localCountBefore === 0 && plan.restoreStyle) {
      try {
        await this.settingsRepository.saveStylePresetId(plan.backupStyle);
        styleRestored = true;
      } catch (error) {
        styleRestored = false;
      }
    }
    return {
      importedCount: importedCount,
      skippedCount: skippedCount,
      styleRestored: styleRestored
    };
  }

  private async createImportPlan(decoded: DecodedBackup): Promise<BackupImportPlan> {
    const localRecords = await this.diaryRepository.findPageBefore(null, BackupCodec.MAX_RECORDS + 1);
    const localDates = new Set<string>();
    localRecords.forEach((record: DailyRecord) => localDates.add(record.localDate));
    const missingRecords: DailyRecord[] = [];
    const imagesByDate = new Map<string, BackgroundImageBackupData>();
    let skippedCount = 0;
    decoded.records.forEach((record: DailyRecord) => {
      if (localDates.has(record.localDate)) {
        skippedCount++;
      } else {
        missingRecords.push(record);
        const imageData = decoded.imagesByDate.get(record.localDate);
        if (imageData !== undefined) imagesByDate.set(record.localDate, imageData);
      }
    });
    return new BackupImportPlan(
      missingRecords,
      missingRecords.length,
      skippedCount,
      localRecords.length === 0,
      decoded.stylePresetId,
      imagesByDate
    );
  }

  private withBackground(record: DailyRecord, backgroundImageId: string | null): DailyRecord {
    return {
      localDate: record.localDate,
      content: record.content,
      note: record.note,
      recordType: record.recordType,
      fontId: record.fontId,
      paperId: record.paperId,
      backgroundImageId: backgroundImageId,
      submittedAt: record.submittedAt,
      submittedTimezoneOffset: record.submittedTimezoneOffset,
      revisionDeadlineAt: record.revisionDeadlineAt,
      revisedAt: record.revisedAt,
      revisionUsed: record.revisionUsed,
      schemaVersion: record.schemaVersion
    };
  }
}
