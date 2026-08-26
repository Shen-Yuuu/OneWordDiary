import { RecordType } from '../../model/DailyRecord';
import { ScrollDisplayItem, ScrollItemSide } from '../../model/ScrollDisplayItem';
import { ScrollLayoutMetrics } from '../../constants/ScrollLayoutMetrics';

@Component
export struct ScrollRecordNode {
  @Prop item: ScrollDisplayItem = new ScrollDisplayItem(
    '', '', '', false, '', '', RecordType.BLANK, '', 0, '', '', ScrollItemSide.CENTER
  );
  @Prop isInteractive: boolean = true;
  onOpen: (localDate: string) => void = (localDate: string) => {
  };

  get recordFontFamily(): string {
    return this.item.fontId === 'system_sans_dev' ? 'sans-serif' : 'serif';
  }

  get recordFontSize(): string {
    if (this.item.contentCount <= 1) {
      return '42vp';
    }
    if (this.item.contentCount === 2) {
      return '36vp';
    }
    return this.item.contentCount === 3 ? '32vp' : '28vp';
  }

  get recordLineHeight(): string {
    if (this.item.contentCount <= 1) {
      return '48vp';
    }
    if (this.item.contentCount === 2) {
      return '44vp';
    }
    return this.item.contentCount === 3 ? '40vp' : '36vp';
  }

  get paperColor(): string {
    return this.item.paperId === 'plain_ash_dev' ? '#FFFFFF' : '#FFFCFB';
  }

  get textColor(): string {
    return this.item.paperId === 'plain_ash_dev' ? '#242424' : '#282622';
  }

  get secondaryColor(): string {
    return this.item.paperId === 'plain_ash_dev' ? '#777775' : '#8C8783';
  }

  get faintColor(): string {
    return this.item.paperId === 'plain_ash_dev' ? '#AFAFAC' : '#B8ADA7';
  }

  get lineColor(): string {
    return this.item.paperId === 'plain_ash_dev' ? '#D8D8D4' : '#E0D5D0';
  }

  get accentColor(): string {
    return this.item.paperId === 'plain_ash_dev' ? '#626260' : '#A65C4D';
  }

  get visibleNote(): string {
    return this.item.note.length > 0 ? this.item.note : '这条记录没有备注';
  }

  get nodeHeight(): number {
    return ScrollLayoutMetrics.nodeHeight(this.item.isMissing, this.item.showNote);
  }

  get totalHeight(): number {
    return this.nodeHeight +
      (this.item.showMonthHeader ? ScrollLayoutMetrics.MONTH_HEADER_HEIGHT : 0);
  }

  @Builder
  private wordContent() {
    Column({ space: 4 }) {
      Text(`${this.item.dayLabel}  ${this.item.weekdayLabel}`)
        .fontSize(11)
        .fontColor(this.secondaryColor)
        .letterSpacing(1)

      Text(this.item.content)
        .fontSize(this.recordFontSize)
        .lineHeight(this.recordLineHeight)
        .fontFamily(this.recordFontFamily)
        .fontWeight(FontWeight.Normal)
        .fontColor(this.textColor)
        .letterSpacing(this.item.contentCount > 1 ? 2 : 0)
        .minFontScale(1)
        .maxFontScale(1)
        .maxLines(1)

      if (this.item.showNote) {
        Text(this.visibleNote)
          .width('100%')
          .fontSize(10)
          .lineHeight(14)
          .fontFamily(this.recordFontFamily)
          .fontColor(this.secondaryColor)
          .maxLines(2)
          .textAlign(this.item.side === ScrollItemSide.LEFT ? TextAlign.End : TextAlign.Start)
      }

      Row()
        .width(32)
        .height(1)
        .backgroundColor(this.lineColor)
    }
    .layoutWeight(1)
    .height('100%')
    .padding({ left: 12, right: 12, top: 4, bottom: 4 })
    .justifyContent(FlexAlign.Center)
    .alignItems(this.item.side === ScrollItemSide.LEFT ? HorizontalAlign.End : HorizontalAlign.Start)
  }

  @Builder
  private blankContent() {
    Column() {
      Text(`${this.item.dayLabel}  ${this.item.weekdayLabel}`)
        .fontSize(11)
        .fontColor(this.secondaryColor)
        .letterSpacing(1)
        .backgroundColor(this.paperColor)
        .padding({ left: 8, right: 8 })

      Blank()

      if (this.item.showNote) {
        Text(this.visibleNote)
          .width(150)
          .fontSize(10)
          .lineHeight(14)
          .fontFamily(this.recordFontFamily)
          .fontColor(this.secondaryColor)
          .maxLines(2)
          .textAlign(TextAlign.Center)
      }
    }
    .width(176)
    .height('100%')
    .padding({ top: 6, bottom: 6 })
    .alignItems(HorizontalAlign.Center)
    .zIndex(1)
  }

