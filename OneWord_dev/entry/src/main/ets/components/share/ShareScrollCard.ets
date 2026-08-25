import { ShareDayItem, ShareDayKind } from '../../model/ShareModel';
import { ShareScrollDayNode } from './ShareScrollDayNode';

@Component
export struct ShareScrollCard {
  @Prop days: ShareDayItem[] = [];
  @Prop fontId: string = 'system_serif_dev';
  @Prop paperId: string = 'warm_paper_dev';
  @Prop includeNote: boolean = false;

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

  get timelineHeight(): number {
    let height = 0;
    for (const item of this.days) {
      if (item.showMonthHeader) {
        height += 66;
      }
      if (item.kind === ShareDayKind.MISSING) {
        height += 82;
      } else {
        height += this.includeNote ? 156 : 126;
      }
    }
    return height;
  }

  get cardHeight(): number {
    return this.timelineHeight + 116;
  }

  build() {
    Column() {
      Column() {
        ForEach(this.days, (item: ShareDayItem, index: number) => {
          ShareScrollDayNode({
            item: item,
            index: index,
            fontId: this.fontId,
            paperId: this.paperId,
            includeNote: this.includeNote
          })
        }, (item: ShareDayItem): string => item.localDate)
      }
      .width('100%')
      .margin({ top: 16 })

      Column({ space: 16 }) {
        Text('卷尾')
          .fontSize(13)
          .fontFamily(this.fontFamily)
          .fontColor(this.secondaryColor)
          .letterSpacing(2)

        Row({ space: 8 }) {
          Stack({ alignContent: Alignment.Center }) {
            Row()
              .width(19)
              .height(19)
              .backgroundColor(this.accentColor)
              .borderRadius(2)

            Text('字')
              .fontSize(9)
              .fontFamily('serif')
              .fontColor('#FFFFFF')
              .minFontScale(1)
              .maxFontScale(1)
          }

          Text('一字日记')
            .fontSize(11)
            .fontFamily(this.fontFamily)
            .fontColor(this.textColor)
            .letterSpacing(2.4)
            .minFontScale(1)
            .maxFontScale(1)
        }
        .alignItems(VerticalAlign.Center)
      }
      .height(100)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .width(286)
    .height(this.cardHeight)
    .backgroundColor(this.paperColor)
    .border({ width: 1, color: this.paperId === 'plain_ash_dev' ? '#E5E5E2' : '#EEE5E1' })
    .borderRadius(2)
    .alignItems(HorizontalAlign.Center)
  }
}
