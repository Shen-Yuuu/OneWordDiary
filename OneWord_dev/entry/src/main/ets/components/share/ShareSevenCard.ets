import { ShareDayItem } from '../../model/ShareModel';
import { ShareSevenDayRow } from './ShareSevenDayRow';

@Component
export struct ShareSevenCard {
  @Prop days: ShareDayItem[] = [];
  @Prop fontId: string = 'system_serif_dev';
  @Prop paperId: string = 'warm_paper_dev';

  get paperColor(): string {
    return this.paperId === 'plain_ash_dev' ? '#FFFFFF' : '#FFFCFB';
  }

  get textColor(): string {
    return this.paperId === 'plain_ash_dev' ? '#242424' : '#282622';
  }

  get secondaryColor(): string {
    return this.paperId === 'plain_ash_dev' ? '#777775' : '#8C8783';
  }

  get lineColor(): string {
    return this.paperId === 'plain_ash_dev' ? '#DDDCD8' : '#E5DCD7';
  }

  get accentColor(): string {
    return this.paperId === 'plain_ash_dev' ? '#626260' : '#A65C4D';
  }

  get fontFamily(): string {
    return this.fontId === 'system_sans_dev' ? 'sans-serif' : 'serif';
  }

  build() {
    Column() {
      Text('RECENT 7 DAYS')
        .fontSize(10)
        .fontFamily('sans-serif')
        .fontColor(this.secondaryColor)
        .letterSpacing(2.2)
        .minFontScale(1)
        .maxFontScale(1)
        .margin({ top: 30 })

      Row()
        .width(18)
        .height(1)
        .backgroundColor(this.lineColor)
        .margin({ top: 10, bottom: 14 })

      Stack({ alignContent: Alignment.Center }) {
        Row()
          .width(1)
          .height(272)
          .backgroundColor(this.lineColor)

        Column() {
          ForEach(this.days, (item: ShareDayItem, index: number) => {
            ShareSevenDayRow({
              item: item,
              index: index,
              fontId: this.fontId,
              paperId: this.paperId
            })
          }, (item: ShareDayItem): string => item.localDate)
        }
        .width('100%')
      }
      .width('100%')
      .height(280)

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
      .layoutWeight(1)
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