  @Builder
  private missingContent() {
    Column() {
      Text(`${this.item.dayLabel}  ${this.item.weekdayLabel}`)
        .fontSize(11)
        .fontColor(this.faintColor)
        .letterSpacing(1)
        .backgroundColor(this.paperColor)
        .padding({ left: 8, right: 8 })

      Blank()
    }
    .width(176)
    .height('100%')
    .padding({ top: 6, bottom: 6 })
    .alignItems(HorizontalAlign.Center)
    .zIndex(1)
  }

  @Builder
  private axisMarker() {
    if (this.item.isMissing) {
      Row()
        .width(ScrollLayoutMetrics.MISSING_NODE_SIZE)
        .height(ScrollLayoutMetrics.MISSING_NODE_SIZE)
        .backgroundColor(this.paperColor)
        .border({ width: 1, color: this.faintColor })
        .borderRadius(ScrollLayoutMetrics.MISSING_NODE_SIZE / 2)
        .zIndex(3)
    } else if (this.item.recordType === RecordType.BLANK) {
      Stack({ alignContent: Alignment.Center }) {
        Row()
          .width(ScrollLayoutMetrics.BLANK_NODE_SIZE)
          .height(ScrollLayoutMetrics.BLANK_NODE_SIZE)
          .backgroundColor(this.paperColor)
          .border({ width: 2, color: this.accentColor })
          .borderRadius(ScrollLayoutMetrics.BLANK_NODE_SIZE / 2)

        Row()
          .width(4)
          .height(4)
          .backgroundColor(this.accentColor)
          .borderRadius(2)
      }
      .zIndex(3)
    } else {
      Stack({ alignContent: Alignment.Center }) {
        Row()
          .width(ScrollLayoutMetrics.WORD_NODE_SIZE + 4)
          .height(ScrollLayoutMetrics.WORD_NODE_SIZE + 4)
          .backgroundColor(this.paperColor)
          .borderRadius((ScrollLayoutMetrics.WORD_NODE_SIZE + 4) / 2)

        Row()
          .width(ScrollLayoutMetrics.WORD_NODE_SIZE)
          .height(ScrollLayoutMetrics.WORD_NODE_SIZE)
          .backgroundColor(this.accentColor)
          .borderRadius(ScrollLayoutMetrics.WORD_NODE_SIZE / 2)
      }
      .zIndex(3)
    }
  }

  build() {
    Column() {
      if (this.item.showMonthHeader) {
        Text(this.item.monthLabel)
          .width('100%')
          .height(ScrollLayoutMetrics.MONTH_HEADER_HEIGHT)
          .fontSize(18)
          .fontFamily('serif')
          .fontWeight(FontWeight.Medium)
          .fontColor(this.textColor)
          .letterSpacing(2.8)
          .textAlign(TextAlign.Center)
          .accessibilityLevel('yes')
      }

      Stack({ alignContent: Alignment.Center }) {
        Row() {
          Blank()
            .layoutWeight(1)

          Divider()
            .vertical(true)
            .height(this.nodeHeight)
            .strokeWidth(1)
            .color(this.lineColor)
            .zIndex(0)

          Blank()
            .layoutWeight(1)
        }
        .width('100%')

        if (this.item.isMissing) {
          this.missingContent()
        } else if (this.item.recordType === RecordType.BLANK) {
          this.blankContent()
        } else {
          Row() {
            if (this.item.side === ScrollItemSide.LEFT) {
              this.wordContent()
              Blank().layoutWeight(1)
            } else {
              Blank().layoutWeight(1)
              this.wordContent()
            }
          }
          .width('100%')
          .height('100%')
          .zIndex(1)
        }

        this.axisMarker()
      }
      .width('100%')
      .height(this.nodeHeight)
      .clip(false)
      .onClick(() => {
        if (this.isInteractive && !this.item.isMissing) {
          this.onOpen(this.item.localDate);
        }
      })
      .accessibilityGroup(true)
      .accessibilityText(this.item.isMissing ?
        `${this.item.localDate}，没有记录` :
        this.item.recordType === RecordType.BLANK ?
          `${this.item.localDate}，正式留白` :
          `${this.item.localDate}，${this.item.content}${this.item.showNote ? `，备注，${this.visibleNote}` : ''}`)
    }
    .width('100%')
    .height(this.totalHeight)
  }
}
