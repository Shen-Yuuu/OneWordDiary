import { ShareDayItem, ShareDayKind } from '../../model/ShareModel';
import { GraphemeCounter } from '../../utils/GraphemeCounter';

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
  private readonly graphemeCounter: GraphemeCounter = new GraphemeCounter();

  get dateOnLeft(): boolean {
    return this.index % 2 === 0;
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

  get contentCount(): number {
    return this.graphemeCounter.count(this.item.content);
  }

  get wordSize(): string {
    if (this.contentCount <= 1) {
      return '30vp';
    }
    if (this.contentCount === 2) {
      return '26vp';
    }
    return this.contentCount === 3 ? '23vp' : '21vp';
  }

  @Builder
  private dateBlock() {
    Text(`${this.item.dateLabel}  ${this.item.weekdayLabel}`)
      .width(112)
      .fontSize(10)
      .fontFamily('sans-serif')
      .fontColor(this.item.kind === ShareDayKind.MISSING ? this.faintColor : this.secondaryColor)
      .letterSpacing(0.5)
      .textAlign(this.dateOnLeft ? TextAlign.End : TextAlign.Start)
      .minFontScale(1)
      .maxFontScale(1)
  }

  @Builder
  private contentBlock() {
    if (this.item.kind === ShareDayKind.WORD) {
      Text(this.item.content)
        .width(112)
        .fontSize(this.wordSize)
        .lineHeight('34vp')
        .fontFamily(this.fontFamily)
        .fontWeight(FontWeight.Normal)
        .fontColor(this.textColor)
        .maxLines(1)
        .textAlign(this.dateOnLeft ? TextAlign.Start : TextAlign.End)
        .minFontScale(1)
        .maxFontScale(1)
    } else if (this.item.kind === ShareDayKind.BLANK) {
      Text('留白')
        .width(112)
        .fontSize(12)
        .fontFamily(this.fontFamily)
        .fontColor(this.secondaryColor)
        .letterSpacing(3)
        .textAlign(this.dateOnLeft ? TextAlign.Start : TextAlign.End)
        .minFontScale(1)
        .maxFontScale(1)
    } else {
      Row()
        .width(112)
        .height(1)
    }
  }

  @Builder
  private axisNode() {
    Stack({ alignContent: Alignment.Center }) {
      if (this.item.kind === ShareDayKind.WORD) {
        Row()
          .width(6)
          .height(6)
          .backgroundColor(this.accentColor)
          .borderRadius(3)
      } else if (this.item.kind === ShareDayKind.BLANK) {
        Row()
          .width(13)
          .height(13)
          .border({ width: 1, color: this.accentColor })
          .borderRadius(6.5)
        Row()
          .width(3)
          .height(3)
          .backgroundColor(this.accentColor)
          .borderRadius(1.5)
      } else {
        Row()
          .width(4)
          .height(4)
          .backgroundColor(this.faintColor)
          .borderRadius(2)
      }
    }
    .width(20)
    .height(38)
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
    .height(38)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
  }
}

