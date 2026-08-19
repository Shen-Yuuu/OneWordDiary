@Component
export struct PaperBackdrop {
  @Prop paperId: string = 'warm_paper_dev';

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
    .hitTestBehavior(HitTestMode.None)
  }
}
