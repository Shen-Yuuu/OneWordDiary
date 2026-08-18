import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { AppServiceContainer } from '../service/AppServiceContainer';
import { AppLogger } from '../utils/AppLogger';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    AppLogger.info('ability.created');
  }

  onDestroy(): void {
    AppLogger.info('ability.destroyed');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    AppLogger.info('ability.window_stage_created');

    this.initializeAndLoad(windowStage);
  }

  private async initializeAndLoad(windowStage: window.WindowStage): Promise<void> {
    try {
      await AppServiceContainer.initialize(this.context);
      AppLogger.info('app_services.initialized');
    } catch (error) {
      AppLogger.error('app_services.initialize_failed');
      return;
    }

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        AppLogger.error('ability.content_load_failed');
        return;
      }
      AppLogger.info('ability.content_loaded');
    });
  }

  onWindowStageDestroy(): void {
    AppLogger.info('ability.window_stage_destroyed');
  }

  onForeground(): void {
    AppLogger.info('ability.foreground');
  }

  onBackground(): void {
    AppLogger.info('ability.background');
  }
}