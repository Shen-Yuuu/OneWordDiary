import { ShareDayItem, ShareDayKind } from '../../model/ShareModel';
import { GraphemeCounter } from '../../utils/GraphemeCounter';

@Component
export struct ShareScrollCard {
  @Prop days: ShareDayItem[] = [];
  @Prop fontId: string = 'system_serif_dev';
  @Prop paperId: string = 'warm_paper_dev';
  @Prop includeNote: boolean = false;
  private readonly graphemeCounter: GraphemeCounter = new GraphemeCounter();

  get paperColor(): string {
    return this.paperId === 'plain_ash_dev' ? '#FFFFFF' : '#FFFCFB';
  }

  get textColor(): string {
    return this.paperId === 'plain_ash_dev' ? '#242424' : '#282622';
  }

  get secondaryColor(): string {
    return this.paperId === 'plain_ash_dev' ? '#6F6F6C' : '#817B77';
  }

  get faintColor(): string {
    return this.paperId === 'plain_ash_dev' ? '#AFAFAC' : '#B8ADA7';
  }

  get lineColor(): string {
    return this.paperId === 'plain_ash_dev' ? '#CACAC6' : '#D5C6BF';
  }

  get accentColor(): string {
    return this.paperId === 'plain_ash_dev' ? '#626260' : '#A65C4D';
  }

  get fontFamily(): string {
    return this.fontId === 'system_sans_dev' ? 'sans-serif' : 'serif';
  }

  private contentOnLeft(index: number): boolean {
    return index % 2 === 0;
  }

  private noteText(item: ShareDayItem): string {
    return item.note.length > 0 ? item.note : '这条记录没有备注';
  }

  private wordSize(item: ShareDayItem): number {
    const count = this.graphemeCounter.count(item.content);
    if (count <= 1) {
      return 42;
    }
    if (count === 2) {
      return 36;
    }
    return count === 3 ? 31 : 27;
  }

  private nodeHeight(item: ShareDayItem): number {
    if (item.kind === ShareDayKind.MISSING) {
      return 82;
    }
    return this.includeNote ? 158 : 128;
  }

  get timelineHeight(): number {
    let height = 0;
    for (const item of this.days) {
      height += this.nodeHeight(item);
      if (item.showMonthHeader) {
        height += 66;
      }
    }
    return height;
  }

  get cardHeight(): number {
    return this.timelineHeight + 116;
  }

  @Builder
  private recordBlock(item: ShareDayItem, onLeft: boolean) {
    Column({ space: 7 }) {
      Text(`${item.dateLabel}  ${item.weekdayLabel}`)
        .width(112)
        .fontSize(10)
        .fontFamily('sans-serif')
        .fontColor(item.kind === ShareDayKind.MISSING ? this.faintColor : this.secondaryColor)
        .letterSpacing(0.7)
        .textAlign(onLeft ? TextAlign.End : TextAlign.Start)
        .minFontScale(1)
        .maxFontScale(1)

      if (item.kind === ShareDayKind.WORD) {
        Text(item.content)
          .width(112)
          .fontSize(this.wordSize(item))
          .lineHeight(50)
          .fontFamily(this.fontFamily)
          .fontWeight(FontWeight.Normal)
          .fontColor(this.textColor)
          .letterSpacing(this.graphemeCounter.count(item.content) > 1 ? 1.4 : 0)
          .maxLines(1)
          .textAlign(onLeft ? TextAlign.End : TextAlign.Start)
          .minFontScale(1)
          .maxFontScale(1)
      } else if (item.kind === ShareDayKind.BLANK) {
        Text('留白')
          .width(112)
          .fontSize(14)
          .fontFamily(this.fontFamily)
          .fontColor(this.secondaryColor)
          .letterSpacing(3)
          .textAlign(onLeft ? TextAlign.End : TextAlign.Start)
          .minFontScale(1)
          .maxFontScale(1)
      }

      if (this.includeNote && item.kind !== ShareDayKind.MISSING) {
        Text(this.noteText(item))
          .width(112)
          .fontSize(9)
          .lineHeight(14)
          .fontFamily(this.fontFamily)
          .fontColor(this.secondaryColor)
          .letterSpacing(0.2)
          .maxLines(2)
          .textAlign(onLeft ? TextAlign.End : TextAlign.Start)
          .minFontScale(1)
          .maxFontScale(1)
      }

      if (item.kind !== ShareDayKind.MISSING) {
        Row()
          .width(28)
          .height(1)
          .backgroundColor(this.lineColor)
      }
    }
    .width(112)
    .alignItems(onLeft ? HorizontalAlign.End : HorizontalAlign.Start)
  }

