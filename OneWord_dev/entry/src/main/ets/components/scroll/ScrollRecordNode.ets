import { RecordType } from '../../model/DailyRecord';
import { ScrollDisplayItem, ScrollItemSide } from '../../model/ScrollDisplayItem';

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
      return '48vp';
    }
    if (this.item.contentCount === 2) {
      return '42vp';
    }
    return this.item.contentCount === 3 ? '36vp' : '32vp';
  }

  get recordLineHeight(): string {
    if (this.item.contentCount <= 1) {
      return '60vp';
    }
    if (this.item.contentCount === 2) {
      return '54vp';
    }
    return this.item.contentCount === 3 ? '48vp' : '44vp';
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
    if (this.item.isMissing) {
      return 92;
    }
    return this.item.showNote ? 166 : 136;
  }

  @Builder
  private wordContent() {
    Column({ space: 8 }) {
      Text(`${this.item.dayLabel}  ${this.item.weekdayLabel}`)
        .fontSize(12)
        .fontColor(this.secondaryColor)
        .letterSpacing(1.2)

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
          .lineHeight(15)
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
    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
    .alignItems(this.item.side === ScrollItemSide.LEFT ? HorizontalAlign.End : HorizontalAlign.Start)
  }

  @Builder
  private blankContent() {
    Column({ space: 10 }) {
      Text(`${this.item.dayLabel}  ${this.item.weekdayLabel}`)
        .fontSize(12)
        .fontColor(this.secondaryColor)
        .letterSpacing(1.2)
        .backgroundColor(this.paperColor)
        .padding({ left: 8, right: 8 })

      Stack({ alignContent: Alignment.Center }) {
        Row()
          .width(42)
          .height(42)
          .backgroundColor(this.paperColor)
          .border({ width: 1, color: this.lineColor })
          .borderRadius(21)

        Row()
          .width(5)
          .height(5)
          .backgroundColor(this.accentColor)
          .borderRadius(2)
      }

      if (this.item.showNote) {
        Text(this.visibleNote)
          .width(150)
          .fontSize(10)
          .lineHeight(15)
          .fontFamily(this.recordFontFamily)
          .fontColor(this.secondaryColor)
          .maxLines(2)
          .textAlign(TextAlign.Center)
      }
    }
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private missingContent() {
    Column({ space: 10 }) {
      Text(`${this.item.dayLabel}  ${this.item.weekdayLabel}`)
        .fontSize(11)
        .fontColor(this.faintColor)
        .letterSpacing(1)
        .backgroundColor(this.paperColor)
        .padding({ left: 8, right: 8 })

      Row()
        .width(18)
        .height(18)
        .backgroundColor(this.paperColor)
        .border({ width: 1, color: this.faintColor })
        .borderRadius(9)
    }
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    Column() {
      if (this.item.showMonthHeader) {
        Text(this.item.monthLabel)
          .width('100%')
          .height(70)
          .fontSize(20)
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

          Row()
            .width(6)
            .height(6)
            .backgroundColor(this.accentColor)
            .borderRadius(3)
        }
      }
      .width('100%')
      .height(this.nodeHeight)
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
  }
}
