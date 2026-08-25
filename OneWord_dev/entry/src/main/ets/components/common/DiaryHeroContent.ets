import { RecordType } from '../../model/DailyRecord';

@Component
export struct DiaryHeroContent {
  @Prop recordType: RecordType = RecordType.WORD;
  @Prop content: string = '';
  @Prop contentCount: number = 0;
  @Prop note: string = '';
  @Prop fontId: string = 'system_serif_dev';
  @Prop accessibilityPrefix: string = '日记正文';

  get fontFamily(): string {
    return this.fontId === 'system_sans_dev' ? 'sans-serif' : 'serif';
  }

  @Builder
  private recordedWord() {
    if (this.contentCount <= 1) {
      Text(this.content)
        .fontSize(136)
        .fontFamily(this.fontFamily)
        .fontWeight(FontWeight.Normal)
        .fontColor($r('app.color.text_primary'))
        .textAlign(TextAlign.Center)
        .accessibilityText(`${this.accessibilityPrefix}，${this.content}`)
    } else if (this.contentCount === 2) {
      Text(this.content)
        .fontSize(76)
        .fontFamily(this.fontFamily)
        .fontWeight(FontWeight.Normal)
        .fontColor($r('app.color.text_primary'))
        .letterSpacing(3)
        .textAlign(TextAlign.Center)
        .accessibilityText(`${this.accessibilityPrefix}，${this.content}`)
    } else if (this.contentCount === 3) {
      Text(this.content)
        .fontSize(56)
        .fontFamily(this.fontFamily)
        .fontWeight(FontWeight.Normal)
        .fontColor($r('app.color.text_primary'))
        .letterSpacing(3)
        .textAlign(TextAlign.Center)
        .accessibilityText(`${this.accessibilityPrefix}，${this.content}`)
    } else {
      Text(this.content)
        .fontSize(44)
        .fontFamily(this.fontFamily)
        .fontWeight(FontWeight.Normal)
        .fontColor($r('app.color.text_primary'))
        .letterSpacing(3)
        .textAlign(TextAlign.Center)
        .accessibilityText(`${this.accessibilityPrefix}，${this.content}`)
    }
  }

  @Builder
  private recordedBlank() {
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
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    Column({ space: 10 }) {
      Stack({ alignContent: Alignment.Center }) {
        if (this.recordType === RecordType.BLANK) {
          this.recordedBlank()
        } else {
          this.recordedWord()
        }

        Row() {
          Blank()

          Text('已')
            .width(40)
            .height(40)
            .fontSize(20)
            .fontFamily('serif')
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .backgroundColor($r('app.color.accent_vermilion'))
            .textAlign(TextAlign.Center)
            .borderRadius(3)
            .accessibilityText('已收入长卷')
        }
        .width(260)
        .height(300)
        .padding({ top: 52 })
        .alignItems(VerticalAlign.Top)
      }
      .width(286)
      .height(300)

      if (this.recordType === RecordType.WORD) {
        Text('「 见字如面 」')
          .fontSize(14)
          .fontFamily('serif')
          .fontColor($r('app.color.text_tertiary'))
          .letterSpacing(3)
      }

      if (this.note.length > 0) {
        Text(this.note)
          .width(280)
          .fontSize(14)
          .lineHeight(22)
          .fontFamily(this.fontFamily)
          .fontColor($r('app.color.text_secondary'))
          .letterSpacing(0.6)
          .textAlign(TextAlign.Center)
          .maxLines(2)
          .accessibilityText(`备注，${this.note}`)
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .accessibilityGroup(true)
    .accessibilityText(this.recordType === RecordType.BLANK ?
      `正式留白${this.note.length > 0 ? `，备注，${this.note}` : ''}` :
      `${this.accessibilityPrefix}，${this.content}${this.note.length > 0 ? `，备注，${this.note}` : ''}`)
  }
}
