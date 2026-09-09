import { describe, expect, it } from '@ohos/hypium';
import { StylePresetId } from '../main/ets/constants/StyleTokens';
import {
  BackgroundImageBackupData,
  BackgroundImageBackupStore
} from '../main/ets/model/BackgroundImage';
import { DailyRecord, RecordType } from '../main/ets/model/DailyRecord';
import { AppSettings, DEFAULT_APP_SETTINGS, ReminderSettings } from '../main/ets/model/Settings';
import { InMemoryDiaryRepository } from '../main/ets/repository/DiaryRepository';
import { SettingsRepository } from '../main/ets/repository/SettingsRepository';
import { AppResetService } from '../main/ets/service/AppResetService';
import { ReminderScheduler } from '../main/ets/service/ReminderScheduler';

class BackgroundResetSettingsRepository implements SettingsRepository {
  resetPending: boolean = false;

  async load(): Promise<AppSettings> {
    return {
      stylePresetId: DEFAULT_APP_SETTINGS.stylePresetId,
      reminder: DEFAULT_APP_SETTINGS.reminder,
      privacyPolicyAcceptedVersion: ''
    };
  }

  async saveStylePresetId(stylePresetId: StylePresetId): Promise<void> {
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
    this.resetPending = false;
  }
}

class FakeBackgroundImageStore implements BackgroundImageBackupStore {
  clearCount: number = 0;
  failNextClear: boolean = false;

  async importFromUri(uri: string): Promise<string> {
    return '11111111111111111111111111111111.jpg';
  }

  resolveUri(id: string | null | undefined): string {
    return id === null || id === undefined ? '' : 'file:///' + id;
  }

  remove(id: string): void {
  }

  clearAll(): void {
    this.clearCount++;
    if (this.failNextClear) {
      this.failNextClear = false;
      throw new Error('injected image deletion failure');
    }
  }

  async readForBackup(id: string): Promise<BackgroundImageBackupData> {
    throw new Error('backup image transport is disabled');
  }

  async importFromBackup(data: BackgroundImageBackupData): Promise<string> {
    throw new Error('backup image transport is disabled');
  }

  removeMany(ids: string[]): void {
  }

  cleanupOrphans(referencedIds: Set<string>): void {
  }
}

class NoopReminderScheduler implements ReminderScheduler {
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

function recordWithBackground(localDate: string): DailyRecord {
  return {
    localDate: localDate,
    content: '静',
    note: null,
    recordType: RecordType.WORD,
    fontId: 'system_serif_dev',
    paperId: 'warm_paper_dev',
    backgroundImageId: '11111111111111111111111111111111.jpg',
    submittedAt: 100,
    submittedTimezoneOffset: 480,
    revisionDeadlineAt: 200,
    revisedAt: null,
    revisionUsed: false,
    schemaVersion: 1
  };
}

export default function backgroundResetTest(): void {
  describe('BackgroundReset', () => {
    it('keepsResetPendingUntilFailedImageCleanupSucceedsOnStartupRetry', 0, async () => {
      const repository = new InMemoryDiaryRepository();
      const settings = new BackgroundResetSettingsRepository();
      const store = new FakeBackgroundImageStore();
      const resetService = new AppResetService(
        repository,
        settings,
        new NoopReminderScheduler(),
        store
      );
      await repository.insert(recordWithBackground('2026-08-21'));
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
