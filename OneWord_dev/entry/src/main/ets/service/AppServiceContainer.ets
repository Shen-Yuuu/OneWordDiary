import { common } from '@kit.AbilityKit';
import { DailyRecord } from '../model/DailyRecord';
import { DiaryDatabase } from '../repository/DiaryDatabase';
import { DiaryRepository } from '../repository/DiaryRepository';
import { PreferencesSettingsRepository, SettingsRepository } from '../repository/SettingsRepository';
import { RdbDiaryRepository } from '../repository/RdbDiaryRepository';
import { SystemClock } from '../utils/Clock';
import { SystemLocalTimeResolver } from '../utils/LocalTimeResolver';
import { AppResetService } from './AppResetService';
import { BackupCodec } from './BackupCodec';
import { DocumentUriBackupFileGateway } from './BackupFileGateway';
import { BackupService } from './BackupService';
import { BackgroundImageService } from './BackgroundImageService';
import { DiaryService } from './DiaryService';
import { DiaryTextRules } from './DiaryTextRules';
import { ReminderScheduler, SystemReminderScheduler } from './ReminderScheduler';

export class AppServiceContainer {
  private static abilityContext: common.UIAbilityContext | null = null;
  private static diaryService: DiaryService | null = null;
  private static settingsRepository: SettingsRepository | null = null;
  private static reminderScheduler: ReminderScheduler | null = null;
  private static resetService: AppResetService | null = null;
  private static backupService: BackupService | null = null;
  private static backgroundImageService: BackgroundImageService | null = null;

  static async initialize(context: common.UIAbilityContext): Promise<void> {
    AppServiceContainer.abilityContext = context;
    const store = await DiaryDatabase.open(context);
    const repository: DiaryRepository = new RdbDiaryRepository(store);
    const settingsRepository = await PreferencesSettingsRepository.create(context);
    const reminderScheduler = new SystemReminderScheduler(context);
    const backgroundImageService = new BackgroundImageService(context);
    const resetService = new AppResetService(
      repository,
      settingsRepository,
      reminderScheduler,
      backgroundImageService
    );
    await resetService.resumeIfNeeded();
    await AppServiceContainer.cleanupBackgroundOrphans(repository, backgroundImageService);

    AppServiceContainer.diaryService = new DiaryService(
      repository,
      new SystemClock(),
      new SystemLocalTimeResolver(),
      new DiaryTextRules()
    );
    AppServiceContainer.settingsRepository = settingsRepository;
    AppServiceContainer.reminderScheduler = reminderScheduler;
    AppServiceContainer.resetService = resetService;
    AppServiceContainer.backgroundImageService = backgroundImageService;
    AppServiceContainer.backupService = new BackupService(
      repository,
      settingsRepository,
      new SystemClock(),
      new BackupCodec(new DiaryTextRules()),
      new DocumentUriBackupFileGateway()
    );
  }

  private static async cleanupBackgroundOrphans(
    repository: DiaryRepository,
    backgroundImageService: BackgroundImageService
  ): Promise<void> {
    const referencedIds = new Set<string>();
    let exclusiveDate: string | null = null;
    const pageSize: number = 200;
    try {
      while (true) {
        const records: DailyRecord[] = await repository.findPageBefore(exclusiveDate, pageSize);
        records.forEach((record: DailyRecord) => {
          if (record.backgroundImageId !== null && record.backgroundImageId !== undefined) {
            referencedIds.add(record.backgroundImageId);
          }
        });
        if (records.length < pageSize) {
          break;
        }
        exclusiveDate = records[records.length - 1].localDate;
      }
      backgroundImageService.cleanupOrphans(referencedIds);
    } catch (error) {
      // Orphan cleanup is best-effort and must not prevent the diary from opening.
    }
  }

  static getAbilityContext(): common.UIAbilityContext {
    if (AppServiceContainer.abilityContext === null) {
      throw new Error('AppServiceContainer has not been initialized');
    }
    return AppServiceContainer.abilityContext;
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

  static getBackgroundImageService(): BackgroundImageService {
    if (AppServiceContainer.backgroundImageService === null) {
      throw new Error('AppServiceContainer has not been initialized');
    }
    return AppServiceContainer.backgroundImageService;
  }

  static getBackupService(): BackupService {
    if (AppServiceContainer.backupService === null) {
      throw new Error('AppServiceContainer has not been initialized');
    }
    return AppServiceContainer.backupService;
  }
}
