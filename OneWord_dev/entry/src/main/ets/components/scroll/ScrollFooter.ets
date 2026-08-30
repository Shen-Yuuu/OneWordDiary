@Component
export struct ScrollFooter {
  @Prop isLoading: boolean = false;
  @Prop errorMessage: string = '';
  @Prop hasMore: boolean = true;
  onRetry: () => void = () => {
  };

  get footerHeight(): number {
    return !this.hasMore && !this.isLoading && this.errorMessage.length === 0 ? 156 : 100;
  }

  build() {
    Column({ space: 12 }) {
      if (this.isLoading) {
        LoadingProgress()
          .width(24)
          .height(24)
          .color($r('app.color.accent_vermilion'))

        Text('长卷仍在展开…')
          .fontSize(13)
          .fontFamily('oneword_wenkai, serif')
          .fontColor($r('app.color.text_secondary'))
      } else if (this.errorMessage.length > 0) {
        Text(this.errorMessage)
          .fontSize(14)
          .fontFamily('oneword_wenkai, serif')
          .fontColor($r('app.color.text_secondary'))

        Button('重试')
          .height($r('app.float.touch_target_min'))
          .fontSize(14)
          .fontFamily('oneword_wenkai, serif')
          .fontColor($r('app.color.text_primary'))
          .backgroundColor(Color.Transparent)
          .onClick(() => this.onRetry())
      } else if (!this.hasMore) {
        Row()
          .width(20)
          .height(1)
          .backgroundColor($r('app.color.outline_soft'))

        Text('卷尾')
          .fontSize(13)
          .fontFamily('oneword_wenkai, serif')
          .fontColor($r('app.color.text_secondary'))
          .letterSpacing(3)
      }
    }
    .width('100%')
    .height(this.footerHeight)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
