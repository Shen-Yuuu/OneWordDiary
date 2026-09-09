import { describe, expect, it } from '@ohos/hypium';
import { StylePresetId } from '../main/ets/constants/StyleTokens';
import { BackupError, BackupErrorCode } from '../main/ets/model/BackupError';
import { DailyRecord, RecordType } from '../main/ets/model/DailyRecord';
import { AppSettings, DEFAULT_APP_SETTINGS, ReminderSettings } from '../main/ets/model/Settings';
import { InMemoryDiaryRepository } from '../main/ets/repository/DiaryRepository';
import { SettingsRepository } from '../main/ets/repository/SettingsRepository';
import { BackupCodec } from '../main/ets/service/BackupCodec';
import { BackupFileGateway } from '../main/ets/service/BackupFileGateway';
import { BackupService } from '../main/ets/service/BackupService';
import { DiaryTextRules } from '../main/ets/service/DiaryTextRules';
import { FixedClock } from '../main/ets/utils/Clock';
import { BackupViewModel } from '../main/ets/viewmodel/BackupViewModel';

class MemoryBackupSettingsRepository implements SettingsRepository {
  stylePresetId: StylePresetId = StylePresetId.PAPER_INK;
  privacyPolicyAcceptedVersion: string = '';

  async load(): Promise<AppSettings> {
    return {
      stylePresetId: this.stylePresetId,
      reminder: {
        enabled: DEFAULT_APP_SETTINGS.reminder.enabled,
        hour: DEFAULT_APP_SETTINGS.reminder.hour,
        minute: DEFAULT_APP_SETTINGS.reminder.minute,
        reminderId: DEFAULT_APP_SETTINGS.reminder.reminderId,
        permissionRequested: DEFAULT_APP_SETTINGS.reminder.permissionRequested
      },
      privacyPolicyAcceptedVersion: this.privacyPolicyAcceptedVersion
    };
  }

  async saveStylePresetId(stylePresetId: StylePresetId): Promise<void> {
    this.stylePresetId = stylePresetId;
  }

  async saveReminder(reminder: ReminderSettings): Promise<void> {
  }

