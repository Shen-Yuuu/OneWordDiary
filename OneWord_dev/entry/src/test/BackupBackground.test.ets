import { describe, expect, it } from '@ohos/hypium';
import { StylePresetId } from '../main/ets/constants/StyleTokens';
import {
  BackgroundImageBackupData,
  BackgroundImageBackupStore
} from '../main/ets/model/BackgroundImage';
import { BackupError, BackupErrorCode } from '../main/ets/model/BackupError';
import { DailyRecord, RecordType } from '../main/ets/model/DailyRecord';
import { AppSettings, DEFAULT_APP_SETTINGS, ReminderSettings } from '../main/ets/model/Settings';
import { InMemoryDiaryRepository } from '../main/ets/repository/DiaryRepository';
import { SettingsRepository } from '../main/ets/repository/SettingsRepository';
import { AppResetService } from '../main/ets/service/AppResetService';
import { BackupCodec } from '../main/ets/service/BackupCodec';
import { BackupService } from '../main/ets/service/BackupService';
import { DiaryTextRules } from '../main/ets/service/DiaryTextRules';
import { ReminderScheduler } from '../main/ets/service/ReminderScheduler';
import { FixedClock } from '../main/ets/utils/Clock';

const IMAGE_DATA: BackgroundImageBackupData = {
  mimeType: 'image/jpeg',
  byteLength: 3,
  dataBase64: '/9j/'
};
const SOURCE_IMAGE_ID: string = '11111111111111111111111111111111.jpg';

class BackgroundBackupSettingsRepository implements SettingsRepository {
  stylePresetId: StylePresetId = StylePresetId.PAPER_INK;
  resetPending: boolean = false;

  async load(): Promise<AppSettings> {
    return {
      stylePresetId: this.stylePresetId,
      reminder: DEFAULT_APP_SETTINGS.reminder,
      privacyPolicyAcceptedVersion: ''
    };
  }

  async saveStylePresetId(stylePresetId: StylePresetId): Promise<void> {
    this.stylePresetId = stylePresetId;
  }

  async saveReminder(reminder: ReminderSettings): Promise<void> {
  }

  async savePrivacyPolicyAcceptedVersion(version: string): Promise<void> {
  }

  async isResetPending(): Promise<boolean> {
    return this.resetPending;
  }

  async markResetPending(): Promise<void> {
    this.resetPending = true;
  }

  async reset(): Promise<void> {
    this.stylePresetId = StylePresetId.PAPER_INK;
    this.resetPending = false;
  }
}

class FakeBackgroundImageBackupStore implements BackgroundImageBackupStore {
  readonly removedIds: string[] = [];
  clearCount: number = 0;
  failNextClear: boolean = false;
  private nextId: number = 1;

  async importFromUri(uri: string): Promise<string> {
    return this.makeId();
  }

  resolveUri(id: string | null | undefined): string {
    return id === null || id === undefined ? '' : 'file:///' + id;
  }

  remove(id: string): void {
    this.removedIds.push(id);
  }

  clearAll(): void {
    this.clearCount++;
    if (this.failNextClear) {
      this.failNextClear = false;
      throw new Error('injected image deletion failure');
    }
  }

  async readForBackup(id: string): Promise<BackgroundImageBackupData> {
    return IMAGE_DATA;
  }

  async importFromBackup(data: BackgroundImageBackupData): Promise<string> {
    return this.makeId();
  }

  removeMany(ids: string[]): void {
    ids.forEach((id: string) => this.remove(id));
  }

  cleanupOrphans(referencedIds: Set<string>): void {
  }

  private makeId(): string {
    const value = this.nextId.toString();
    const serial = '00000000000000000000000000000000'.substring(value.length) + value;
    this.nextId++;
    return `${serial}.jpg`;
  }
}

class NoopBackgroundReminderScheduler implements ReminderScheduler {
  async isNotificationEnabled(): Promise<boolean> {
    return false;
  }

  async requestNotificationPermission(): Promise<void> {
  }

  async publishDaily(hour: number, minute: number): Promise<number> {
    return -1;
  }

  async cancel(reminderId: number): Promise<void> {
  }

  async cancelAll(): Promise<void> {
  }

  async hasValidReminder(): Promise<boolean> {
    return false;
  }
}

class FailingBackgroundImportRepository extends InMemoryDiaryRepository {
  failDate: string = '';

  async insert(record: DailyRecord): Promise<void> {
    if (record.localDate === this.failDate) {
      throw new Error('injected database failure');
    }
    await super.insert(record);
  }
}

function record(localDate: string, content: string, withImage: boolean = false): DailyRecord {
  return {
    localDate: localDate,
    content: content,
    note: null,
    recordType: RecordType.WORD,
    fontId: 'system_serif_dev',
    paperId: 'warm_paper_dev',
    backgroundImageId: withImage ? SOURCE_IMAGE_ID : null,
    submittedAt: 100,
    submittedTimezoneOffset: 480,
    revisionDeadlineAt: 200,
    revisedAt: null,
    revisionUsed: false,
    schemaVersion: 1
  };
}

function imageMap(localDates: string[]): Map<string, BackgroundImageBackupData> {
  const result = new Map<string, BackgroundImageBackupData>();
  localDates.forEach((localDate: string) => result.set(localDate, IMAGE_DATA));
  return result;
}

