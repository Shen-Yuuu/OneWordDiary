import { fileIo } from '@kit.CoreFileKit';
import { buffer } from '@kit.ArkTS';
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

  constructor(
    diaryRepository: DiaryRepository,
    settingsRepository: SettingsRepository,
    clock: Clock,
    codec: BackupCodec
  ) {
    this.diaryRepository = diaryRepository;
    this.settingsRepository = settingsRepository;
    this.clock = clock;
    this.codec = codec;
  }

  async exportToUri(uri: string): Promise<number> {
    try {
      const records = await this.diaryRepository.findPageBefore(null, BackupCodec.MAX_RECORDS + 1);
      const settings = await this.settingsRepository.load();
      const text = this.codec.encode(records, settings.stylePresetId, this.clock.now());
      if (buffer.byteLength(text, 'utf8') > BackupCodec.MAX_FILE_BYTES) {
        throw new BackupError(BackupErrorCode.FILE_TOO_LARGE, '备份内容超过文件上限');
      }
      const file = fileIo.openSync(uri, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.TRUNC);
      try {
        fileIo.writeSync(file.fd, text, { encoding: 'utf-8' });
      } finally {
        fileIo.closeSync(file);
      }
      return records.length;
    } catch (error) {
      if (error instanceof BackupError) {
        throw error;
      }
      throw new BackupError(BackupErrorCode.WRITE_FAILED, '备份文件未能写入');
    }
  }

  async prepareImportFromUri(uri: string): Promise<BackupImportPlan> {
    let text: string;
    try {
      const stat = fileIo.statSync(uri);
      if (stat.size > BackupCodec.MAX_FILE_BYTES) {
        throw new BackupError(BackupErrorCode.FILE_TOO_LARGE, '备份文件超过 5 MiB');
      }
      text = fileIo.readTextSync(uri, { encoding: 'utf-8' });
    } catch (error) {
      if (error instanceof BackupError) {
        throw error;
      }
      throw new BackupError(BackupErrorCode.READ_FAILED, '备份文件暂时无法读取');
    }
    return this.prepareImportFromText(text);
  }

  async prepareImportFromText(text: string): Promise<BackupImportPlan> {
    const decoded = this.codec.decode(text);
    return this.createImportPlan(decoded);
  }

  async applyImport(plan: BackupImportPlan): Promise<BackupImportResult> {
    let importedCount: number = 0;
    let skippedCount: number = plan.skippedCount;
    const localCountBefore = await this.diaryRepository.countAll();
    try {
      await this.diaryRepository.runInTransaction(async (): Promise<void> => {
        for (let index = 0; index < plan.records.length; index++) {
          const record = plan.records[index];
          const existing = await this.diaryRepository.findByDate(record.localDate);
          if (existing !== null) {
            skippedCount++;
          } else {
            await this.diaryRepository.insert(record);
            importedCount++;
          }
        }
      });
    } catch (error) {
      throw new BackupError(BackupErrorCode.IMPORT_FAILED, '导入未完成，本机记录保持不变');
    }

    let styleRestored: boolean = false;
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
    const localDates: Set<string> = new Set<string>();
    localRecords.forEach((record: DailyRecord) => {
      localDates.add(record.localDate);
    });
    const missingRecords: DailyRecord[] = [];
    let skippedCount: number = 0;
    decoded.records.forEach((record: DailyRecord) => {
      if (localDates.has(record.localDate)) {
        skippedCount++;
      } else {
        missingRecords.push(record);
      }
    });
    return new BackupImportPlan(
      missingRecords,
      missingRecords.length,
      skippedCount,
      localRecords.length === 0,
      decoded.stylePresetId
    );
  }
}

