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

  get recordPaperColor(): string {
    return this.item.paperId === 'plain_ash_dev' ? '#F7F7F5' : '#FDF8F7';
  }

  get recordFontSize(): number {
    if (this.item.contentCount <= 1) {
      return 50;
    }
    if (this.item.contentCount === 2) {
      return 42;
    }
    return this.item.contentCount === 3 ? 36 : 32;
  }

  @Builder
  private wordContent() {
    Column({ space: 12 }) {
      Text(`${this.item.dayLabel}  ${this.item.weekdayLabel}`)
        .fontSize(12)
        .fontColor($r('app.color.text_secondary'))
        .letterSpacing(1.2)

      Text(this.item.content)
        .fontSize(this.recordFontSize)
        .fontFamily(this.recordFontFamily)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .maxLines(1)
    }
    .layoutWeight(1)
    .padding({ left: 22, right: 22, top: 10, bottom: 10 })
    .backgroundColor(this.recordPaperColor)
    .borderRadius(12)
    .alignItems(this.item.side === ScrollItemSide.LEFT ? HorizontalAlign.End : HorizontalAlign.Start)
  }

  @Builder
  private blankContent() {
    Column({ space: 12 }) {
      Text(`${this.item.dayLabel}  ${this.item.weekdayLabel}`)
        .fontSize(12)
        .fontColor($r('app.color.text_secondary'))
        .letterSpacing(1.2)
        .backgroundColor($r('app.color.app_background'))
        .padding({ left: 8, right: 8 })

      Stack({ alignContent: Alignment.Center }) {
        Row()
          .width(42)
          .height(42)
          .border({ width: 1, color: $r('app.color.divider_subtle') })
          .borderRadius(22)

        Row()
          .width(6)
          .height(6)
          .backgroundColor($r('app.color.divider_subtle'))
          .borderRadius(3)
      }
      .backgroundColor($r('app.color.app_background'))
      .padding(4)
    }
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    Column() {
      if (this.item.showMonthHeader) {
        Text(this.item.monthLabel)
          .fontSize(22)
          .fontFamily('serif')
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .letterSpacing(2.4)
          .margin({ top: 20, bottom: 26 })
          .accessibilityLevel('yes')
      }

      Stack({ alignContent: Alignment.Center }) {
        Row() {
          Blank()
            .layoutWeight(1)

          Divider()
            .vertical(true)
            .height(136)
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
      .height(136)
      .onClick(() => this.onOpen(this.item.localDate))
      .accessibilityGroup(true)
      .accessibilityText(this.item.recordType === RecordType.BLANK ?
        `${this.item.localDate}，正式留白` : `${this.item.localDate}，${this.item.content}`)
    }
    .width('100%')
  }
}