function expectDecodeError(codec: BackupCodec, text: string, code: BackupErrorCode): void {
  let actual: BackupErrorCode | null = null;
  try {
    codec.decode(text);
  } catch (error) {
    if (error instanceof BackupError) actual = error.code;
  }
  expect(actual).assertEqual(code);
}

export default function backupBackgroundTest(): void {
  describe('BackupBackground', () => {
    it('roundTripsLegacyV1AndImageV2Documents', 0, () => {
      const codec = new BackupCodec(new DiaryTextRules());
      const legacyText = codec.encode([record('2026-08-20', '静')], StylePresetId.PAPER_INK, 1000);
      expect(legacyText.includes('"format_version":1')).assertTrue();
      expect(codec.decode(legacyText).imagesByDate.size).assertEqual(0);

      const imageText = codec.encode(
        [record('2026-08-21', '雨', true)],
        StylePresetId.PLAIN_ASH,
        1000,
        imageMap(['2026-08-21'])
      );
      const decoded = codec.decode(imageText);
      expect(imageText.includes('"format_version":2')).assertTrue();
      expect(decoded.records.length).assertEqual(1);
      expect(decoded.imagesByDate.get('2026-08-21')?.dataBase64).assertEqual('/9j/');
      expect(decoded.stylePresetId).assertEqual(StylePresetId.PLAIN_ASH);
    });

    it('rejectsMissingPayloadAndMalformedImageMetadata', 0, () => {
      const codec = new BackupCodec(new DiaryTextRules());
      const encoded = codec.encode(
        [record('2026-08-21', '雨', true)],
        StylePresetId.PAPER_INK,
        1000,
        imageMap(['2026-08-21'])
      );
      const imageField = ',"background_image":{"mimeType":"image/jpeg","byteLength":3,"dataBase64":"/9j/"}';
      expectDecodeError(codec, encoded.replace(imageField, ''), BackupErrorCode.INVALID_RECORD);
      expectDecodeError(codec, encoded.replace('"byteLength":3', '"byteLength":4'),
        BackupErrorCode.INVALID_IMAGE);
    });

    it('removesStagedImageWhenAConflictAppearsAfterPlanning', 0, async () => {
      const repository = new InMemoryDiaryRepository();
      const settings = new BackgroundBackupSettingsRepository();
      const store = new FakeBackgroundImageBackupStore();
      const codec = new BackupCodec(new DiaryTextRules());
      const service = new BackupService(repository, settings, new FixedClock(1000), codec, store);
      const encoded = codec.encode(
        [record('2026-08-21', '备份', true)],
        StylePresetId.PAPER_INK,
        1000,
        imageMap(['2026-08-21'])
      );
      const plan = await service.prepareImportFromText(encoded);
      await repository.insert(record('2026-08-21', '本机'));

      const result = await service.applyImport(plan);

      expect(result.importedCount).assertEqual(0);
      expect(result.skippedCount).assertEqual(1);
      expect(store.removedIds.length).assertEqual(1);
      expect((await repository.findByDate('2026-08-21'))?.content).assertEqual('本机');
    });

    it('rollsBackDatabaseAndEveryStagedImageWhenInsertFails', 0, async () => {
      const repository = new FailingBackgroundImportRepository();
      repository.failDate = '2026-08-20';
      const settings = new BackgroundBackupSettingsRepository();
      const store = new FakeBackgroundImageBackupStore();
      const codec = new BackupCodec(new DiaryTextRules());
      const service = new BackupService(repository, settings, new FixedClock(1000), codec, store);
      const encoded = codec.encode(
        [record('2026-08-21', '静', true), record('2026-08-20', '雨', true)],
        StylePresetId.PAPER_INK,
        1000,
        imageMap(['2026-08-21', '2026-08-20'])
      );
      let errorCode: BackupErrorCode | null = null;
      try {
        await service.applyImport(await service.prepareImportFromText(encoded));
      } catch (error) {
        if (error instanceof BackupError) errorCode = error.code;
      }

      expect(errorCode).assertEqual(BackupErrorCode.IMPORT_FAILED);
      expect(await repository.countAll()).assertEqual(0);
      expect(store.removedIds.length).assertEqual(2);
    });

    it('keepsResetPendingUntilFailedImageCleanupSucceedsOnStartupRetry', 0, async () => {
      const repository = new InMemoryDiaryRepository();
      const settings = new BackgroundBackupSettingsRepository();
      const store = new FakeBackgroundImageBackupStore();
      const resetService = new AppResetService(
        repository,
        settings,
        new NoopBackgroundReminderScheduler(),
        store
      );
      await repository.insert(record('2026-08-21', '静', true));
      store.failNextClear = true;
      let failed: boolean = false;
      try {
        await resetService.clearAll();
      } catch (error) {
        failed = true;
      }

      expect(failed).assertTrue();
      expect(settings.resetPending).assertTrue();
      expect(store.clearCount).assertEqual(1);

      await resetService.resumeIfNeeded();
      expect(store.clearCount).assertEqual(2);
      expect(settings.resetPending).assertFalse();
      expect(await repository.countAll()).assertEqual(0);
    });
  });
}
