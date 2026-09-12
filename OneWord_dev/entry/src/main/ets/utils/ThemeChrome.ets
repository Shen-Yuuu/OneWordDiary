import { common } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { styleForPaper } from '../constants/StyleTokens';

/**
 * 让系统导航条底色跟随当前主题纸色。
 * 全屏布局 + 透明导航条时，系统会在亮色内容的手势区绘制对比渐变（深灰层）；
 * 将导航条设为不透明的主题纸色后系统不再绘制该层，底部与页面无缝融合。
 */
export class ThemeChrome {
  static apply(context: common.UIAbilityContext, paperId: string): void {
    try {
      window.getLastWindow(context).then((mainWindow: window.Window) => {
        mainWindow.setWindowSystemBarProperties({
          navigationBarColor: styleForPaper(paperId).light.background,
          statusBarContentColor: '#1F1F1F'
        });
      }).catch(() => {
        // 窗口不可用时静默：仅影响导航条底色
      });
    } catch (err) {
      // 静默：外观同步失败不影响功能
    }
  }

  private constructor() {
  }
}
