import { common } from '@kit.AbilityKit';
import { DiaryDatabase } from '../repository/DiaryDatabase';
import { DiaryRepository } from '../repository/DiaryRepository';
import { PreferencesSettingsRepository, SettingsRepository } from '../repository/SettingsRepository';
import { RdbDiaryRepository } from '../repository/RdbDiaryRepository';
import { SystemClock } from '../utils/Clock';
import { SystemLocalTimeResolver } from '../utils/LocalTimeResolver';
import { AppResetService } from './AppResetService';
import { DiaryService } from './DiaryService';
import { DiaryTextRules } from './DiaryTextRules';
import { ReminderScheduler, SystemReminderScheduler } from './ReminderScheduler';

export class AppServiceContainer {
  private static diaryService: DiaryService | null = null;
  private static settingsRepository: SettingsRepository | null = null;
  private static reminderScheduler: ReminderScheduler | null = null;
  private static resetService: AppResetService | null = null;

  static async initialize(context: common.UIAbilityContext): Promise<void> {
    const store = await DiaryDatabase.open(context);
    const repository: DiaryRepository = new RdbDiaryRepository(store);
    const settingsRepository = await PreferencesSettingsRepository.create(context);
    const reminderScheduler = new SystemReminderScheduler(context);
    const resetService = new AppResetService(repository, settingsRepository, reminderScheduler);
    await resetService.resumeIfNeeded();

    AppServiceContainer.diaryService = new DiaryService(
      repository,
      new SystemClock(),
      new SystemLocalTimeResolver(),
      new DiaryTextRules()
    );
    AppServiceContainer.settingsRepository = settingsRepository;
    AppServiceContainer.reminderScheduler = reminderScheduler;
    AppServiceContainer.resetService = resetService;
  }

  static getDiaryService(): DiaryService {
    if (AppServiceContainer.diaryService === null) {
      throw new Error('AppServiceContainer has not been initialized');
    }
    return AppServiceContainer.diaryService;
  }

  static getSettingsRepository(): SettingsRepository {
    if (AppServiceContainer.settingsRepository === null) {
      throw new Error('AppServiceContainer has not been initialized');
    }
    return AppServiceContainer.settingsRepository;
  }

  static getReminderScheduler(): ReminderScheduler {
    if (AppServiceContainer.reminderScheduler === null) {
      throw new Error('AppServiceContainer has not been initialized');
    }
    return AppServiceContainer.reminderScheduler;
  }

  static getResetService(): AppResetService {
    if (AppServiceContainer.resetService === null) {
      throw new Error('AppServiceContainer has not been initialized');
    }
    return AppServiceContainer.resetService;
  }
}