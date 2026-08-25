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
