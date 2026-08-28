import { RecordType } from '../../model/DailyRecord';
import { resolveShareNoteText, ShareDayKind } from '../../model/ShareModel';
import { DiaryDateFormatter } from '../../utils/DiaryDateFormatter';
import { GraphemeCounter } from '../../utils/GraphemeCounter';

@Component
export struct ShareSingleCard {
  @Link includeNote: boolean;
  @Prop localDate: string = '';
  @Prop recordType: RecordType = RecordType.WORD;
  @Prop content: string = '';
  @Prop note: string = '';
  @Prop fontId: string = 'system_serif_dev';
  @Prop paperId: string = 'warm_paper_dev';
  private readonly dateFormatter: DiaryDateFormatter = new DiaryDateFormatter();
  private readonly graphemeCounter: GraphemeCounter = new GraphemeCounter();

  get paperBackground(): Resource {
    return this.paperId === 'plain_ash_dev' ?
      $r('app.media.share_bg_plain') : $r('app.media.share_bg_warm');
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

  get contentCount(): number {
    return this.graphemeCounter.count(this.content);
  }

  get visibleNote(): string {
    const kind = this.recordType === RecordType.WORD ? ShareDayKind.WORD : ShareDayKind.BLANK;
    return resolveShareNoteText(this.includeNote, kind, this.note);
  }

  build() {
    Stack() {
      Image(this.paperBackground)
        .width(286)
        .height(440)
        .objectFit(ImageFit.Fill)

      Column() {
      Text(this.dateFormatter.compactLabel(this.localDate))
        .fontSize(12)
        .fontFamily('serif')
        .fontWeight(FontWeight.Lighter)
        .fontColor(this.secondaryColor)
        .letterSpacing(2.4)
        .minFontScale(1)
        .maxFontScale(1)
        .margin({ top: 38 })

      Column() {
        if (this.recordType === RecordType.WORD) {
          Stack({ alignContent: Alignment.Center }) {
            if (this.contentCount <= 1) {
              Text(this.content)
                .fontSize(96)
                .fontFamily(this.fontFamily)
                .fontWeight(FontWeight.Normal)
                .fontColor(this.textColor)
                .textAlign(TextAlign.Center)
            } else if (this.contentCount === 2) {
              Text(this.content)
                .fontSize(78)
                .fontFamily(this.fontFamily)
                .fontWeight(FontWeight.Normal)
                .fontColor(this.textColor)
                .letterSpacing(3)
                .textAlign(TextAlign.Center)
            } else if (this.contentCount === 3) {
              Text(this.content)
                .fontSize(62)
                .fontFamily(this.fontFamily)
                .fontWeight(FontWeight.Normal)
                .fontColor(this.textColor)
                .letterSpacing(3)
                .textAlign(TextAlign.Center)
            } else {
              Text(this.content)
                .fontSize(52)
                .fontFamily(this.fontFamily)
                .fontWeight(FontWeight.Normal)
                .fontColor(this.textColor)
                .letterSpacing(3)
                .textAlign(TextAlign.Center)
            }
          }
          .width('100%')
          .height(this.visibleNote.length > 0 ? 224 : 292)
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
          .height(this.visibleNote.length > 0 ? 224 : 292)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }

        if (this.visibleNote.length > 0) {
          Column({ space: 6 }) {
            Row()
              .width(28)
              .height(1)
              .backgroundColor(this.secondaryColor)

            Text(this.visibleNote)
              .width(238)
              .fontSize(12)
              .lineHeight(18)
              .fontFamily(this.fontFamily)
              .fontColor(this.secondaryColor)
              .letterSpacing(0.5)
              .textAlign(TextAlign.Center)
              .maxLines(3)
              .minFontScale(1)
              .maxFontScale(1)
          }
          .height(68)
          .alignItems(HorizontalAlign.Center)
        }
      }
      .width('100%')
      .height(292)
      .alignItems(HorizontalAlign.Center)

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
      .margin({ bottom: 32 })
      .alignItems(VerticalAlign.Center)
      }
      .width(286)
      .height(440)
      .alignItems(HorizontalAlign.Center)
    }
    .width(286)
    .height(440)
    .border({ width: 1, color: this.paperId === 'plain_ash_dev' ? '#E5E5E2' : '#EEE5E1' })
    .borderRadius(2)
  }
}