  @Builder
  private axisNode(item: ShareDayItem, height: number) {
    Stack({ alignContent: Alignment.Center }) {
      if (item.kind === ShareDayKind.WORD) {
        Row()
          .width(8)
          .height(8)
          .backgroundColor(this.accentColor)
          .borderRadius(4)
      } else if (item.kind === ShareDayKind.BLANK) {
        Row()
          .width(22)
          .height(22)
          .backgroundColor(this.paperColor)
          .border({ width: 2, color: this.accentColor })
          .borderRadius(11)

        Row()
          .width(4)
          .height(4)
          .backgroundColor(this.accentColor)
          .borderRadius(2)
      } else {
        Row()
          .width(14)
          .height(14)
          .backgroundColor(this.paperColor)
          .border({ width: 1, color: this.faintColor })
          .borderRadius(7)
      }
    }
    .width(22)
    .height(height)
  }

  @Builder
  private dayNode(item: ShareDayItem, index: number) {
    Column() {
      if (item.showMonthHeader) {
        Text(item.monthLabel)
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
          .width(2)
          .height(this.nodeHeight(item))
          .backgroundColor(this.lineColor)

        Row() {
          if (this.contentOnLeft(index)) {
            this.recordBlock(item, true)
            Row().width(22)
            Row().width(112)
          } else {
            Row().width(112)
            Row().width(22)
            this.recordBlock(item, false)
          }
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)

        this.axisNode(item, this.nodeHeight(item))
      }
      .width('100%')
      .height(this.nodeHeight(item))
    }
    .width('100%')
    .height(this.nodeHeight(item) + (item.showMonthHeader ? 66 : 0))
  }

  build() {
    Column() {
      Column() {
        ForEach(this.days, (item: ShareDayItem, index: number) => {
          this.dayNode(item, index)
        }, (item: ShareDayItem): string => item.localDate)
      }
      .width('100%')
      .margin({ top: 16 })

      Column({ space: 16 }) {
        Text('卷尾')
          .fontSize(13)
          .fontFamily(this.fontFamily)
          .fontColor(this.secondaryColor)
          .letterSpacing(2)

        Row({ space: 8 }) {
          Stack({ alignContent: Alignment.Center }) {
            Row()
              .width(19)
              .height(19)
              .backgroundColor(this.accentColor)
              .borderRadius(2)

            Text('字')
              .fontSize(9)
              .fontFamily('serif')
              .fontColor('#FFFFFF')
              .minFontScale(1)
              .maxFontScale(1)
          }

          Text('一字日记')
            .fontSize(11)
            .fontFamily(this.fontFamily)
            .fontColor(this.textColor)
            .letterSpacing(2.4)
            .minFontScale(1)
            .maxFontScale(1)
        }
        .alignItems(VerticalAlign.Center)
      }
      .height(100)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .width(286)
    .height(this.cardHeight)
    .backgroundColor(this.paperColor)
    .border({ width: 1, color: this.paperId === 'plain_ash_dev' ? '#E5E5E2' : '#EEE5E1' })
    .borderRadius(2)
    .alignItems(HorizontalAlign.Center)
  }
}
