import { DiaryDatabase } from '../repository/DiaryDatabase';
import { PreferencesSettingsRepository, SettingsRepository } from '../repository/SettingsRepository';
import { RdbDiaryRepository } from '../repository/RdbDiaryRepository';
import { SystemClock } from '../utils/Clock';
import { SystemLocalTimeResolver } from '../utils/LocalTimeResolver';
import { DiaryService } from './DiaryService';
import { DiaryTextRules } from './DiaryTextRules';

export class AppServiceContainer {
  private static diaryService: DiaryService | null = null;
  private static settingsRepository: SettingsRepository | null = null;

  static async initialize(context: Context): Promise<void> {
    const store = await DiaryDatabase.open(context);
    const repository = new RdbDiaryRepository(store);
    AppServiceContainer.diaryService = new DiaryService(
      repository,
      new SystemClock(),
      new SystemLocalTimeResolver(),
      new DiaryTextRules()
    );
    AppServiceContainer.settingsRepository = await PreferencesSettingsRepository.create(context);
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
}
