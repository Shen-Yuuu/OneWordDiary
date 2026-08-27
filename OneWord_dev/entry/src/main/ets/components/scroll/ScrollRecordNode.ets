import { RecordType } from '../../model/DailyRecord';
import { ScrollDisplayItem, ScrollItemSide } from '../../model/ScrollDisplayItem';
import { ScrollLayoutMetrics } from '../../constants/ScrollLayoutMetrics';

@Component
struct ScrollAxisNode {
  @Prop recordType: RecordType = RecordType.WORD;
  @Prop isMissing: boolean = false;
  @Prop nodeHeight: number = ScrollLayoutMetrics.RECORD_HEIGHT;
  @Prop lineColor: string = '#D8C7C0';

  build() {
    Column() {
      Divider()
        .vertical(true)
        .height((this.nodeHeight - ScrollLayoutMetrics.AXIS_MARKER_BOX_SIZE) / 2)
        .strokeWidth(1)
        .color(this.lineColor)

      if (this.isMissing) {
        Image($r('app.media.timeline_missing_node'))
          .width(ScrollLayoutMetrics.AXIS_MARKER_BOX_SIZE)
          .height(ScrollLayoutMetrics.AXIS_MARKER_BOX_SIZE)
      } else if (this.recordType === RecordType.BLANK) {
        Image($r('app.media.timeline_blank_node'))
          .width(ScrollLayoutMetrics.AXIS_MARKER_BOX_SIZE)
          .height(ScrollLayoutMetrics.AXIS_MARKER_BOX_SIZE)
      } else {
        Image($r('app.media.timeline_word_node'))
          .width(ScrollLayoutMetrics.AXIS_MARKER_BOX_SIZE)
          .height(ScrollLayoutMetrics.AXIS_MARKER_BOX_SIZE)
      }

      Divider()
        .vertical(true)
        .height((this.nodeHeight - ScrollLayoutMetrics.AXIS_MARKER_BOX_SIZE) / 2)
        .strokeWidth(1)
        .color(this.lineColor)
    }
    .width(ScrollLayoutMetrics.AXIS_MARKER_BOX_SIZE)
    .height(this.nodeHeight)
    .alignItems(HorizontalAlign.Center)
  }
}

@Component
export struct ScrollRecordNode {
  @Prop item: ScrollDisplayItem = new ScrollDisplayItem(
    '', '', '', false, '', '', RecordType.BLANK, '', 0, '', '', ScrollItemSide.CENTER
  );
  @Prop noteText: string = '';
  @Prop isInteractive: boolean = true;
  onOpen: (localDate: string) => void = (localDate: string) => {
  };

  get recordFontFamily(): string {
    return this.item.fontId === 'system_sans_dev' ? 'sans-serif' : 'serif';
  }

  get recordFontSize(): number {
    if (this.item.contentCount <= 1) {
      return 42;
    }
    if (this.item.contentCount === 2) {
      return 36;
    }
    return this.item.contentCount === 3 ? 32 : 28;
  }

  get recordLineHeight(): number {
    if (this.item.contentCount <= 1) {
      return 48;
    }
    if (this.item.contentCount === 2) {
      return 44;
    }
    return this.item.contentCount === 3 ? 40 : 36;
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
    return this.item.paperId === 'plain_ash_dev' ? '#CFCFCA' : '#D8C7C0';
  }

  get accentColor(): string {
    return this.item.paperId === 'plain_ash_dev' ? '#626260' : '#A65C4D';
  }

  get visibleNote(): string {
    return this.noteText;
  }

  get shouldShowNote(): boolean {
    return this.noteText.length > 0;
  }

  get nodeHeight(): number {
    return ScrollLayoutMetrics.nodeHeight(this.item.isMissing, this.shouldShowNote);
  }

  get totalHeight(): number {
    return ScrollLayoutMetrics.totalHeight(
      this.item.isMissing,
      this.shouldShowNote,
      this.item.showMonthHeader
    );
  }

  @Builder
  private noteContent(textAlign: TextAlign) {
    Text(this.visibleNote)
      .width(104)
      .height(28)
      .fontSize(10)
      .lineHeight(14)
      .fontFamily(this.recordFontFamily)
      .fontColor(this.secondaryColor)
      .maxLines(2)
      .textAlign(textAlign)
      .minFontScale(1)
      .maxFontScale(1)
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

      if (this.shouldShowNote) {
        this.noteContent(this.item.side === ScrollItemSide.LEFT ? TextAlign.End : TextAlign.Start)
      }

      Row()
        .width(32)
        .height(1)
        .backgroundColor(this.lineColor)
    }
    .layoutWeight(1)
    .height(this.nodeHeight)
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

      Blank()

      if (this.shouldShowNote) {
        this.noteContent(TextAlign.End)
      }
    }
    .layoutWeight(1)
    .height(this.nodeHeight)
    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
    .alignItems(HorizontalAlign.End)
  }

  @Builder
  private missingContent() {
    Column() {
      Text(`${this.item.dayLabel}  ${this.item.weekdayLabel}`)
        .fontSize(11)
        .fontColor(this.faintColor)
        .letterSpacing(1)

      Blank()
    }
    .layoutWeight(1)
    .height(this.nodeHeight)
    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
    .alignItems(HorizontalAlign.End)
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

      Row() {
        if (this.item.isMissing) {
          this.missingContent()
          ScrollAxisNode({
            recordType: this.item.recordType,
            isMissing: true,
            nodeHeight: this.nodeHeight,
            lineColor: this.lineColor
          })
          Blank().layoutWeight(1)
        } else if (this.item.recordType === RecordType.BLANK) {
          this.blankContent()
          ScrollAxisNode({
            recordType: this.item.recordType,
            isMissing: false,
            nodeHeight: this.nodeHeight,
            lineColor: this.lineColor
          })
          Blank().layoutWeight(1)
        } else {
          if (this.item.side === ScrollItemSide.LEFT) {
            this.wordContent()
            ScrollAxisNode({
              recordType: this.item.recordType,
              isMissing: false,
              nodeHeight: this.nodeHeight,
              lineColor: this.lineColor
            })
            Blank().layoutWeight(1)
          } else {
            Blank().layoutWeight(1)
            ScrollAxisNode({
              recordType: this.item.recordType,
              isMissing: false,
              nodeHeight: this.nodeHeight,
              lineColor: this.lineColor
            })
            this.wordContent()
          }
        }
      }
      .width('100%')
      .height(this.nodeHeight)
      .alignItems(VerticalAlign.Center)
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
          `${this.item.localDate}，${this.item.content}${this.shouldShowNote ? `，备注，${this.visibleNote}` : ''}`)
    }
    .width('100%')
    .height(this.totalHeight)
  }
}
