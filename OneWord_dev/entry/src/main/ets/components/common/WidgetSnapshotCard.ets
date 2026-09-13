import { snapshotAndPushWidget } from '../../utils/WidgetSync';
import { AppServiceContainer } from '../../service/AppServiceContainer';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'WidgetSnapshotCard';

/**
 * 隐藏的桌面卡片快照组件：与卡片同布局，用 App 内已注册的真字体渲染。
 * widgetCard* AppStorage 快照变化后防抖 600ms，把自身渲染成位图推送给所有卡片。
 * 由 Index 页挂在屏幕外，不参与交互与可见布局。
 */
@Component
export struct WidgetSnapshotCard {
  @StorageProp('widgetCardContent') @Watch('onSnapshotSourceChanged') content: string = '';
  @StorageProp('widgetCardDate') @Watch('onSnapshotSourceChanged') date: string = '';
  @StorageProp('widgetCardPaperColor') @Watch('onSnapshotSourceChanged') paperColor: string = '#FDF8F7';
  @StorageProp('widgetCardInkColor') @Watch('onSnapshotSourceChanged') inkColor: string = '#282622';
  @StorageProp('widgetCardAccentColor') @Watch('onSnapshotSourceChanged') accentColor: string = '#A65C4D';
  @StorageProp('widgetCardFontFamily') @Watch('onSnapshotSourceChanged') fontFamily: string = 'oneword_wenkai, serif';
  private snapTimer: number = -1;

  aboutToAppear(): void {
    // 冷启动竞态兜底：widgetCard* 可能在本组件创建前已写入（初始赋值不触发 @Watch），
    // 挂载后延迟补一次快照，保证仅打开 App 也能刷新卡片位图。
    this.snapTimer = setTimeout(() => {
      this.snapTimer = -1;
      this.takeSnapshot();
    }, 1200);
  }

  aboutToDisappear(): void {
    if (this.snapTimer !== -1) {
      clearTimeout(this.snapTimer);
      this.snapTimer = -1;
    }
  }

  onSnapshotSourceChanged(): void {
    if (this.snapTimer !== -1) {
      clearTimeout(this.snapTimer);
    }
    this.snapTimer = setTimeout(() => {
      this.snapTimer = -1;
      this.takeSnapshot();
    }, 600);
  }

  private takeSnapshot(): void {
    snapshotAndPushWidget(AppServiceContainer.getAbilityContext(), this.getUIContext(), 'widget_snapshot_card')
      .catch((error: Error) => {
        hilog.warn(0, TAG, `widget snapshot failed: ${error.message}`);
      });
  }

  private charFontSize(): number {
    const len: number = this.content.length;
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
            .fontFamily(this.fontFamily)
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
      .padding({ top: 23, bottom: 10 })

      Column() {
        Text('已')
          .fontSize(10)
          .fontColor('#FFFFFF')
          .fontFamily(this.fontFamily)
          .backgroundColor(this.accentColor)
          .width(20)
          .height(20)
          .textAlign(TextAlign.Center)
          .borderRadius(2)
      }
      .margin({ top: 16, right: 16 })
    }
    .width(148)
    .height(148)
    .backgroundColor(this.paperColor)
    .id('widget_snapshot_card')
  }
}
