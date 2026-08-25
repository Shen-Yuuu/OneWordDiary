import { ShareDayItem, ShareDayKind } from '../../model/ShareModel';
import { GraphemeCounter } from '../../utils/GraphemeCounter';

@Component
export struct ShareSevenDayRow {
  @Prop item: ShareDayItem = {
    localDate: '',
    dateLabel: '',
    weekdayLabel: '',
    monthLabel: '',
    showMonthHeader: false,
    kind: ShareDayKind.MISSING,
    content: '',
    note: ''
  };
  @Prop index: number = 0;
  @Prop fontId: string = 'system_serif_dev';
  @Prop paperId: string = 'warm_paper_dev';
  @Prop showNote: boolean = false;
  private readonly graphemeCounter: GraphemeCounter = new GraphemeCounter();

  get contentOnLeft(): boolean {
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

  get lineColor(): string {
    return this.paperId === 'plain_ash_dev' ? '#DDDCD8' : '#E5DCD7';
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

  get hasVisibleNote(): boolean {
    return this.showNote && this.item.note.length > 0;
  }

  get timelineHeight(): number {
    return this.hasVisibleNote ? 86 : 58;
  }

  get totalHeight(): number {
    return this.timelineHeight + (this.item.showMonthHeader ? 40 : 0);
  }

  @Builder
  private recordBlock() {
    Column({ space: 4 }) {
      Text(`${this.item.dateLabel}  ${this.item.weekdayLabel}`)
        .width(108)
        .fontSize(9)
        .fontFamily('sans-serif')
        .fontColor(this.item.kind === ShareDayKind.MISSING ? this.faintColor : this.secondaryColor)
        .letterSpacing(0.4)
        .textAlign(this.contentOnLeft ? TextAlign.End : TextAlign.Start)
        .minFontScale(1)
        .maxFontScale(1)

      if (this.item.kind === ShareDayKind.WORD) {
        Text(this.item.content)
          .width(108)
          .fontSize(this.wordSize)
          .lineHeight('34vp')
          .fontFamily(this.fontFamily)
          .fontWeight(FontWeight.Normal)
          .fontColor(this.textColor)
          .letterSpacing(this.contentCount > 1 ? 1 : 0)
          .maxLines(1)
          .textAlign(this.contentOnLeft ? TextAlign.End : TextAlign.Start)
          .minFontScale(1)
          .maxFontScale(1)
      } else if (this.item.kind === ShareDayKind.BLANK) {
        Text('留白')
          .width(108)
          .fontSize(12)
          .fontFamily(this.fontFamily)
          .fontColor(this.secondaryColor)
          .letterSpacing(3)
          .textAlign(this.contentOnLeft ? TextAlign.End : TextAlign.Start)
          .minFontScale(1)
          .maxFontScale(1)
      }

      if (this.hasVisibleNote) {
        Text(this.item.note)
          .width(108)
          .fontSize(9)
          .lineHeight(13)
          .fontFamily(this.fontFamily)
          .fontColor(this.secondaryColor)
          .letterSpacing(0.2)
          .maxLines(3)
          .textAlign(this.contentOnLeft ? TextAlign.End : TextAlign.Start)
          .minFontScale(1)
          .maxFontScale(1)
      }

      if (this.item.kind !== ShareDayKind.MISSING) {
        Row()
          .width(24)
          .height(1)
          .backgroundColor(this.lineColor)
      }
    }
    .width(108)
    .alignItems(this.contentOnLeft ? HorizontalAlign.End : HorizontalAlign.Start)
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
          .width(14)
          .height(14)
          .backgroundColor(this.paperId === 'plain_ash_dev' ? '#FFFFFF' : '#FFFCFB')
          .border({ width: 1, color: this.accentColor })
          .borderRadius(7)
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
    .height(this.timelineHeight)
  }

  build() {
    Column() {
      if (this.item.showMonthHeader) {
        Text(this.item.monthLabel)
          .height(40)
          .fontSize(16)
          .fontFamily('serif')
          .fontWeight(FontWeight.Medium)
          .fontColor(this.textColor)
          .letterSpacing(2.2)
          .textAlign(TextAlign.Center)
          .minFontScale(1)
          .maxFontScale(1)
      }

      Stack({ alignContent: Alignment.Center }) {
        Row()
          .width(1)
          .height(this.timelineHeight)
          .backgroundColor(this.lineColor)

        Row() {
          if (this.contentOnLeft) {
            this.recordBlock()
            Row().width(20)
            Row().width(108)
          } else {
            Row().width(108)
            Row().width(20)
            this.recordBlock()
          }
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)

        this.axisNode()
      }
      .width('100%')
      .height(this.timelineHeight)
    }
    .width('100%')
    .height(this.totalHeight)
  }
}
