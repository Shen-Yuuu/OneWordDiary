import { RecordType } from '../../model/DailyRecord';

@Component
export struct DetailRecordContent {
  @Prop dateLabel: string = '';
  @Prop recordType: RecordType = RecordType.WORD;
  @Prop content: string = '';
  @Prop contentCount: number = 0;
  @Prop note: string = '';
  @Prop fontId: string = '';
  @Prop paperId: string = '';
  onShare: () => void = () => {
  };

  get recordFontFamily(): string {
    return this.fontId === 'system_sans_dev' ? 'sans-serif' : 'serif';
  }

  get paperColor(): string {
    return this.paperId === 'plain_ash_dev' ? '#F7F7F5' : '#FDF8F7';
  }

  get contentFontSize(): number {
    if (this.contentCount <= 1) {
      return 104;
    }
    if (this.contentCount === 2) {
      return 82;
    }
    return this.contentCount === 3 ? 64 : 50;
  }

  build() {
    Column() {
      Blank()

      Stack({ alignContent: Alignment.TopEnd }) {
        Column() {
          if (this.recordType === RecordType.BLANK) {
            Stack({ alignContent: Alignment.Center }) {
              Row()
                .width(78)
                .height(78)
                .border({ width: 1, color: $r('app.color.divider_subtle') })
                .borderRadius(40)

              Row()
                .width(8)
                .height(8)
                .backgroundColor($r('app.color.divider_subtle'))
                .borderRadius(4)
            }

            Text('今日留白')
              .fontSize(20)
              .fontFamily('serif')
              .fontColor($r('app.color.text_primary'))
              .letterSpacing(4)
              .margin({ top: 26 })
          } else {
            Text(this.content)
              .fontSize(this.contentFontSize)
              .fontFamily(this.recordFontFamily)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
              .maxLines(1)
              .textAlign(TextAlign.Center)
          }

          Text(this.dateLabel)
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
            .letterSpacing(1.5)
            .margin({ top: 34 })

          if (this.note.length > 0) {
            Text(this.note)
              .fontSize(16)
              .fontColor($r('app.color.text_secondary'))
              .lineHeight(28)
              .letterSpacing(0.8)
              .textAlign(TextAlign.Center)
              .margin({ top: 24 })
              .maxLines(4)
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .accessibilityGroup(true)
        .accessibilityText(this.recordType === RecordType.BLANK ?
          `${this.dateLabel}，正式留白` : `${this.dateLabel}，${this.content}${this.note.length > 0 ? `，注解，${this.note}` : ''}`)

        Text('已')
          .width(24)
          .height(24)
          .fontSize(11)
          .fontColor('#FFFFFF')
          .backgroundColor($r('app.color.accent_vermilion'))
          .textAlign(TextAlign.Center)
          .borderRadius(2)
          .accessibilityText('已收入长卷')
      }
      .width('100%')

      Blank()

      Button('分享')
        .width(56)
        .height(56)
        .fontSize(12)
        .fontColor('#FFFFFF')
        .backgroundColor($r('app.color.text_primary'))
        .borderRadius(28)
        .accessibilityText('分享这一天')
        .margin({ bottom: 28 })
        .onClick(() => this.onShare())
    }
    .width('100%')
    .height('100%')
    .padding({ left: 28, right: 28 })
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(this.paperColor)
  }
}
