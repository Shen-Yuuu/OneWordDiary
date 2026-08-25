import { DiaryHeroContent } from '../common/DiaryHeroContent';
import { DiaryIconButton } from '../common/DiaryIconButton';
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

  build() {
    Column() {
      Blank()

      Column({ space: 12 }) {
        DiaryHeroContent({
          recordType: this.recordType,
          content: this.content,
          contentCount: this.contentCount,
          note: this.note,
          fontId: this.fontId,
          accessibilityPrefix: '日记正文'
        })

        Text(this.dateLabel)
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .letterSpacing(1.4)
          .margin({ top: 8 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .accessibilityGroup(true)
      .accessibilityText(this.recordType === RecordType.BLANK ?
        `${this.dateLabel}，正式留白` :
        `${this.dateLabel}，${this.content}${this.note.length > 0 ? `，备注，${this.note}` : ''}`)

      Blank()

      DiaryIconButton({
        icon: $r('app.media.ic_share'),
        accessibilityLabel: '分享这一天',
        bordered: true,
        onTap: () => this.onShare()
      })
        .margin({ bottom: 22 })
    }
    .width('100%')
    .height('100%')
    .padding({ left: 28, right: 28 })
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(Color.Transparent)
  }
}
