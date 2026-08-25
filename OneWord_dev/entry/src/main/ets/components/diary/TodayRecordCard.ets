import { DiaryIconButton } from '../common/DiaryIconButton';
import { DiaryPrimaryButton } from '../common/DiaryPrimaryButton';
import { RecordType } from '../../model/DailyRecord';

@Component
export struct TodayRecordCard {
  @Prop dateText: string = '';
  @Prop recordType: RecordType = RecordType.WORD;
  @Prop content: string = '';
  @Prop contentCount: number = 0;
  @Prop fontId: string = 'system_serif_dev';
  @Prop canRevise: boolean = false;
  @Prop revisionDeadline: string = '';
  @Prop finalLabel: string = '';
  @Prop recordCount: number = 0;
  onRevise: () => void = () => {
  };
  onShare: () => void = () => {
  };

  get fontFamily(): string {
    return this.fontId === 'system_sans_dev' ? 'sans-serif' : 'serif';
  }

  get heroTextWidth(): number {
    if (this.contentCount <= 1) {
      return 150;
    }
    if (this.contentCount === 2) {
      return 170;
    }
    return this.contentCount === 3 ? 190 : 200;
  }

  get heroGroupWidth(): number {
    return this.heroTextWidth + 76;
  }

  build() {
    Column() {
      Blank()

      Column({ space: 10 }) {
        Row({ space: 12 }) {
          if (this.recordType === RecordType.BLANK) {
            Column({ space: 14 }) {
              Stack({ alignContent: Alignment.Center }) {
                Row()
                  .width(86)
                  .height(86)
                  .border({ width: 1, color: $r('app.color.outline_soft') })
                  .borderRadius(43)

                Row()
                  .width(8)
                  .height(8)
                  .backgroundColor($r('app.color.accent_vermilion'))
                  .borderRadius(2)
              }

              Text('今日留白')
                .fontSize(24)
                .fontFamily('serif')
                .fontColor($r('app.color.text_primary'))
                .letterSpacing(4)
            }
            .width(this.heroTextWidth)
            .height(300)
            .flexShrink(0)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
          } else {
            Stack({ alignContent: Alignment.Center }) {
              if (this.contentCount <= 1) {
                Text(this.content)
                  .fontSize(136)
                  .fontFamily(this.fontFamily)
                  .fontWeight(FontWeight.Normal)
                  .fontColor($r('app.color.text_primary'))
                  .textAlign(TextAlign.Center)
                  .accessibilityText(`今日正文，${this.content}`)
              } else if (this.contentCount === 2) {
                Text(this.content)
                  .fontSize(76)
                  .fontFamily(this.fontFamily)
                  .fontWeight(FontWeight.Normal)
                  .fontColor($r('app.color.text_primary'))
                  .letterSpacing(3)
                  .textAlign(TextAlign.Center)
                  .accessibilityText(`今日正文，${this.content}`)
              } else if (this.contentCount === 3) {
                Text(this.content)
                  .fontSize(56)
                  .fontFamily(this.fontFamily)
                  .fontWeight(FontWeight.Normal)
                  .fontColor($r('app.color.text_primary'))
                  .letterSpacing(3)
                  .textAlign(TextAlign.Center)
                  .accessibilityText(`今日正文，${this.content}`)
              } else {
                Text(this.content)
                  .fontSize(44)
                  .fontFamily(this.fontFamily)
                  .fontWeight(FontWeight.Normal)
                  .fontColor($r('app.color.text_primary'))
                  .letterSpacing(3)
                  .textAlign(TextAlign.Center)
                  .accessibilityText(`今日正文，${this.content}`)
              }
            }
            .width(this.heroTextWidth)
            .height(300)
            .flexShrink(0)
          }

          Text('已')
            .width(64)
            .height(64)
            .fontSize(28)
            .fontFamily('serif')
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .backgroundColor($r('app.color.accent_vermilion'))
            .textAlign(TextAlign.Center)
            .borderRadius(3)
            .flexShrink(0)
            .accessibilityText('已收入长卷')
        }
        .width(this.heroGroupWidth)
        .height(300)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)

        if (this.recordType === RecordType.WORD) {
          Text('「 见字如面 」')
            .fontSize(14)
            .fontFamily('serif')
            .fontColor($r('app.color.text_tertiary'))
            .letterSpacing(3)
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .accessibilityGroup(true)
      .accessibilityText(this.recordType === RecordType.BLANK ? '今天选择了正式留白' : `今日正文，${this.content}`)

      if (this.canRevise) {
        Text(`尚可修订 1 次 · 截止 ${this.revisionDeadline}`)
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
          .letterSpacing(1)
          .textAlign(TextAlign.Center)
          .margin({ top: 34 })
          .accessibilityLevel('yes')
      } else {
        Text(this.finalLabel)
          .fontSize(13)
          .fontColor($r('app.color.accent_vermilion'))
          .margin({ top: 34 })
          .accessibilityLevel('yes')
      }

      Blank()

      if (this.canRevise) {
        Row({ space: 8 }) {
          Row()
            .width($r('app.float.touch_target_min'))
            .height($r('app.float.touch_target_min'))

          DiaryPrimaryButton({
            label: '修订今日',
            onTap: () => this.onRevise()
          })

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
        .fontSize(12)
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
