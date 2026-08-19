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

  get recordFontFamily(): string {
    return this.fontId === 'system_sans_dev' ? 'sans-serif' : 'serif';
  }

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
              .fontFamily(this.recordFontFamily)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
              .maxLines(1)
              .textAlign(TextAlign.Center)

            Text('「 见字如面 」')
              .fontSize(12)
              .fontFamily('serif')
              .fontColor($r('app.color.text_tertiary'))
              .letterSpacing(3)
          }

          Text(this.dateLabel)
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
            .letterSpacing(1.4)
            .margin({ top: 10 })

          if (this.note.length > 0) {
            Column({ space: 14 }) {
              Divider()
                .width(36)
                .strokeWidth(1)
                .color($r('app.color.outline_soft'))

              Text(this.note)
                .fontSize(15)
                .fontColor($r('app.color.text_secondary'))
                .lineHeight(26)
                .letterSpacing(0.8)
                .textAlign(TextAlign.Center)
                .maxLines(4)
            }
            .alignItems(HorizontalAlign.Center)
            .margin({ top: 10 })
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .accessibilityGroup(true)
        .accessibilityText(this.recordType === RecordType.BLANK ?
          `${this.dateLabel}，正式留白` :
          `${this.dateLabel}，${this.content}${this.note.length > 0 ? `，注解，${this.note}` : ''}`)

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
