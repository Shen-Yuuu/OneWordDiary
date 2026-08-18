@Component
export struct ScrollFooter {
  @Prop isLoading: boolean = false;
  @Prop errorMessage: string = '';
  @Prop hasMore: boolean = true;
  onRetry: () => void = () => {
  };

  build() {
    Column({ space: 12 }) {
      if (this.isLoading) {
        LoadingProgress()
          .width(24)
          .height(24)
          .color($r('app.color.accent_vermilion'))

        Text('长卷仍在展开…')
          .fontSize(11)
          .fontColor($r('app.color.text_secondary'))
      } else if (this.errorMessage.length > 0) {
        Text(this.errorMessage)
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))

        Button('重试')
          .height($r('app.float.touch_target_min'))
          .fontSize(12)
          .fontColor($r('app.color.text_primary'))
          .backgroundColor(Color.Transparent)
          .onClick(() => this.onRetry())
      } else if (!this.hasMore) {
        Text('卷尾')
          .fontSize(11)
          .fontColor($r('app.color.text_secondary'))
          .letterSpacing(3)
      }
    }
    .width('100%')
    .height(100)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
