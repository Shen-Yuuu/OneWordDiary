import { RecordType } from '../../model/DailyRecord';
import { DiaryBackground } from '../common/DiaryBackground';
import { AppLogger } from '../../utils/AppLogger';
import { DiaryDateFormatter } from '../../utils/DiaryDateFormatter';
import { GraphemeCounter } from '../../utils/GraphemeCounter';
import { styleForPaper } from '../../constants/StyleTokens';

@Component
export struct ShareSingleCard {
  @Prop localDate: string = '';
  @Prop recordType: RecordType = RecordType.WORD;
  @Prop content: string = '';
  @Prop fontId: string = 'system_serif_dev';
  @Prop paperId: string = 'warm_paper_dev';
  @Prop backgroundImageUri: string = '';
  @Prop showBackgroundImage: boolean = true;
  @Prop backgroundReloadKey: number = 0;
  onBackgroundReady: (imageUri: string, reloadKey: number) => void =
    (imageUri: string, reloadKey: number) => {
    };
  onBackgroundFailed: (imageUri: string, reloadKey: number) => void =
    (imageUri: string, reloadKey: number) => {
    };
  private readonly dateFormatter: DiaryDateFormatter = new DiaryDateFormatter();
  private readonly graphemeCounter: GraphemeCounter = new GraphemeCounter();

  paperBackground(): Resource {
    return this.paperId === 'plain_ash_dev' ?
      $r('app.media.share_bg_plain') : $r('app.media.share_bg_warm');
  }

  textColor(): string {
    return styleForPaper(this.paperId).light.textPrimary;
  }

  secondaryColor(): string {
    return styleForPaper(this.paperId).light.textSecondary;
  }

  accentColor(): string {
    return styleForPaper(this.paperId).light.accent;
  }

  recordFontFamily(): string {
    return 'oneword_wenkai, serif';
  }

  aboutToAppear(): void {
    AppLogger.info(`style.share_card paperId=${this.paperId} fontId=${this.fontId}`);
  }

  contentCount(): number {
    return this.graphemeCounter.count(this.content);
  }

  build() {
    Stack() {
      Image(this.paperBackground())
        .width(286)
        .height(440)
        .objectFit(ImageFit.Fill)

      if (this.showBackgroundImage) {
        DiaryBackground({
          imageUri: this.backgroundImageUri,
          paperId: this.paperId,
          scrimOpacity: 0.74,
          fixedLightScrim: true,
          reloadKey: this.backgroundReloadKey,
          onReady: (imageUri: string, reloadKey: number) => this.onBackgroundReady(imageUri, reloadKey),
          onFailed: (imageUri: string, reloadKey: number) => this.onBackgroundFailed(imageUri, reloadKey)
        })
          .width(286)
          .height(440)
      }

      Column() {
      Text(this.dateFormatter.compactLabel(this.localDate))
        .fontSize(12)
        .fontFamily('oneword_wenkai, serif')
        .fontWeight(FontWeight.Lighter)
        .fontColor(this.secondaryColor())
        .letterSpacing(2.4)
        .minFontScale(1)
        .maxFontScale(1)
        .margin({ top: 38 })

      Column() {
        if (this.recordType === RecordType.WORD) {
          Stack({ alignContent: Alignment.Center }) {
            if (this.contentCount() <= 1) {
              Text(this.content)
                .fontSize(96)
                .fontFamily(this.recordFontFamily())
                .fontWeight(FontWeight.Normal)
                .fontColor(this.textColor())
                .textAlign(TextAlign.Center)
            } else if (this.contentCount() === 2) {
              Text(this.content)
                .fontSize(78)
                .fontFamily(this.recordFontFamily())
                .fontWeight(FontWeight.Normal)
                .fontColor(this.textColor())
                .letterSpacing(3)
                .textAlign(TextAlign.Center)
            } else if (this.contentCount() === 3) {
              Text(this.content)
                .fontSize(62)
                .fontFamily(this.recordFontFamily())
                .fontWeight(FontWeight.Normal)
                .fontColor(this.textColor())
                .letterSpacing(3)
                .textAlign(TextAlign.Center)
            } else {
              Text(this.content)
                .fontSize(52)
                .fontFamily(this.recordFontFamily())
                .fontWeight(FontWeight.Normal)
                .fontColor(this.textColor())
                .letterSpacing(3)
                .textAlign(TextAlign.Center)
            }
          }
          .width('100%')
          .height(292)
        } else {
          Column({ space: 14 }) {
            Stack({ alignContent: Alignment.Center }) {
              Row()
                .width(70)
                .height(70)
                .border({ width: 1, color: this.secondaryColor() })
                .borderRadius(35)

              Row()
                .width(5)
                .height(5)
                .backgroundColor(this.accentColor())
                .borderRadius(2.5)
            }

            Text('留白')
              .fontSize(14)
              .fontFamily(this.recordFontFamily())
              .fontColor(this.secondaryColor())
              .letterSpacing(4)
              .minFontScale(1)
              .maxFontScale(1)
          }
          .height(292)
          .justifyContent(FlexAlign.Center)
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
            .backgroundColor(this.accentColor())
            .borderRadius(2)

          Text('字')
            .fontSize(10)
            .fontFamily('oneword_wenkai, serif')
            .fontColor('#FFFFFF')
            .minFontScale(1)
            .maxFontScale(1)
        }

        Text('一字日记')
          .fontSize(13)
          .fontFamily(this.recordFontFamily())
          .fontColor(this.textColor())
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
    .backgroundColor(styleForPaper(this.paperId).light.background)
    .border({ width: 1, color: styleForPaper(this.paperId).light.divider })
    .borderRadius(2)
  }
}
