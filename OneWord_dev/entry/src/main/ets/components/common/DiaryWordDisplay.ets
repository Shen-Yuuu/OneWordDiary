@Component
export struct DiaryWordDisplay {
  @Prop content: string = '';
  @Prop contentCount: number = 0;
  @Prop fontFamily: string = 'serif';
  @Prop stageHeight: number = 160;
  @Prop isHero: boolean = false;
  @Prop accessibilityPrefix: string = '正文';

  get contentFontSize(): number {
    if (this.isHero) {
      if (this.contentCount <= 1) {
        return 210;
      }
      if (this.contentCount === 2) {
        return 136;
      }
      return this.contentCount === 3 ? 92 : 66;
    }
    if (this.contentCount <= 1) {
      return 88;
    }
    if (this.contentCount === 2) {
      return 72;
    }
    return this.contentCount === 3 ? 58 : 48;
  }

  get contentLineHeight(): number {
    if (this.isHero) {
      if (this.contentCount <= 1) {
        return 246;
      }
      if (this.contentCount === 2) {
        return 164;
      }
      return this.contentCount === 3 ? 116 : 90;
    }
    if (this.contentCount <= 1) {
      return 104;
    }
    if (this.contentCount === 2) {
      return 88;
    }
    return this.contentCount === 3 ? 74 : 64;
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
