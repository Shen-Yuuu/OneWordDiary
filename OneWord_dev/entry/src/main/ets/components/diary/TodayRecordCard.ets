import { DiaryIconButton } from '../common/DiaryIconButton';
import { DiaryPrimaryButton } from '../common/DiaryPrimaryButton';
import { DiaryWordDisplay } from '../common/DiaryWordDisplay';
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

  build() {
    Column() {
      Blank()

      Column({ space: 10 }) {
        Row() {
          Row()
            .width(52)
            .height(52)

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
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
          } else {
            DiaryWordDisplay({
              content: this.content,
              contentCount: this.contentCount,
              fontFamily: this.fontFamily,
              stageHeight: 300,
              isHero: true,
              accessibilityPrefix: '今日正文'
            })
              .layoutWeight(1)
          }

          Text('已')
            .width(52)
            .height(52)
            .fontSize(22)
            .fontFamily('serif')
            .fontColor('#FFFFFF')
            .backgroundColor($r('app.color.accent_vermilion'))
            .textAlign(TextAlign.Center)
            .borderRadius(3)
            .accessibilityText('已收入长卷')
        }
        .width('100%')
        .height(300)
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
