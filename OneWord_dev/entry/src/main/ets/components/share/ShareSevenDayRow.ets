import { ShareDayItem, ShareDayKind } from '../../model/ShareModel';

@Component
export struct ShareSevenDayRow {
  @Prop item: ShareDayItem = {
    localDate: '',
    dateLabel: '',
    weekdayLabel: '',
    kind: ShareDayKind.MISSING,
    content: ''
  };
  @Prop index: number = 0;
  @Prop fontId: string = 'system_serif_dev';
  @Prop paperId: string = 'warm_paper_dev';

  get dateOnLeft(): boolean {
    return Math.floor(this.index / 2) % 2 === 0;
  }

  get fontFamily(): string {
    return this.fontId === 'system_sans_dev' ? 'sans-serif' : 'serif';
  }

  get textColor(): string {
    return this.paperId === 'plain_ash_dev' ? '#242424' : '#282622';
  }

  get secondaryColor(): string {
    return this.paperId === 'plain_ash_dev' ? '#777775' : '#8C8783';
  }

  get faintColor(): string {
    return this.paperId === 'plain_ash_dev' ? '#B5B5B1' : '#C2B9B4';
  }

  get accentColor(): string {
    return this.paperId === 'plain_ash_dev' ? '#626260' : '#A65C4D';
  }

  get wordSize(): number {
    return this.item.content.length > 2 ? 18 : 29;
  }

  @Builder
  private dateBlock() {
    Text(`${this.item.dateLabel}  ${this.item.weekdayLabel}`)
      .width(108)
      .fontSize(9)
      .fontFamily('sans-serif')
      .fontColor(this.item.kind === ShareDayKind.MISSING ? this.faintColor : this.secondaryColor)
      .letterSpacing(0.8)
      .textAlign(this.dateOnLeft ? TextAlign.End : TextAlign.Start)
      .minFontScale(1)
      .maxFontScale(1)
  }

  @Builder
  private contentBlock() {
    if (this.item.kind === ShareDayKind.WORD) {
      Text(this.item.content)
        .width(108)
        .fontSize(this.wordSize)
        .fontFamily(this.fontFamily)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.textColor)
        .maxLines(1)
        .textAlign(this.dateOnLeft ? TextAlign.Start : TextAlign.End)
        .minFontScale(1)
        .maxFontScale(1)
    } else if (this.item.kind === ShareDayKind.BLANK) {
      Text('留白')
        .width(108)
        .fontSize(11)
        .fontFamily(this.fontFamily)
        .fontColor(this.secondaryColor)
        .letterSpacing(3)
        .textAlign(this.dateOnLeft ? TextAlign.Start : TextAlign.End)
        .minFontScale(1)
        .maxFontScale(1)
    } else {
      Row()
        .width(108)
        .height(1)
    }
  }

  @Builder
  private axisNode() {
    Stack({ alignContent: Alignment.Center }) {
      if (this.item.kind === ShareDayKind.WORD) {
        Row()
          .width(7)
          .height(7)
          .backgroundColor(this.accentColor)
          .borderRadius(3.5)
      } else if (this.item.kind === ShareDayKind.BLANK) {
        Row()
          .width(15)
          .height(15)
          .border({ width: 1, color: this.accentColor })
          .borderRadius(7.5)
        Row()
          .width(3)
          .height(3)
          .backgroundColor(this.accentColor)
          .borderRadius(1.5)
      } else {
        Row()
          .width(11)
          .height(11)
          .border({ width: 1, color: this.faintColor, style: BorderStyle.Dashed })
          .borderRadius(5.5)
      }
    }
    .width(20)
    .height(40)
  }

  build() {
    Row() {
      if (this.dateOnLeft) {
        this.dateBlock()
        this.axisNode()
        this.contentBlock()
      } else {
        this.contentBlock()
        this.axisNode()
        this.dateBlock()
      }
    }
    .width('100%')
    .height(40)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
  }
}

