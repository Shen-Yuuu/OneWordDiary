import { describe, expect, it } from '@ohos/hypium';
import { StylePresetId } from '../main/ets/constants/StyleTokens';
import { BackupError, BackupErrorCode } from '../main/ets/model/BackupError';
import { DailyRecord, RecordType } from '../main/ets/model/DailyRecord';
import { AppSettings, DEFAULT_APP_SETTINGS, ReminderSettings } from '../main/ets/model/Settings';
import { InMemoryDiaryRepository } from '../main/ets/repository/DiaryRepository';
import { SettingsRepository } from '../main/ets/repository/SettingsRepository';
import { BackupCodec } from '../main/ets/service/BackupCodec';
import { BackupService } from '../main/ets/service/BackupService';
import { DiaryTextRules } from '../main/ets/service/DiaryTextRules';
import { FixedClock } from '../main/ets/utils/Clock';

class MemoryBackupSettingsRepository implements SettingsRepository {
  stylePresetId: StylePresetId = StylePresetId.PAPER_INK;

  async load(): Promise<AppSettings> {
    return {
      stylePresetId: this.stylePresetId,
      reminder: {
        enabled: DEFAULT_APP_SETTINGS.reminder.enabled,
        hour: DEFAULT_APP_SETTINGS.reminder.hour,
        minute: DEFAULT_APP_SETTINGS.reminder.minute,
        reminderId: DEFAULT_APP_SETTINGS.reminder.reminderId,
        permissionRequested: DEFAULT_APP_SETTINGS.reminder.permissionRequested
      }
    };
  }

  async saveStylePresetId(stylePresetId: StylePresetId): Promise<void> {
    this.stylePresetId = stylePresetId;
  }

  async saveReminder(reminder: ReminderSettings): Promise<void> {
  }

  async isResetPending(): Promise<boolean> {
    return false;
  }

  async markResetPending(): Promise<void> {
  }

  async reset(): Promise<void> {
    this.stylePresetId = StylePresetId.PAPER_INK;
  }
}

class FailingDiaryRepository extends InMemoryDiaryRepository {
  failDate: string = '';

  async insert(record: DailyRecord): Promise<void> {
    if (record.localDate === this.failDate) {
      throw new Error('injected insert failure');
    }
    await super.insert(record);
  }
}

function createRecord(
  localDate: string,
  content: string | null,
  note: string | null = null,
  recordType: RecordType = RecordType.WORD
): DailyRecord {
  return {
    localDate: localDate,
    content: content,
    note: note,
    recordType: recordType,
    fontId: 'system_serif_dev',
    paperId: 'warm_paper_dev',
    submittedAt: 100,
    submittedTimezoneOffset: 480,
    revisionDeadlineAt: 200,
    revisedAt: null,
    revisionUsed: false,
    schemaVersion: 1
  };
}

function expectBackupError(codec: BackupCodec, text: string, expectedCode: BackupErrorCode): void {
  let actualCode: BackupErrorCode | null = null;
  try {
    codec.decode(text);
  } catch (error) {
    if (error instanceof BackupError) {
      actualCode = error.code;
    }
  }
  expect(actualCode).assertEqual(expectedCode);
}

