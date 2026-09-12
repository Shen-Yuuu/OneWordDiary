import { DiaryHeroContent } from '../common/DiaryHeroContent';
import { DiaryIconButton } from '../common/DiaryIconButton';
import { DiaryPrimaryButton } from '../common/DiaryPrimaryButton';
import { RecordType } from '../../model/DailyRecord';

@Component
export struct TodayRecordCard {
  @Prop dateText: string = '';
  @Prop recordType: RecordType = RecordType.WORD;
  @Prop content: string = '';
  @Prop contentCount: number = 0;
  @Prop note: string = '';
  @Prop fontId: string = 'system_serif_dev';
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
      Blank()

      DiaryHeroContent({
        recordType: this.recordType,
        content: this.content,
        contentCount: this.contentCount,
        note: this.note,
        fontId: this.fontId,
        accessibilityPrefix: '今日正文'
      })

      Blank()

      if (this.canRevise) {
        Row({ space: 8 }) {
          Row()
            .width($r('app.float.touch_target_min'))
            .height($r('app.float.touch_target_min'))

          Column({ space: 8 }) {
            Text('尚可修订 1 次')
              .fontSize(13)
              .fontColor($r('app.color.text_secondary'))
              .letterSpacing(1)
              .textAlign(TextAlign.Center)
              .accessibilityLevel('yes')

            DiaryPrimaryButton({
              label: '修订今日',
              onTap: () => this.onRevise()
            })
          }
          .alignItems(HorizontalAlign.Center)

          DiaryIconButton({
            icon: $r('app.media.ic_share'),
            accessibilityLabel: '分享今天',
            bordered: true,
            onTap: () => this.onShare()
          })
        }
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Bottom)
      } else {
        Column({ space: 10 }) {
          Text(this.finalLabel)
            .fontSize(13)
            .fontColor($r('app.color.accent_vermilion'))
            .letterSpacing(1)
            .accessibilityLevel('yes')

          DiaryIconButton({
            icon: $r('app.media.ic_share'),
            accessibilityLabel: '分享今天',
            bordered: true,
            onTap: () => this.onShare()
          })
        }
        .alignItems(HorizontalAlign.Center)
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
