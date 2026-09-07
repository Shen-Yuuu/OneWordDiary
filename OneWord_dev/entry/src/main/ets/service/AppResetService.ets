import { DiaryRepository } from '../repository/DiaryRepository';
import { SettingsRepository } from '../repository/SettingsRepository';
import { BackgroundImageStore } from '../model/BackgroundImage';
import { ReminderScheduler } from './ReminderScheduler';

export class AppResetService {
  private readonly diaryRepository: DiaryRepository;
  private readonly settingsRepository: SettingsRepository;
  private readonly reminderScheduler: ReminderScheduler;
  private readonly backgroundImageStore: BackgroundImageStore | null;
  private isResetting: boolean = false;

  constructor(
    diaryRepository: DiaryRepository,
    settingsRepository: SettingsRepository,
    reminderScheduler: ReminderScheduler,
    backgroundImageStore: BackgroundImageStore | null = null
  ) {
    this.diaryRepository = diaryRepository;
    this.settingsRepository = settingsRepository;
    this.reminderScheduler = reminderScheduler;
    this.backgroundImageStore = backgroundImageStore;
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
    if (this.backgroundImageStore !== null) {
      this.backgroundImageStore.clearAll();
    }
    await this.settingsRepository.reset();
  }
}
