import { ReminderSettings } from '../model/Settings';
import { SettingsRepository } from '../repository/SettingsRepository';
import { AppLogger } from '../utils/AppLogger';
import { ReminderScheduler } from './ReminderScheduler';

export class ReminderRetirementService {
  private readonly settingsRepository: SettingsRepository;
  private readonly reminderScheduler: ReminderScheduler;

  constructor(settingsRepository: SettingsRepository, reminderScheduler: ReminderScheduler) {
    this.settingsRepository = settingsRepository;
    this.reminderScheduler = reminderScheduler;
  }

  async retire(): Promise<void> {
    try {
      const settings = await this.settingsRepository.load();
      try {
        await this.reminderScheduler.cancelAll();
      } catch (error) {
        AppLogger.warn('reminder.retirement cancel_all_failed');
      }

      const disabledReminder: ReminderSettings = {
        enabled: false,
        hour: settings.reminder.hour,
        minute: settings.reminder.minute,
        reminderId: -1,
        permissionRequested: settings.reminder.permissionRequested
      };
      await this.settingsRepository.saveReminder(disabledReminder);
      AppLogger.info('reminder.retirement complete');
    } catch (error) {
      AppLogger.warn('reminder.retirement settings_unavailable');
    }
  }
}
