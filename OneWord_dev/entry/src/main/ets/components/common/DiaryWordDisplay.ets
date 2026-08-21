@Component
export struct DiaryWordDisplay {
  @Prop content: string = '';
  @Prop contentCount: number = 0;
  @Prop fontFamily: string = 'serif';
  @Prop stageHeight: number = 132;
  @Prop accessibilityPrefix: string = '正文';

  get contentFontSize(): number {
    if (this.contentCount <= 1) {
      return 84;
    }
    if (this.contentCount === 2) {
      return 68;
    }
    return this.contentCount === 3 ? 54 : 46;
  }

  get contentLineHeight(): number {
    return this.contentFontSize + 16;
  }

  build() {
    Row() {
      Text(this.content)
        .width('100%')
        .fontSize(this.contentFontSize)
        .lineHeight(this.contentLineHeight)
        .minFontScale(1)
        .maxFontScale(1)
        .fontFamily(this.fontFamily)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .accessibilityText(`${this.accessibilityPrefix}，${this.content}`)
    }
    .width('100%')
    .height(this.stageHeight)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
  }
}
