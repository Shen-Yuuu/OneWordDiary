import { describe, expect, it } from '@ohos/hypium';
import { StylePresetId } from '../main/ets/constants/StyleTokens';
import { FontPresetId } from '../main/ets/constants/FontCatalog';
import { AppSettings, ReminderSettings } from '../main/ets/model/Settings';
import { SettingsRepository } from '../main/ets/repository/SettingsRepository';
import { ReminderRetirementService } from '../main/ets/service/ReminderRetirementService';
import { ReminderScheduler } from '../main/ets/service/ReminderScheduler';

class RetirementSettingsRepository implements SettingsRepository {
  settings: AppSettings = {
    stylePresetId: StylePresetId.PAPER_INK,
    fontPresetId: FontPresetId.DEFAULT,
    reminder: {
      enabled: true,
      hour: 22,
      minute: 15,
      reminderId: 42,
      permissionRequested: true
    },
    privacyPolicyAcceptedVersion: '1.0'
  };

  async load(): Promise<AppSettings> {
    return this.settings;
  }

  async saveStylePresetId(stylePresetId: StylePresetId): Promise<void> {
    this.settings.stylePresetId = stylePresetId;
  }

  async saveFontPresetId(fontPresetId: FontPresetId): Promise<void> {
    this.settings.fontPresetId = fontPresetId;
  }

  async saveReminder(reminder: ReminderSettings): Promise<void> {
    this.settings.reminder = reminder;
  }

  async savePrivacyPolicyAcceptedVersion(version: string): Promise<void> {
    this.settings.privacyPolicyAcceptedVersion = version;
  }

  async isResetPending(): Promise<boolean> {
    return false;
  }

  async markResetPending(): Promise<void> {
  }

  async reset(): Promise<void> {
  }
}

class RetirementScheduler implements ReminderScheduler {
  cancelAllCount: number = 0;
  cancelFails: boolean = false;

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
    this.cancelAllCount += 1;
    if (this.cancelFails) {
      throw new Error('cancel failed');
    }
  }

  async hasValidReminder(): Promise<boolean> {
    return false;
  }
}

export default function reminderRetirementServiceTest(): void {
  describe('ReminderRetirementService', () => {
    it('cancelsScheduledRemindersAndPersistsDisabledState', 0, async () => {
      const repository = new RetirementSettingsRepository();
      const scheduler = new RetirementScheduler();
      await new ReminderRetirementService(repository, scheduler).retire();
      expect(scheduler.cancelAllCount).assertEqual(1);
      expect(repository.settings.reminder.enabled).assertFalse();
      expect(repository.settings.reminder.reminderId).assertEqual(-1);
      expect(repository.settings.reminder.hour).assertEqual(22);
      expect(repository.settings.reminder.minute).assertEqual(15);
      expect(repository.settings.reminder.permissionRequested).assertTrue();
    });

    it('remainsIdempotentWhenReminderIsAlreadyDisabled', 0, async () => {
      const repository = new RetirementSettingsRepository();
      repository.settings.reminder.enabled = false;
      repository.settings.reminder.reminderId = -1;
      const scheduler = new RetirementScheduler();
      const service = new ReminderRetirementService(repository, scheduler);
      await service.retire();
      await service.retire();
      expect(scheduler.cancelAllCount).assertEqual(2);
      expect(repository.settings.reminder.enabled).assertFalse();
      expect(repository.settings.reminder.reminderId).assertEqual(-1);
    });

    it('persistsDisabledStateWhenSystemCancellationFails', 0, async () => {
      const repository = new RetirementSettingsRepository();
      const scheduler = new RetirementScheduler();
      scheduler.cancelFails = true;
      await new ReminderRetirementService(repository, scheduler).retire();
      expect(scheduler.cancelAllCount).assertEqual(1);
      expect(repository.settings.reminder.enabled).assertFalse();
      expect(repository.settings.reminder.reminderId).assertEqual(-1);
    });
  });
}
