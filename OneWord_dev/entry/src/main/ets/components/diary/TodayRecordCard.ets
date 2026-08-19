import { DiaryIconButton } from '../common/DiaryIconButton';
import { RecordType } from '../../model/DailyRecord';

@Component
export struct TodayRecordCard {
  @Prop dateText: string = '';
  @Prop recordType: RecordType = RecordType.WORD;
  @Prop content: string = '';
  @Prop contentCount: number = 0;
  @Prop canRevise: boolean = false;
  @Prop revisionDeadline: string = '';
  @Prop finalLabel: string = '';
  @Prop recordCount: number = 0;
  onRevise: () => void = () => {
  };
  onShare: () => void = () => {
  };

  get contentFontSize(): number {
    if (this.contentCount <= 1) {
      return 108;
    }
    if (this.contentCount === 2) {
      return 80;
    }
    return this.contentCount === 3 ? 64 : 52;
  }

  build() {
    Column() {
      Blank()

      Stack({ alignContent: Alignment.TopEnd }) {
        Column({ space: 22 }) {
          if (this.recordType === RecordType.BLANK) {
            Stack({ alignContent: Alignment.Center }) {
              Row()
                .width(82)
                .height(82)
                .border({ width: 1, color: $r('app.color.outline_soft') })
                .borderRadius(41)

              Row()
                .width(7)
                .height(7)
                .backgroundColor($r('app.color.accent_vermilion'))
                .borderRadius(2)
            }

            Text('今日留白')
              .fontSize(22)
              .fontFamily('serif')
              .fontColor($r('app.color.text_primary'))
              .letterSpacing(4)
          } else {
            Text(this.content)
              .fontSize(this.contentFontSize)
              .fontFamily('serif')
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
              .textAlign(TextAlign.Center)
              .maxLines(1)
              .accessibilityText(`今日正文，${this.content}`)

            Text('「 见字如面 」')
              .fontSize(12)
              .fontFamily('serif')
              .fontColor($r('app.color.text_tertiary'))
              .letterSpacing(3)
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .accessibilityText(this.recordType === RecordType.BLANK ? '今天选择了正式留白' : `今日正文，${this.content}`)

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

      if (this.canRevise) {
        Text(`尚可修订 1 次 · 截止 ${this.revisionDeadline}`)
          .fontSize(11)
          .fontColor($r('app.color.text_secondary'))
          .letterSpacing(1)
          .textAlign(TextAlign.Center)
          .margin({ top: 38 })
          .accessibilityLevel('yes')
      } else {
        Text(this.finalLabel)
          .fontSize(11)
          .fontColor($r('app.color.accent_vermilion'))
          .margin({ top: 38 })
          .accessibilityLevel('yes')
      }

      Blank()

      if (this.canRevise) {
        Row({ space: 8 }) {
          Row()
            .width($r('app.float.touch_target_min'))
            .height($r('app.float.touch_target_min'))

          Button('修订今日')
            .width($r('app.float.primary_button_width'))
            .height($r('app.float.primary_button_height'))
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .backgroundColor($r('app.color.ink_button'))
            .borderRadius(26)
            .onClick(() => this.onRevise())

          DiaryIconButton({
            icon: $r('app.media.ic_share'),
            accessibilityLabel: '分享今天',
            bordered: true,
            onTap: () => this.onShare()
          })
        }
        .justifyContent(FlexAlign.Center)
      } else {
        DiaryIconButton({
          icon: $r('app.media.ic_share'),
          accessibilityLabel: '分享今天',
          bordered: true,
          onTap: () => this.onShare()
        })
      }

      Text(`已留下 ${this.recordCount} 天`)
        .fontSize(10)
        .fontColor($r('app.color.text_tertiary'))
        .letterSpacing(1.4)
        .margin({ top: 14, bottom: 14 })
    }
    .width('100%')
    .height('100%')
    .padding({ left: 12, right: 12 })
    .alignItems(HorizontalAlign.Center)
  }
}
