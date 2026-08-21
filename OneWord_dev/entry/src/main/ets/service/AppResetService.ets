import { DiaryRepository } from '../repository/DiaryRepository';
import { SettingsRepository } from '../repository/SettingsRepository';
import { ReminderScheduler } from './ReminderScheduler';

export class AppResetService {
  private readonly diaryRepository: DiaryRepository;
  private readonly settingsRepository: SettingsRepository;
  private readonly reminderScheduler: ReminderScheduler;
  private isResetting: boolean = false;

  constructor(
    diaryRepository: DiaryRepository,
    settingsRepository: SettingsRepository,
    reminderScheduler: ReminderScheduler
  ) {
    this.diaryRepository = diaryRepository;
    this.settingsRepository = settingsRepository;
    this.reminderScheduler = reminderScheduler;
  }

  async resumeIfNeeded(): Promise<void> {
    if (await this.settingsRepository.isResetPending()) {
      await this.completeReset();
    }
  }

  async clearAll(): Promise<void> {
    if (this.isResetting) {
      return;
    }
    this.isResetting = true;
    try {
      await this.settingsRepository.markResetPending();
      await this.completeReset();
    } finally {
      this.isResetting = false;
    }
  }

  private async completeReset(): Promise<void> {
    const settings = await this.settingsRepository.load();
    if (settings.reminder.enabled || settings.reminder.reminderId >= 0) {
      await this.reminderScheduler.cancelAll();
    }
    await this.diaryRepository.runInTransaction(async (): Promise<void> => {
      await this.diaryRepository.clearAll();
    });
    await this.settingsRepository.reset();
  }
}
