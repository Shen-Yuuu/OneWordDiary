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

  build() {
    Column() {
      Text(this.content)
        .width('100%')
        .fontSize(this.contentFontSize)
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
    .alignItems(HorizontalAlign.Center)
  }
}
