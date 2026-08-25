import { ShareDayItem, ShareDayKind } from '../../model/ShareModel';
import { GraphemeCounter } from '../../utils/GraphemeCounter';

@Component
export struct ShareScrollDayNode {
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
  @Prop includeNote: boolean = false;
  private readonly graphemeCounter: GraphemeCounter = new GraphemeCounter();

  get contentOnLeft(): boolean {
    return this.index % 2 === 0;
  }

  get fontFamily(): string {
    return this.fontId === 'system_sans_dev' ? 'sans-serif' : 'serif';
  }

  get paperColor(): string {
    return this.paperId === 'plain_ash_dev' ? '#FFFFFF' : '#FFFCFB';
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

  get wordSize(): number {
    if (this.contentCount <= 1) {
      return 42;
    }
    if (this.contentCount === 2) {
      return 36;
    }
    return this.contentCount === 3 ? 31 : 28;
  }

  get visibleNote(): string {
    return this.item.note.length > 0 ? this.item.note : '这条记录没有备注';
  }

  get timelineHeight(): number {
    if (this.item.kind === ShareDayKind.MISSING) {
      return 82;
    }
    return this.includeNote ? 156 : 126;
  }

  get totalHeight(): number {
    return this.timelineHeight + (this.item.showMonthHeader ? 66 : 0);
  }

  @Builder
  private recordBlock() {
    Column({ space: 6 }) {
      Text(`${this.item.dateLabel}  ${this.item.weekdayLabel}`)
        .fontSize(10)
        .fontFamily('sans-serif')
        .fontColor(this.item.kind === ShareDayKind.MISSING ? this.faintColor : this.secondaryColor)
        .letterSpacing(0.7)
        .textAlign(this.contentOnLeft ? TextAlign.End : TextAlign.Start)
        .minFontScale(1)
        .maxFontScale(1)

      if (this.item.kind === ShareDayKind.WORD) {
        Text(this.item.content)
          .fontSize(this.wordSize)
          .lineHeight(52)
          .fontFamily(this.fontFamily)
          .fontWeight(FontWeight.Normal)
          .fontColor(this.textColor)
          .letterSpacing(this.contentCount > 1 ? 1.4 : 0)
          .maxLines(1)
          .textAlign(this.contentOnLeft ? TextAlign.End : TextAlign.Start)
          .minFontScale(1)
          .maxFontScale(1)
      } else if (this.item.kind === ShareDayKind.BLANK) {
        Text('留白')
          .fontSize(14)
          .fontFamily(this.fontFamily)
          .fontColor(this.secondaryColor)
          .letterSpacing(3)
          .textAlign(this.contentOnLeft ? TextAlign.End : TextAlign.Start)
          .minFontScale(1)
          .maxFontScale(1)
      }

      if (this.includeNote && this.item.kind !== ShareDayKind.MISSING) {
        Text(this.visibleNote)
          .width(112)
          .fontSize(9)
          .lineHeight(14)
          .fontFamily(this.fontFamily)
          .fontColor(this.secondaryColor)
          .letterSpacing(0.2)
          .maxLines(2)
          .textAlign(this.contentOnLeft ? TextAlign.End : TextAlign.Start)
          .minFontScale(1)
          .maxFontScale(1)
      }

      if (this.item.kind !== ShareDayKind.MISSING) {
        Row()
          .width(28)
          .height(1)
          .backgroundColor(this.lineColor)
      }
    }
    .width(112)
    .padding({ left: 4, right: 4 })
    .alignItems(this.contentOnLeft ? HorizontalAlign.End : HorizontalAlign.Start)
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
          .width(22)
          .height(22)
          .backgroundColor(this.paperColor)
          .border({ width: 1, color: this.accentColor })
          .borderRadius(11)

        Row()
          .width(4)
          .height(4)
          .backgroundColor(this.accentColor)
          .borderRadius(2)
      } else {
        Row()
          .width(5)
          .height(5)
          .backgroundColor(this.faintColor)
          .borderRadius(2.5)
      }
    }
    .width(22)
    .height(this.timelineHeight)
  }

  build() {
    Column() {
      if (this.item.showMonthHeader) {
        Text(this.item.monthLabel)
          .height(66)
          .fontSize(20)
          .fontFamily('serif')
          .fontWeight(FontWeight.Medium)
          .fontColor(this.textColor)
          .letterSpacing(2.8)
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
            Row().width(22)
            Row().width(112)
          } else {
            Row().width(112)
            Row().width(22)
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
