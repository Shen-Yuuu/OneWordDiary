@Component
export struct InspirationLine {
  @Prop text: string = '';
  onRefresh: () => void = () => {
  };

  build() {
    Row({ space: 8 }) {
      Text(this.text)
        .fontSize(15)
        .fontWeight(FontWeight.Lighter)
        .fontColor($r('app.color.text_secondary'))
        .letterSpacing(0.6)
        .maxLines(2)

      Button('换一句')
        .height($r('app.float.touch_target_min'))
        .fontSize(11)
        .fontColor($r('app.color.text_secondary'))
        .backgroundColor(Color.Transparent)
        .accessibilityText('换一句今日灵感')
        .onClick(() => this.onRefresh())
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
  }
}
