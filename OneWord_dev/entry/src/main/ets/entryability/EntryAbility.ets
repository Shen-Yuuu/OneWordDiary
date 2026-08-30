import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { FontFamilies } from '../constants/StyleTokens';
import { AppServiceContainer } from '../service/AppServiceContainer';
import { AppLogger } from '../utils/AppLogger';

const FONT_FAMILY_SERIF = 'oneword_wenkai';
const FONT_FAMILY_SERIF_MEDIUM = 'oneword_wenkai_medium';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.context.getApplicationContext()
      .setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT);
    AppLogger.info('ability.created');
  }

  onDestroy(): void {
    AppLogger.info('ability.destroyed');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    AppLogger.info('ability.window_stage_created');

    this.initializeAndLoad(windowStage);
  }

  private registerCustomFonts(windowStage: window.WindowStage): void {
    AppLogger.info(`font.v4 constants_check serif=${FontFamilies.SERIF} medium=${FontFamilies.SERIF_HEAVY}`);
    AppLogger.info('font.register_start families=oneword_wenkai,oneword_wenkai_medium');
    windowStage.getMainWindow().then((mainWindow: window.Window) => {
      this.verifyFontAsset('fonts/OneWordKai-Regular.ttf');
      this.verifyFontAsset('fonts/OneWordKai-Medium.ttf');
      const fontManager = mainWindow.getUIContext().getFont();
      fontManager.registerFont({
        familyName: FONT_FAMILY_SERIF,
        familySrc: $rawfile('fonts/OneWordKai-Regular.ttf')
      });
      fontManager.registerFont({
        familyName: FONT_FAMILY_SERIF_MEDIUM,
        familySrc: $rawfile('fonts/OneWordKai-Medium.ttf')
      });
      AppLogger.info('font.custom_registered families=oneword_wenkai,oneword_wenkai_medium');
    }).catch((err: BusinessError) => {
      AppLogger.error(`font.register_failed code=${err.code}`);
    });
  }

  private verifyFontAsset(rawfilePath: string): void {
    try {
      const descriptor = this.context.resourceManager.getRawFdSync(rawfilePath);
      AppLogger.info(`font.asset_ok ${rawfilePath} bytes=${descriptor.length}`);
    } catch (err) {
      const code = (err as BusinessError).code;
      AppLogger.error(`font.asset_missing ${rawfilePath} code=${code}`);
    }
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
      // 官方指引：全局字体在 loadContent 回调内注册（过早 getMainWindow 会报 1300002 窗口状态异常）
      this.registerCustomFonts(windowStage);
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