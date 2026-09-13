import { AppLogger } from '../../utils/AppLogger';
import { styleForPaper } from '../../constants/StyleTokens';

@Component
export struct PaperBackdrop {
  @Prop @Watch('onPaperChanged') paperId: string = 'warm_paper_dev';

  aboutToAppear(): void {
    AppLogger.info(`style.backdrop paperId=${this.paperId}`);
  }

  onPaperChanged(): void {
    AppLogger.info(`style.backdrop_change paperId=${this.paperId}`);
  }

  get paperColor(): ResourceColor {
    return styleForPaper(this.paperId).light.background;
  }

  private readonly grainMap: Record<string, Resource> = {
    'warm_paper_dev': $r('app.media.paper_grain_warm'),
    'plain_ash_dev': $r('app.media.paper_grain_ash'),
    'pine_mist_dev': $r('app.media.paper_grain_pine'),
    'mist_blue_dev': $r('app.media.paper_grain_blue'),
    'apricot_paper_dev': $r('app.media.paper_grain_apricot'),
    'rose_pink_dev': $r('app.media.paper_grain_rose')
  };

  grainResource(): Resource {
    const grain = this.grainMap[this.paperId];
    return grain !== undefined ? grain : $r('app.media.paper_grain_warm');
  }

  build() {
    Stack() {
      Row()
        .width('100%')
        .height('100%')
        .backgroundColor(this.paperColor)

      Image(this.grainResource())
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Fill)
        .opacity(0.34)
        .accessibilityLevel('no')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.paperColor)
    .hitTestBehavior(HitTestMode.None)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
