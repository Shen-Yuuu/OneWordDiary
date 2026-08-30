import { AppLogger } from '../../utils/AppLogger';

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
    return this.paperId === 'plain_ash_dev' ? $r('app.color.paper_plain') : $r('app.color.paper_warm');
  }

  build() {
    Stack() {
      Row()
        .width('100%')
        .height('100%')
        .backgroundColor(this.paperColor)

      Image($r('app.media.paper_grain_dev'))
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
  }
}
