@Component
export struct TodayHeader {
  @Prop dateText: string = '';
  @Prop weekdayText: string = '';
  onScroll: () => void = () => {
  };
  onSettings: () => void = () => {
  };

  build() {
    Row() {
      Button('长卷')
        .height($r('app.float.touch_target_min'))
        .fontSize($r('app.float.label_size'))
        .fontColor($r('app.color.text_secondary'))
        .backgroundColor(Color.Transparent)
        .accessibilityText('打开文字长卷')
        .onClick(() => this.onScroll())

      Column({ space: 2 }) {
        Text(this.dateText)
          .fontSize(14)
          .fontWeight(FontWeight.Lighter)
          .fontColor($r('app.color.text_primary'))
          .letterSpacing(1.2)

        Text(this.weekdayText)
          .fontSize(11)
          .fontColor($r('app.color.text_secondary'))
          .letterSpacing(1)
      }
      .alignItems(HorizontalAlign.Center)

      Button('设置')
        .height($r('app.float.touch_target_min'))
        .fontSize($r('app.float.label_size'))
        .fontColor($r('app.color.text_secondary'))
        .backgroundColor(Color.Transparent)
        .accessibilityText('打开设置')
        .onClick(() => this.onSettings())
    }
    .width('100%')
    .height(64)
    .justifyContent(FlexAlign.SpaceBetween)
  }
}
