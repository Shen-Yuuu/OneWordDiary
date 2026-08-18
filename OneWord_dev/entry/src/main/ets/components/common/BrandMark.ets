@Component
export struct BrandMark {
  build() {
    Column({ space: 12 }) {
      Text($r('app.string.brand_name'))
        .fontSize($r('app.float.brand_word_size'))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .letterSpacing(8)

      Text($r('app.string.brand_tagline'))
        .fontSize($r('app.float.label_size'))
        .fontWeight(FontWeight.Lighter)
        .fontColor($r('app.color.text_secondary'))
        .letterSpacing(3)
    }
    .alignItems(HorizontalAlign.Center)
  }
}