export default function backupTest(): void {
  describe('Backup', () => {
    it('roundTripsWordBlankNoteAndHistoricalStyle', 0, () => {
      const codec = new BackupCodec(new DiaryTextRules());
      const blank = createRecord('2026-08-20', null, null, RecordType.BLANK);
      blank.fontId = 'system_sans_dev';
      blank.paperId = 'plain_ash_dev';
      const text = codec.encode([
        createRecord('2026-08-21', '静', '听见雨声'),
        blank
      ], StylePresetId.PLAIN_ASH, 1000);
      const decoded = codec.decode(text);
      expect(decoded.records.length).assertEqual(2);
      expect(decoded.records[0].content).assertEqual('静');
      expect(decoded.records[0].note).assertEqual('听见雨声');
      expect(decoded.records[1].recordType).assertEqual(RecordType.BLANK);
      expect(decoded.stylePresetId).assertEqual(StylePresetId.PLAIN_ASH);
    });

    it('rejectsDamagedUnknownDuplicateAndInvalidRecords', 0, () => {
      const codec = new BackupCodec(new DiaryTextRules());
      const valid = codec.encode([createRecord('2026-08-21', '静')], StylePresetId.PAPER_INK, 1000);
      expectBackupError(codec, '{broken', BackupErrorCode.INVALID_JSON);
      expectBackupError(codec, valid.replace('"format_version":1', '"format_version":2'),
        BackupErrorCode.UNSUPPORTED_VERSION);
      expectBackupError(codec, valid.replace('2026-08-21', '2026-02-30'), BackupErrorCode.INVALID_RECORD);
      expectBackupError(codec, codec.encode([
        createRecord('2026-08-21', '静'),
        createRecord('2026-08-21', '雨')
      ], StylePresetId.PAPER_INK, 1000), BackupErrorCode.DUPLICATE_DATE);
      expectBackupError(codec, valid.replace('"content":"静"', '"content":"一二三四五"'),
        BackupErrorCode.INVALID_RECORD);
      expectBackupError(codec, valid.replace('"revision_used":false', '"revision_used":true'),
        BackupErrorCode.INVALID_RECORD);
    });

    it('keepsLocalConflictsAndCurrentStyle', 0, async () => {
      const repository = new InMemoryDiaryRepository();
      const settings = new MemoryBackupSettingsRepository();
      const codec = new BackupCodec(new DiaryTextRules());
      const service = new BackupService(repository, settings, new FixedClock(1000), codec);
      await repository.insert(createRecord('2026-08-21', '本机'));
      const text = codec.encode([
        createRecord('2026-08-21', '备份'),
        createRecord('2026-08-20', '新记')
      ], StylePresetId.PLAIN_ASH, 1000);
      const plan = await service.prepareImportFromText(text);
      expect(plan.importedCount).assertEqual(1);
      expect(plan.skippedCount).assertEqual(1);
      expect(plan.restoreStyle).assertFalse();
      const result = await service.applyImport(plan);
      expect(result.importedCount).assertEqual(1);
      expect(result.skippedCount).assertEqual(1);
      expect((await repository.findByDate('2026-08-21'))?.content).assertEqual('本机');
      expect(settings.stylePresetId).assertEqual(StylePresetId.PAPER_INK);
    });

    it('restoresBackupStyleOnlyForAnEmptyLocalDiary', 0, async () => {
      const repository = new InMemoryDiaryRepository();
      const settings = new MemoryBackupSettingsRepository();
      const codec = new BackupCodec(new DiaryTextRules());
      const service = new BackupService(repository, settings, new FixedClock(1000), codec);
      const text = codec.encode([createRecord('2026-08-21', '静')], StylePresetId.PLAIN_ASH, 1000);
      const result = await service.applyImport(await service.prepareImportFromText(text));
      expect(result.importedCount).assertEqual(1);
      expect(result.styleRestored).assertTrue();
      expect(settings.stylePresetId).assertEqual(StylePresetId.PLAIN_ASH);
    });

    it('rollsBackEveryRecordWhenOneInsertFails', 0, async () => {
      const repository = new FailingDiaryRepository();
      repository.failDate = '2026-08-20';
      const settings = new MemoryBackupSettingsRepository();
      const codec = new BackupCodec(new DiaryTextRules());
      const service = new BackupService(repository, settings, new FixedClock(1000), codec);
      const text = codec.encode([
        createRecord('2026-08-21', '静'),
        createRecord('2026-08-20', '雨')
      ], StylePresetId.PLAIN_ASH, 1000);
      let actualCode: BackupErrorCode | null = null;
      try {
        await service.applyImport(await service.prepareImportFromText(text));
      } catch (error) {
        if (error instanceof BackupError) {
          actualCode = error.code;
        }
      }
      expect(actualCode).assertEqual(BackupErrorCode.IMPORT_FAILED);
      expect(await repository.countAll()).assertEqual(0);
      expect(settings.stylePresetId).assertEqual(StylePresetId.PAPER_INK);
    });
  });
}
