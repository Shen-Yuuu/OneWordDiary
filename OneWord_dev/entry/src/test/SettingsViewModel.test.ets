import { describe, expect, it } from '@ohos/hypium';
import { StylePresetId } from '../main/ets/constants/StyleTokens';
import { DailyRecord, RecordType } from '../main/ets/model/DailyRecord';
import { AppSettings, DEFAULT_APP_SETTINGS, ReminderSettings } from '../main/ets/model/Settings';
import { SettingsUiState } from '../main/ets/model/SettingsUiState';
import { InMemoryDiaryRepository } from '../main/ets/repository/DiaryRepository';
import { SettingsRepository } from '../main/ets/repository/SettingsRepository';
import { AppResetService } from '../main/ets/service/AppResetService';
import { ReminderScheduler } from '../main/ets/service/ReminderScheduler';
import { SettingsViewModel } from '../main/ets/viewmodel/SettingsViewModel';

class MemorySettingsRepository implements SettingsRepository {
  settings: AppSettings = {
    stylePresetId: DEFAULT_APP_SETTINGS.stylePresetId,
    reminder: MemorySettingsRepository.cloneReminder(DEFAULT_APP_SETTINGS.reminder),
    privacyPolicyAcceptedVersion: ''
  };
  privacyPolicyAcceptedVersion: string = '';
  resetPending: boolean = false;

  async load(): Promise<AppSettings> {
    return {
      stylePresetId: this.settings.stylePresetId,
      reminder: MemorySettingsRepository.cloneReminder(this.settings.reminder),
      privacyPolicyAcceptedVersion: this.settings.privacyPolicyAcceptedVersion
    };
  }

  async saveStylePresetId(stylePresetId: StylePresetId): Promise<void> {
    this.settings = {
      stylePresetId: stylePresetId,
      reminder: MemorySettingsRepository.cloneReminder(this.settings.reminder),
      privacyPolicyAcceptedVersion: this.settings.privacyPolicyAcceptedVersion
    };
  }

  async saveReminder(reminder: ReminderSettings): Promise<void> {
    this.settings = {
      stylePresetId: this.settings.stylePresetId,
      reminder: MemorySettingsRepository.cloneReminder(reminder),
      privacyPolicyAcceptedVersion: this.settings.privacyPolicyAcceptedVersion
    };
  }

  async savePrivacyPolicyAcceptedVersion(version: string): Promise<void> {
    this.privacyPolicyAcceptedVersion = version;
    this.settings = {
      stylePresetId: this.settings.stylePresetId,
      reminder: MemorySettingsRepository.cloneReminder(this.settings.reminder),
      privacyPolicyAcceptedVersion: version
    };
  }
  async isResetPending(): Promise<boolean> {
    return this.resetPending;
  }

  async markResetPending(): Promise<void> {
    this.resetPending = true;
  }

  async reset(): Promise<void> {
    this.settings = {
      stylePresetId: DEFAULT_APP_SETTINGS.stylePresetId,
      reminder: MemorySettingsRepository.cloneReminder(DEFAULT_APP_SETTINGS.reminder),
      privacyPolicyAcceptedVersion: ''
    };
    this.privacyPolicyAcceptedVersion = '';
    this.resetPending = false;
  }

  private static cloneReminder(reminder: ReminderSettings): ReminderSettings {
    return {
      enabled: reminder.enabled,
      hour: reminder.hour,
      minute: reminder.minute,
      reminderId: reminder.reminderId,
      permissionRequested: reminder.permissionRequested
    };
  }
}

class FakeReminderScheduler implements ReminderScheduler {
  notificationEnabled: boolean = false;
  validReminder: boolean = false;
  requestFails: boolean = false;
  publishFails: boolean = false;
  nextReminderId: number = 42;
  cancelledReminderId: number = -1;
  cancelAllCount: number = 0;

  async isNotificationEnabled(): Promise<boolean> {
    return this.notificationEnabled;
  }

  async requestNotificationPermission(): Promise<void> {
    if (this.requestFails) {
      throw new Error('permission denied');
    }
    this.notificationEnabled = true;
  }

  async publishDaily(hour: number, minute: number): Promise<number> {
    if (this.publishFails) {
      throw new Error('publish failed');
    }
    this.validReminder = true;
    return this.nextReminderId;
  }

  async cancel(reminderId: number): Promise<void> {
    this.cancelledReminderId = reminderId;
  }

  async cancelAll(): Promise<void> {
    this.cancelAllCount += 1;
    this.validReminder = false;
  }

  async hasValidReminder(): Promise<boolean> {
    return this.validReminder;
  }
}

class SettingsFixture {
  readonly diaryRepository: InMemoryDiaryRepository = new InMemoryDiaryRepository();
  readonly settingsRepository: MemorySettingsRepository = new MemorySettingsRepository();
  readonly scheduler: FakeReminderScheduler = new FakeReminderScheduler();
  readonly resetService: AppResetService = new AppResetService(
    this.diaryRepository,
    this.settingsRepository,
    this.scheduler
  );
  readonly viewModel: SettingsViewModel = new SettingsViewModel(
    this.settingsRepository,
    this.scheduler,
    this.resetService
  );
}

