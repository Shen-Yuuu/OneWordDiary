import { styleForPaper } from '../../../constants/StyleTokens';
import { fontFamilyForId } from '../../../constants/FontCatalog';

let storage = new LocalStorage();

interface CardFontAsset {
  family: string;
  source: string;
}

const CARD_FONTS: CardFontAsset[] = [
  { family: 'oneword_wenkai', source: 'fonts/OneWordKai-Regular.ttf' },
  { family: 'oneword_wenkai_medium', source: 'fonts/OneWordKai-Medium.ttf' },
  { family: 'oneword_smiley_sans', source: 'fonts/SmileySans-Oblique.ttf' },
  { family: 'oneword_dymon_handwriting', source: 'fonts/Dymon-ShouXieTi.otf' },
  { family: 'oneword_slide_youran', source: 'fonts/slideyouran-Regular.ttf' },
  { family: 'oneword_mingchao', source: 'fonts/mingchao.ttf' },
  { family: 'oneword_yunfeng_feiyun', source: 'fonts/YunfengFeiyun.ttf' }
];

@Entry(storage)
@Component
struct WordCardCard {
  @LocalStorageProp('content') content: string = '';
  @LocalStorageProp('date') date: string = '';
  @LocalStorageProp('paperColor') paperColor: string = '#FDF8F7';
  @LocalStorageProp('inkColor') inkColor: string = '#282622';
  @LocalStorageProp('accentColor') accentColor: string = '#A65C4D';
  @LocalStorageProp('fontFamily') fontFamily: string = 'oneword_wenkai, serif';

  aboutToAppear(): void {
    // 卡片渲染环境独立于 App 进程：App 内注册的字体对卡片不可见，
    // 需在卡片自身环境注册后，fontFamily 才能命中（失败则回退系统字体，不影响展示）
    const fontManager = this.getUIContext().getFont();
    for (const asset of CARD_FONTS) {
      try {
        fontManager.registerFont({ familyName: asset.family, familySrc: $rawfile(asset.source) });
      } catch (error) {
        // 单个字体注册失败不影响其余字体与兜底字体
      }
    }
  }

  charFontSize(): number {
    const len = this.content.length;
    if (len <= 1) {
      return 56;
    }
    if (len === 2) {
      return 42;
    }
    if (len === 3) {
      return 34;
    }
    return 28;
  }

  build() {
    Stack({ alignContent: Alignment.TopEnd }) {
      Column() {
        Text(this.date)
          .fontSize(12)
          .fontFamily(this.fontFamily)
          .fontColor(this.inkColor)
          .opacity(0.6)
          .letterSpacing(1)

        Blank()

        if (this.content.length > 0) {
          Text(this.content)
            .fontSize(this.charFontSize())
            .fontFamily(this.fontFamily)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.inkColor)
            .textAlign(TextAlign.Center)
            .maxLines(1)
        } else {
          Text('一字')
            .fontSize(40)
            .fontWeight(FontWeight.Lighter)
            .fontColor(this.inkColor)
            .opacity(0.4)
        }

        Blank()
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Column() {
        Text('已')
          .fontSize(10)
          .fontFamily(this.fontFamily)
          .fontColor('#FFFFFF')
          .backgroundColor(this.accentColor)
          .width(20)
          .height(20)
          .textAlign(TextAlign.Center)
          .borderRadius(2)
      }
      .margin(8)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.paperColor)
  }
}
