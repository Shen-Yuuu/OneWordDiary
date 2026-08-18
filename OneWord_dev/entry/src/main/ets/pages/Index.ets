import { BrandMark } from '../components/common/BrandMark';
import { TodayPlaceholder } from '../components/diary/TodayPlaceholder';

@Entry
@Component
struct Index {
  private navPathStack: NavPathStack = new NavPathStack();

  build() {
    Navigation(this.navPathStack) {
      Column() {
        Blank()

        BrandMark()

        Blank()

        TodayPlaceholder()
          .margin({ bottom: 56 })
      }
      .width('100%')
      .height('100%')
      .padding({
        left: $r('app.float.page_horizontal_margin'),
        right: $r('app.float.page_horizontal_margin')
      })
      .backgroundColor($r('app.color.app_background'))
    }
    .width('100%')
    .height('100%')
    .hideTitleBar(true)
    .mode(NavigationMode.Stack)
    .backgroundColor($r('app.color.app_background'))
  }
}
