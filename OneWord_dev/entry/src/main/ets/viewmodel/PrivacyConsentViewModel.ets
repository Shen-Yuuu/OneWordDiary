import { SettingsRepository } from '../repository/SettingsRepository';

/**
 * Holds the first-use privacy-consent state independently of page navigation.
 * The caller supplies the current policy version so a later policy update can
 * require consent again without changing persisted data formats here.
 */
@Observed
export class PrivacyConsentViewModel {
  isLoading: boolean = false;
  isSaving: boolean = false;
  needsConsent: boolean = true;
  acceptedVersion: string = '';
  errorMessage: string = '';

  private readonly settingsRepository: SettingsRepository;
  private readonly requiredPolicyVersion: string;

  constructor(settingsRepository: SettingsRepository, requiredPolicyVersion: string) {
    this.settingsRepository = settingsRepository;
    this.requiredPolicyVersion = requiredPolicyVersion;
  }

  get isBusy(): boolean {
    return this.isLoading || this.isSaving;
  }

  async load(): Promise<void> {
    if (this.isLoading || this.isSaving) {
      return;
    }
    this.isLoading = true;
    this.errorMessage = '';
    try {
      const settings = await this.settingsRepository.load();
      this.acceptedVersion = settings.privacyPolicyAcceptedVersion;
      this.needsConsent = this.acceptedVersion !== this.requiredPolicyVersion;
    } catch (error) {
      this.acceptedVersion = '';
      this.needsConsent = true;
      this.errorMessage = '暂时无法读取隐私同意状态，请重试';
    } finally {
      this.isLoading = false;
    }
  }

  async accept(): Promise<boolean> {
    if (this.isBusy || !this.needsConsent) {
      return !this.needsConsent;
    }
    this.isSaving = true;
    this.errorMessage = '';
    try {
      await this.settingsRepository.savePrivacyPolicyAcceptedVersion(this.requiredPolicyVersion);
      this.acceptedVersion = this.requiredPolicyVersion;
      this.needsConsent = false;
      return true;
    } catch (error) {
      this.errorMessage = '同意状态未能保存，请重试';
      return false;
    } finally {
      this.isSaving = false;
    }
  }
}
