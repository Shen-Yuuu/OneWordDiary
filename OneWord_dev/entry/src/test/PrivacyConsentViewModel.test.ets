import { describe, expect, it } from '@ohos/hypium';
import { StylePresetId } from '../main/ets/constants/StyleTokens';
import { AppSettings, DEFAULT_APP_SETTINGS, ReminderSettings } from '../main/ets/model/Settings';
import { SettingsRepository } from '../main/ets/repository/SettingsRepository';
import { PrivacyConsentViewModel } from '../main/ets/viewmodel/PrivacyConsentViewModel';

class MemoryPrivacySettingsRepository implements SettingsRepository {
  privacyPolicyAcceptedVersion: string = '';
  loadFails: boolean = false;
  saveFails: boolean = false;

  async load(): Promise<AppSettings> {
    if (this.loadFails) {
      throw new Error('load failed');
    }
    return {
      stylePresetId: DEFAULT_APP_SETTINGS.stylePresetId,
      reminder: MemoryPrivacySettingsRepository.cloneReminder(DEFAULT_APP_SETTINGS.reminder),
      privacyPolicyAcceptedVersion: this.privacyPolicyAcceptedVersion
    };
  }

  async savePrivacyPolicyAcceptedVersion(version: string): Promise<void> {
    if (this.saveFails) {
      throw new Error('save failed');
    }
    this.privacyPolicyAcceptedVersion = version;
  }

  async saveStylePresetId(stylePresetId: StylePresetId): Promise<void> {
  }

  async saveReminder(reminder: ReminderSettings): Promise<void> {
  }

  async isResetPending(): Promise<boolean> {
    return false;
  }

  async markResetPending(): Promise<void> {
  }

  async reset(): Promise<void> {
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

export default function privacyConsentViewModelTest(): void {
  describe('PrivacyConsentViewModel', () => {
    it('requiresConsentWhenNoMatchingVersionIsStored', 0, async () => {
      const repository = new MemoryPrivacySettingsRepository();
      const viewModel = new PrivacyConsentViewModel(repository, '2026-09-01');

      await viewModel.load();

      expect(viewModel.needsConsent).assertTrue();
      expect(viewModel.errorMessage).assertEqual('');
    });

    it('doesNotRequireConsentWhenTheStoredVersionMatches', 0, async () => {
      const repository = new MemoryPrivacySettingsRepository();
      repository.privacyPolicyAcceptedVersion = '2026-09-01';
      const viewModel = new PrivacyConsentViewModel(repository, '2026-09-01');

      await viewModel.load();

      expect(viewModel.needsConsent).assertFalse();
      expect(viewModel.acceptedVersion).assertEqual('2026-09-01');
    });

    it('savesConsentAndClearsTheGate', 0, async () => {
      const repository = new MemoryPrivacySettingsRepository();
      const viewModel = new PrivacyConsentViewModel(repository, '2026-09-01');
      await viewModel.load();

      const accepted = await viewModel.accept();

      expect(accepted).assertTrue();
      expect(repository.privacyPolicyAcceptedVersion).assertEqual('2026-09-01');
      expect(viewModel.needsConsent).assertFalse();
      expect(viewModel.isSaving).assertFalse();
    });

    it('keepsTheGateOpenWhenSavingFails', 0, async () => {
      const repository = new MemoryPrivacySettingsRepository();
      repository.saveFails = true;
      const viewModel = new PrivacyConsentViewModel(repository, '2026-09-01');
      await viewModel.load();

      const accepted = await viewModel.accept();

      expect(accepted).assertFalse();
      expect(viewModel.needsConsent).assertTrue();
      expect(viewModel.errorMessage).assertEqual('同意状态未能保存，请重试');
      expect(viewModel.isSaving).assertFalse();
    });
  });
}
