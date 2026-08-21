@Component
export struct DiaryWordDisplay {
  @Prop content: string = '';
  @Prop contentCount: number = 0;
  @Prop fontFamily: string = 'serif';
  @Prop stageHeight: number = 160;
  @Prop accessibilityPrefix: string = '正文';

  get contentFontSize(): string {
    if (this.contentCount <= 1) {
      return '88vp';
    }
    if (this.contentCount === 2) {
      return '72vp';
    }
    return this.contentCount === 3 ? '58vp' : '48vp';
  }

  get contentLineHeight(): string {
    if (this.contentCount <= 1) {
      return '104vp';
    }
    if (this.contentCount === 2) {
      return '88vp';
    }
    return this.contentCount === 3 ? '74vp' : '64vp';
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Text(this.content)
        .width('100%')
        .fontSize(this.contentFontSize)
        .lineHeight(this.contentLineHeight)
        .minFontScale(1)
        .maxFontScale(1)
        .fontFamily(this.fontFamily)
        .fontWeight(FontWeight.Normal)
        .fontColor($r('app.color.text_primary'))
        .letterSpacing(this.contentCount > 1 ? 3 : 0)
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .accessibilityText(`${this.accessibilityPrefix}，${this.content}`)
    }
    .width('100%')
    .height(this.stageHeight)
  }
}
