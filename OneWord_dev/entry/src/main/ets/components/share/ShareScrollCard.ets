import { ScrollRecordNode } from '../scroll/ScrollRecordNode';
import { RecordType } from '../../model/DailyRecord';
import { AppLogger } from '../../utils/AppLogger';
import { ScrollDisplayItem, ScrollItemSide } from '../../model/ScrollDisplayItem';
import { ShareDayItem, ShareDayKind } from '../../model/ShareModel';
import { GraphemeCounter } from '../../utils/GraphemeCounter';
import { ScrollLayoutMetrics } from '../../constants/ScrollLayoutMetrics';
import { styleForPaper } from '../../constants/StyleTokens';

@Component
export struct ShareScrollCard {
  @Prop days: ShareDayItem[] = [];
  @Prop paperId: string = 'warm_paper_dev';
  private readonly graphemeCounter: GraphemeCounter = new GraphemeCounter();

  textColor(): string {
    return styleForPaper(this.paperId).light.textPrimary;
  }

  secondaryColor(): string {
    return styleForPaper(this.paperId).light.textSecondary;
  }

  accentColor(): string {
    return styleForPaper(this.paperId).light.accent;
  }

  aboutToAppear(): void {
    AppLogger.info(`style.share_scroll_card paperId=${this.paperId}`);
  }

  private sideFor(item: ShareDayItem, index: number): ScrollItemSide {
    if (item.kind !== ShareDayKind.WORD) {
      return ScrollItemSide.CENTER;
    }
    let previousWordCount = 0;
    for (let currentIndex = 0; currentIndex < index; currentIndex += 1) {
      if (this.days[currentIndex].kind === ShareDayKind.WORD) {
        previousWordCount += 1;
      }
    }
    return previousWordCount % 2 === 0 ? ScrollItemSide.LEFT : ScrollItemSide.RIGHT;
  }

  private displayItem(item: ShareDayItem, index: number): ScrollDisplayItem {
    const recordType = item.kind === ShareDayKind.WORD ? RecordType.WORD : RecordType.BLANK;
    return new ScrollDisplayItem(
      item.localDate,
      item.monthLabel,
      item.monthLabel,
      item.showMonthHeader,
      item.dateLabel,
      item.weekdayLabel,
      recordType,
      item.content,
      this.graphemeCounter.count(item.content),
      item.fontId,
      this.paperId,
      this.sideFor(item, index),
      '',
      false,
      item.kind === ShareDayKind.MISSING
    );
  }

  timelineHeight(): number {
    let height = 0;
    for (const item of this.days) {
      height += ScrollLayoutMetrics.totalHeight(
        item.kind === ShareDayKind.MISSING,
        false,
        item.showMonthHeader
      );
    }
    return height;
  }

  cardHeight(): number {
    return this.timelineHeight() + ScrollLayoutMetrics.SHARE_TOP_SPACING +
      ScrollLayoutMetrics.SHARE_FOOTER_HEIGHT;
  }

  build() {
    Stack() {
      Column() {
      Column() {
        ForEach(this.days, (item: ShareDayItem, index: number) => {
          ScrollRecordNode({
            item: this.displayItem(item, index),
            isInteractive: false
          })
        }, (item: ShareDayItem): string => item.localDate)
      }
      .width('100%')
      .margin({ top: ScrollLayoutMetrics.SHARE_TOP_SPACING })

      Column({ space: 10 }) {
        Text('卷尾')
          .fontSize(13)
          .fontFamily('oneword_wenkai, serif')
          .fontColor(this.secondaryColor())
          .letterSpacing(2)

        Row({ space: 8 }) {
          Stack({ alignContent: Alignment.Center }) {
            Row()
              .width(19)
              .height(19)
              .backgroundColor(this.accentColor())
              .borderRadius(2)

            Text('字')
              .fontSize(9)
              .fontFamily('oneword_wenkai, serif')
              .fontColor('#FFFFFF')
          }

          Text('一字日记')
            .fontSize(11)
            .fontFamily('oneword_wenkai, serif')
            .fontColor(this.textColor())
            .letterSpacing(2.4)
        }
        .alignItems(VerticalAlign.Center)
      }
      .height(ScrollLayoutMetrics.SHARE_FOOTER_HEIGHT)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      }
      .width(286)
      .height(this.cardHeight())
      .alignItems(HorizontalAlign.Center)
    }
    .width(286)
    .height(this.cardHeight())
    .backgroundColor(styleForPaper(this.paperId).light.background)
    .border({ width: 1, color: styleForPaper(this.paperId).light.divider })
    .borderRadius(2)
  }
}
