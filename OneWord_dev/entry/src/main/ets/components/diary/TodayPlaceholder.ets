@Component
export struct TodayPlaceholder {
  build() {
    Column({ space: 16 }) {
      Divider()
        .width(32)
        .strokeWidth(1)
        .color($r('app.color.accent_vermilion'))

      Text($r('app.string.baseline_ready'))
        .fontSize($r('app.float.body_size'))
        .fontWeight(FontWeight.Lighter)
        .fontColor($r('app.color.text_secondary'))
        .letterSpacing(2)
    }
    .alignItems(HorizontalAlign.Center)
  }
}
