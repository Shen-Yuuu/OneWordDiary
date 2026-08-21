import { RecordType } from '../../model/DailyRecord';
import { DiaryDateFormatter } from '../../utils/DiaryDateFormatter';

@Component
export struct ShareSingleCard {
  @Prop localDate: string = '';
  @Prop recordType: RecordType = RecordType.WORD;
  @Prop content: string = '';
  @Prop fontId: string = 'system_serif_dev';
  @Prop paperId: string = 'warm_paper_dev';
  private readonly dateFormatter: DiaryDateFormatter = new DiaryDateFormatter();

  get paperColor(): string {
    return this.paperId === 'plain_ash_dev' ? '#FFFFFF' : '#FFFCFB';
  }

  get textColor(): string {
    return this.paperId === 'plain_ash_dev' ? '#242424' : '#282622';
  }

  get secondaryColor(): string {
    return this.paperId === 'plain_ash_dev' ? '#777775' : '#8C8783';
  }

  get accentColor(): string {
    return this.paperId === 'plain_ash_dev' ? '#626260' : '#A65C4D';
  }

  get fontFamily(): string {
    return this.fontId === 'system_sans_dev' ? 'sans-serif' : 'serif';
  }

  get wordSize(): number {
    if (this.content.length >= 4) {
      return 48;
    }
    if (this.content.length >= 2) {
      return 64;
    }
    return 94;
  }

  build() {
    Column() {
      Text(this.dateFormatter.compactLabel(this.localDate))
        .fontSize(12)
        .fontFamily('serif')
        .fontWeight(FontWeight.Light)
        .fontColor(this.secondaryColor)
        .letterSpacing(2.4)
        .minFontScale(1)
        .maxFontScale(1)
        .margin({ top: 42 })

      if (this.recordType === RecordType.WORD) {
        Text(this.content)
          .fontSize(this.wordSize)
          .fontFamily(this.fontFamily)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.textColor)
          .letterSpacing(this.content.length > 1 ? 2 : 0)
          .maxLines(1)
          .minFontScale(1)
          .maxFontScale(1)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
      } else {
        Column({ space: 14 }) {
          Stack({ alignContent: Alignment.Center }) {
            Row()
              .width(70)
              .height(70)
              .border({ width: 1, color: this.secondaryColor })
              .borderRadius(35)

            Row()
              .width(5)
              .height(5)
              .backgroundColor(this.accentColor)
              .borderRadius(2.5)
          }

          Text('留白')
            .fontSize(14)
            .fontFamily(this.fontFamily)
            .fontColor(this.secondaryColor)
            .letterSpacing(4)
            .minFontScale(1)
            .maxFontScale(1)
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }

      Row({ space: 9 }) {
        Stack({ alignContent: Alignment.Center }) {
          Row()
            .width(22)
            .height(22)
            .backgroundColor(this.accentColor)
            .borderRadius(2)

          Text('字')
            .fontSize(10)
            .fontFamily('serif')
            .fontColor('#FFFFFF')
            .minFontScale(1)
            .maxFontScale(1)
        }

        Text('一字日记')
          .fontSize(13)
          .fontFamily(this.fontFamily)
          .fontColor(this.textColor)
          .letterSpacing(3)
          .minFontScale(1)
          .maxFontScale(1)
      }
      .margin({ bottom: 38 })
      .alignItems(VerticalAlign.Center)
    }
    .width(286)
    .height(440)
    .backgroundColor(this.paperColor)
    .border({ width: 1, color: this.paperId === 'plain_ash_dev' ? '#E5E5E2' : '#EEE5E1' })
    .borderRadius(2)
    .shadow({ radius: 22, color: '#16000000', offsetX: 0, offsetY: 10 })
    .alignItems(HorizontalAlign.Center)
  }
}