function createRecord(): DailyRecord {
  return {
    localDate: '2026-08-20',
    content: '静',
    note: null,
    recordType: RecordType.WORD,
    fontId: 'system_serif_dev',
    paperId: 'warm_paper_dev',
    submittedAt: 1,
    submittedTimezoneOffset: 480,
    revisionDeadlineAt: 2,
    revisedAt: null,
    revisionUsed: false,
    schemaVersion: 1
  };
}

export default function settingsViewModelTest(): void {
  describe('SettingsViewModel', () => {
    it('switchesStyleWithoutChangingReminder', 0, async () => {
      const fixture = new SettingsFixture();
      await fixture.viewModel.load();
      await fixture.viewModel.selectStyle(StylePresetId.PLAIN_ASH);
      expect(fixture.viewModel.stylePresetId).assertEqual(StylePresetId.PLAIN_ASH);
      expect(fixture.settingsRepository.settings.reminder.enabled).assertFalse();
    });

    it('requestsPermissionOnlyWhenEnablingAndPublishesDailyReminder', 0, async () => {
      const fixture = new SettingsFixture();
      await fixture.viewModel.load();
      expect(fixture.scheduler.notificationEnabled).assertFalse();
      await fixture.viewModel.enableReminder();
      expect(fixture.scheduler.notificationEnabled).assertTrue();
      expect(fixture.viewModel.reminder.enabled).assertTrue();
      expect(fixture.viewModel.reminder.reminderId).assertEqual(42);
      expect(fixture.viewModel.uiState).assertEqual(SettingsUiState.READY);
    });

    it('keepsReminderOffWhenPermissionIsDenied', 0, async () => {
      const fixture = new SettingsFixture();
      fixture.scheduler.requestFails = true;
      await fixture.viewModel.load();
      await fixture.viewModel.enableReminder();
      expect(fixture.viewModel.reminder.enabled).assertFalse();
      expect(fixture.viewModel.reminder.permissionRequested).assertTrue();
      expect(fixture.viewModel.uiState).assertEqual(SettingsUiState.REMINDER_PERMISSION_DENIED);
    });

    it('keepsReminderIntentWhenPublishingFails', 0, async () => {
      const fixture = new SettingsFixture();
      fixture.scheduler.notificationEnabled = true;
      fixture.scheduler.publishFails = true;
      await fixture.viewModel.load();
      await fixture.viewModel.enableReminder();
      expect(fixture.viewModel.reminder.enabled).assertTrue();
      expect(fixture.viewModel.reminder.reminderId).assertEqual(-1);
      expect(fixture.viewModel.uiState).assertEqual(SettingsUiState.REMINDER_SCHEDULE_ERROR);
    });

    it('replacesTheExistingReminderWhenTimeChanges', 0, async () => {
      const fixture = new SettingsFixture();
      fixture.scheduler.notificationEnabled = true;
      await fixture.viewModel.load();
      await fixture.viewModel.enableReminder();
      fixture.scheduler.nextReminderId = 77;
      await fixture.viewModel.changeReminderTime(22, 30);
      expect(fixture.scheduler.cancelledReminderId).assertEqual(42);
      expect(fixture.viewModel.reminder.reminderId).assertEqual(77);
      expect(fixture.viewModel.reminderTimeLabel).assertEqual('22:30');
    });

    it('clearsRecordsSettingsAndReminderTogether', 0, async () => {
      const fixture = new SettingsFixture();
      fixture.scheduler.notificationEnabled = true;
      await fixture.diaryRepository.insert(createRecord());
      await fixture.viewModel.load();
      await fixture.viewModel.enableReminder();
      const cleared = await fixture.viewModel.clearAll();
      expect(cleared).assertTrue();
      expect(await fixture.diaryRepository.countAll()).assertEqual(0);
      expect(fixture.settingsRepository.settings.stylePresetId).assertEqual(StylePresetId.PAPER_INK);
      expect(fixture.settingsRepository.settings.reminder.enabled).assertFalse();
      expect(fixture.scheduler.cancelAllCount).assertEqual(1);
      expect(fixture.settingsRepository.resetPending).assertFalse();
    });

    it('resumesAnInterruptedResetOnNextStartup', 0, async () => {
      const fixture = new SettingsFixture();
      fixture.scheduler.notificationEnabled = true;
      await fixture.diaryRepository.insert(createRecord());
      await fixture.settingsRepository.saveStylePresetId(StylePresetId.PLAIN_ASH);
      await fixture.settingsRepository.saveReminder({
        enabled: true,
        hour: 21,
        minute: 0,
        reminderId: 42,
        permissionRequested: true
      });
      await fixture.settingsRepository.markResetPending();
      await fixture.resetService.resumeIfNeeded();
      expect(await fixture.diaryRepository.countAll()).assertEqual(0);
      expect(fixture.settingsRepository.settings.stylePresetId).assertEqual(StylePresetId.PAPER_INK);
      expect(fixture.settingsRepository.settings.reminder.enabled).assertFalse();
      expect(fixture.scheduler.cancelAllCount).assertEqual(1);
      expect(fixture.settingsRepository.resetPending).assertFalse();
    });
  });
}
