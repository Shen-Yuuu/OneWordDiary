import { RecordType } from '../../model/DailyRecord';
import { ScrollDisplayItem, ScrollItemSide } from '../../model/ScrollDisplayItem';

@Component
export struct ScrollRecordNode {
  @Prop item: ScrollDisplayItem = new ScrollDisplayItem(
    '', '', '', false, '', '', RecordType.BLANK, '', 0, '', '', ScrollItemSide.CENTER
  );
  onOpen: (localDate: string) => void = (localDate: string) => {
  };

  get recordFontFamily(): string {
    return this.item.fontId === 'system_sans_dev' ? 'sans-serif' : 'serif';
  }

  get recordPaperColor(): ResourceColor {
    return this.item.paperId === 'plain_ash_dev' ? $r('app.color.paper_plain') : $r('app.color.paper_warm');
  }

  get recordFontSize(): number {
    if (this.item.contentCount <= 1) {
      return 56;
    }
    if (this.item.contentCount === 2) {
      return 46;
    }
    return this.item.contentCount === 3 ? 39 : 34;
  }

  @Builder
  private wordContent() {
    Column({ space: 10 }) {
      Text(`${this.item.dayLabel}  ${this.item.weekdayLabel}`)
        .fontSize(12)
        .fontColor($r('app.color.text_tertiary'))
        .letterSpacing(1.2)

      Text(this.item.content)
        .fontSize(this.recordFontSize)
        .fontFamily(this.recordFontFamily)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .maxLines(1)

      Row()
        .width(32)
        .height(1)
        .backgroundColor(this.recordPaperColor)
        .border({ width: { bottom: 1 }, color: $r('app.color.outline_soft') })
    }
    .layoutWeight(1)
    .padding({ left: 18, right: 18, top: 12, bottom: 12 })
    .alignItems(this.item.side === ScrollItemSide.LEFT ? HorizontalAlign.End : HorizontalAlign.Start)
  }

  @Builder
  private blankContent() {
    Column({ space: 12 }) {
      Text(`${this.item.dayLabel}  ${this.item.weekdayLabel}`)
        .fontSize(12)
        .fontColor($r('app.color.text_tertiary'))
        .letterSpacing(1.2)
        .backgroundColor($r('app.color.paper_warm'))
        .padding({ left: 8, right: 8 })

      Stack({ alignContent: Alignment.Center }) {
        Row()
          .width(42)
          .height(42)
          .backgroundColor($r('app.color.paper_warm'))
          .border({ width: 1, color: $r('app.color.outline_soft') })
          .borderRadius(21)

        Row()
          .width(5)
          .height(5)
          .backgroundColor($r('app.color.accent_vermilion'))
          .borderRadius(2)
      }
    }
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    Column() {
      if (this.item.showMonthHeader) {
        Text(this.item.monthLabel)
          .fontSize(20)
          .fontFamily('serif')
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .letterSpacing(2.8)
          .margin({ top: 24, bottom: 22 })
          .accessibilityLevel('yes')
      }

      Stack({ alignContent: Alignment.Center }) {
        Row() {
          Blank()
            .layoutWeight(1)

          Divider()
            .vertical(true)
            .height(128)
            .strokeWidth(1)
            .color($r('app.color.divider_subtle'))

          Blank()
            .layoutWeight(1)
        }
        .width('100%')

        if (this.item.recordType === RecordType.BLANK) {
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
        }
      }
      .width('100%')
      .height(128)
      .onClick(() => this.onOpen(this.item.localDate))
      .accessibilityGroup(true)
      .accessibilityText(this.item.recordType === RecordType.BLANK ?
        `${this.item.localDate}，正式留白` : `${this.item.localDate}，${this.item.content}`)
    }
    .width('100%')
  }
}
