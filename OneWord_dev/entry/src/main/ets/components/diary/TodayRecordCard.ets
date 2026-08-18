import { RecordType } from '../../model/DailyRecord';

@Component
export struct TodayRecordCard {
  @Prop dateText: string = '';
  @Prop recordType: RecordType = RecordType.WORD;
  @Prop content: string = '';
  @Prop canRevise: boolean = false;
  @Prop revisionDeadline: string = '';
  @Prop finalLabel: string = '';
  @Prop recordCount: number = 0;
  onRevise: () => void = () => {
  };
  onShare: () => void = () => {
  };

  build() {
    Column() {
      Text(this.dateText)
        .fontSize(13)
        .fontWeight(FontWeight.Lighter)
        .fontColor($r('app.color.text_secondary'))
        .letterSpacing(1.6)
        .margin({ top: 18 })

      Blank()

      if (this.recordType === RecordType.BLANK) {
        Column({ space: 18 }) {
          Row()
            .width(34)
            .height(34)
            .border({ width: 1, color: $r('app.color.divider_subtle') })
            .borderRadius(18)

          Text('今日留白')
            .fontSize(18)
            .fontFamily('serif')
            .fontColor($r('app.color.text_primary'))
            .letterSpacing(3)
        }
        .accessibilityText('今天选择了正式留白')
      } else {
        Text(this.content)
          .fontSize(96)
          .fontFamily('serif')
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .textAlign(TextAlign.Center)
          .maxLines(1)
          .accessibilityText(`今日正文，${this.content}`)

      }

      Blank()

      if (this.canRevise) {
        Text(`今日尚可修订 1 次，至 ${this.revisionDeadline}`)
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .textAlign(TextAlign.Center)
          .margin({ bottom: 12 })
          .accessibilityLevel('yes')

        Button('修订')
          .width('100%')
          .height(50)
          .fontSize(13)
          .fontColor('#FFFFFF')
          .backgroundColor($r('app.color.text_primary'))
          .borderRadius(25)
          .onClick(() => this.onRevise())
      } else {
        Text(this.finalLabel)
          .fontSize(12)
          .fontColor($r('app.color.accent_vermilion'))
          .letterSpacing(2)
          .margin({ bottom: 12 })
          .accessibilityLevel('yes')

      }

      Button('分享今天')
        .width('100%')
        .height(50)
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
        .backgroundColor(Color.Transparent)
        .border({ width: 1, color: $r('app.color.divider_subtle') })
        .borderRadius(25)
        .margin({ top: this.canRevise ? 12 : 0 })
        .onClick(() => this.onShare())

      Text(`已留下 ${this.recordCount} 天`)
        .fontSize(11)
        .fontColor($r('app.color.text_secondary'))
        .letterSpacing(1.2)
        .margin({ top: 18, bottom: 22 })
    }
    .width('100%')
    .height('100%')
    .padding({ left: 12, right: 12 })
    .alignItems(HorizontalAlign.Center)
  }
}
