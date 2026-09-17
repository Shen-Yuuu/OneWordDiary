import { GraphemeCounter } from '../../utils/GraphemeCounter';

let storage = new LocalStorage();

@Entry(storage)
@Component
struct WordCardCard {
  @LocalStorageProp('imgSrc') imgSrc: string = '';
  @LocalStorageProp('content') content: string = '';
  @LocalStorageProp('date') date: string = '';
  @LocalStorageProp('paperColor') paperColor: string = '#FDF8F7';
  @LocalStorageProp('inkColor') inkColor: string = '#282622';
  @LocalStorageProp('accentColor') accentColor: string = '#A65C4D';
  private readonly graphemeCounter: GraphemeCounter = new GraphemeCounter();

  charFontSize(): number {
    const len = this.graphemeCounter.count(this.content);
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
    Stack() {
      if (this.imgSrc.length > 0) {
        // 位图卡片：App 内以真字体渲染的同款快照，通过 memory:// 协议注入
        Image('memory://' + this.imgSrc)
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Fill)
      } else {
        Stack({ alignContent: Alignment.TopEnd }) {
          Column() {
            Blank()

            if (this.content.length > 0) {
              Text(this.content)
                .fontSize(this.charFontSize())
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

            Text(this.date)
              .fontSize(12)
              .fontColor(this.inkColor)
              .opacity(0.6)
              .letterSpacing(1)
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .padding({ top: 18, bottom: 10 })

          Column() {
            Text('已')
              .fontSize(10)
              .fontColor('#FFFFFF')
              .backgroundColor(this.accentColor)
              .width(20)
              .height(20)
              .textAlign(TextAlign.Center)
              .borderRadius(2)
          }
          .margin({ top: 16, right: 16 })
        }
        .width('100%')
        .height('100%')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.paperColor)
    .onClick(() => {
      // 点击卡片拉起 App 主页
      postCardAction(this, {
        'action': 'router',
        'abilityName': 'EntryAbility',
        'params': { 'from': 'widget' }
      });
    })
  }
}