  async savePrivacyPolicyAcceptedVersion(version: string): Promise<void> {
    this.privacyPolicyAcceptedVersion = version;
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

class MemoryBackupFileGateway implements BackupFileGateway {
  private readonly files: Map<string, string> = new Map<string, string>();
  readError: BackupError | null = null;
  writeError: BackupError | null = null;

  readUtf8(uri: string, maxBytes: number): string {
    if (this.readError !== null) {
      throw this.readError;
    }
    const text = this.files.get(uri);
    if (text === undefined) {
      throw new BackupError(BackupErrorCode.READ_FAILED, 'missing file');
    }
    return text;
  }

  writeUtf8(uri: string, text: string, maxBytes: number): void {
    if (this.writeError !== null) {
      throw this.writeError;
    }
    this.files.set(uri, text);
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

async function expectServiceBackupError(action: () => Promise<void>, expectedCode: BackupErrorCode): Promise<void> {
  let actualCode: BackupErrorCode | null = null;
  try {
    await action();
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
      const service = new BackupService(repository, settings, new FixedClock(1000), codec, new MemoryBackupFileGateway());
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
      const service = new BackupService(repository, settings, new FixedClock(1000), codec, new MemoryBackupFileGateway());
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
      const service = new BackupService(repository, settings, new FixedClock(1000), codec, new MemoryBackupFileGateway());
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

    it('exportsAndImportsAcrossDifferentRepositoriesWithoutWritingDuringPreparation', 0, async () => {
      const gateway = new MemoryBackupFileGateway();
      const exporterRepository = new InMemoryDiaryRepository();
      const importerRepository = new InMemoryDiaryRepository();
      const exporter = new BackupService(
        exporterRepository,
        new MemoryBackupSettingsRepository(),
        new FixedClock(1000),
        new BackupCodec(new DiaryTextRules()),
        gateway
      );
      const importer = new BackupService(
        importerRepository,
        new MemoryBackupSettingsRepository(),
        new FixedClock(1000),
        new BackupCodec(new DiaryTextRules()),
        gateway
      );
      await exporterRepository.insert(createRecord('2026-08-21', '静'));

      const exported = await exporter.exportToUri('file://docs/export.oneword');
      const plan = await importer.prepareImportFromUri('file://docs/export.oneword');
      expect(exported).assertEqual(1);
      expect(plan.importedCount).assertEqual(1);
      expect(await importerRepository.countAll()).assertEqual(0);

      const result = await importer.applyImport(plan);
      expect(result.importedCount).assertEqual(1);
      expect((await importerRepository.findByDate('2026-08-21'))?.content).assertEqual('静');
    });

    it('preservesGatewayErrorCodesAndMapsThemToViewModelMessages', 0, async () => {
      const gateway = new MemoryBackupFileGateway();
      const service = new BackupService(
        new InMemoryDiaryRepository(),
        new MemoryBackupSettingsRepository(),
        new FixedClock(1000),
        new BackupCodec(new DiaryTextRules()),
        gateway
      );
      const viewModel = new BackupViewModel(service);

      gateway.writeError = new BackupError(BackupErrorCode.WRITE_FAILED, 'write failed');
      await expectServiceBackupError(
        async (): Promise<void> => { await service.exportToUri('file://docs/export.oneword'); },
        BackupErrorCode.WRITE_FAILED
      );
      expect(await viewModel.exportToUri('file://docs/export.oneword')).assertFalse();
      expect(viewModel.errorMessage).assertEqual('无法写入所选位置，请重新选择');

      gateway.writeError = null;
      gateway.readError = new BackupError(BackupErrorCode.READ_FAILED, 'read failed');
      await expectServiceBackupError(
        async (): Promise<void> => { await service.prepareImportFromUri('file://docs/import.oneword'); },
        BackupErrorCode.READ_FAILED
      );
      expect(await viewModel.prepareImport('file://docs/import.oneword')).assertFalse();
      expect(viewModel.errorMessage).assertEqual('无法读取所选文件，请重新选择');

      gateway.readError = new BackupError(BackupErrorCode.FILE_TOO_LARGE, 'too large');
      await expectServiceBackupError(
        async (): Promise<void> => { await service.prepareImportFromUri('file://docs/import.oneword'); },
        BackupErrorCode.FILE_TOO_LARGE
      );
      expect(await viewModel.prepareImport('file://docs/import.oneword')).assertFalse();
      expect(viewModel.errorMessage).assertEqual('文件超过 5 MiB，未读取任何记录');
    });

    it('clearsStaleErrorsAfterSuccessfulExportAndImportPreparation', 0, async () => {
      const gateway = new MemoryBackupFileGateway();
      const repository = new InMemoryDiaryRepository();
      const service = new BackupService(
        repository,
        new MemoryBackupSettingsRepository(),
        new FixedClock(1000),
        new BackupCodec(new DiaryTextRules()),
        gateway
      );
      const viewModel = new BackupViewModel(service);
      gateway.writeError = new BackupError(BackupErrorCode.WRITE_FAILED, 'write failed');
      await viewModel.exportToUri('file://docs/export.oneword');
      expect(viewModel.errorMessage).assertEqual('无法写入所选位置，请重新选择');

      gateway.writeError = null;
      expect(await viewModel.exportToUri('file://docs/export.oneword')).assertTrue();
      expect(viewModel.errorMessage).assertEqual('');

      gateway.readError = new BackupError(BackupErrorCode.READ_FAILED, 'read failed');
      await viewModel.prepareImport('file://docs/export.oneword');
      expect(viewModel.errorMessage).assertEqual('无法读取所选文件，请重新选择');

      gateway.readError = null;
      expect(await viewModel.prepareImport('file://docs/export.oneword')).assertTrue();
      expect(viewModel.errorMessage).assertEqual('');
    });
  });
}
