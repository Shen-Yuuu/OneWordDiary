import { DiaryIconButton } from '../components/common/DiaryIconButton';
import { PaperBackdrop } from '../components/common/PaperBackdrop';
import { styleForPaper } from '../constants/StyleTokens';

@Component
export struct PrivacyPage {
  @Prop paperId: string = 'warm_paper_dev';
  @State private contentShown: boolean = false;
  private revealTimer: number = -1;
  onBack: () => void = () => {
  };
  onOpenOfficialPolicy: () => void = () => {
  };

  aboutToAppear(): void {
    this.revealTimer = setTimeout(() => {
      this.getUIContext().animateTo({ duration: 300, curve: Curve.EaseOut }, () => {
        this.contentShown = true;
      });
    }, 30);
  }

  aboutToDisappear(): void {
    if (this.revealTimer !== -1) {
      clearTimeout(this.revealTimer);
    }
  }

  @Builder
  private privacyItem(title: string, content: string) {
    Column({ space: 8 }) {
      Text(title)
        .width('100%')
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))

      Text(content)
        .width('100%')
        .fontSize(15)
        .lineHeight(24)
        .fontColor($r('app.color.text_secondary'))
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding({ top: 18, bottom: 18 })
    .border({ width: { bottom: 1 }, color: $r('app.color.divider_subtle') })
  }

  @Builder
  private officialPolicyEntry() {
    Row() {
      Text('查看完整《一字日记隐私政策》')
        .fontSize(16)
        .fontColor($r('app.color.text_primary'))

      Text('›')
        .fontSize(24)
        .fontColor($r('app.color.text_secondary'))
    }
    .width('100%')
    .height(56)
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
    .padding({ left: 16, right: 16 })
    .margin({ top: 24 })
    .borderRadius(12)
    .backgroundColor($r('app.color.surface_primary'))
    .onClick(() => this.onOpenOfficialPolicy())
  }

  build() {
    NavDestination() {
      Stack() {
        PaperBackdrop({ paperId: this.paperId })

        Column() {
          Row() {
            DiaryIconButton({
              icon: $r('app.media.ic_back'),
              accessibilityLabel: '返回设置',
              onTap: () => this.onBack()
            })

            Text('隐私说明')
              .fontSize(22)
              .fontFamily('oneword_wenkai, serif')
              .fontColor($r('app.color.text_primary'))
              .letterSpacing(2.6)

            Row()
              .width($r('app.float.touch_target_min'))
              .height($r('app.float.touch_target_min'))
          }
          .width('100%')
          .height($r('app.float.top_bar_height'))
          .justifyContent(FlexAlign.SpaceBetween)
          .alignItems(VerticalAlign.Center)

          Scroll() {
            Column() {
              this.privacyItem('本机存储', '日记保存在当前设备。')
              this.privacyItem('分享与备份', '仅在你主动操作时生成或读取文件。')
              this.privacyItem('清除数据', '可在设置中清空全部数据。')
              this.officialPolicyEntry()
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Start)
            .alignItems(HorizontalAlign.Start)
            .padding({ top: 18, bottom: 36 })
          }
          .layoutWeight(1)
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
        }
        .width('100%')
        .height('100%')
        .padding({
          top: $r('app.float.immersive_top_content_offset'),
          bottom: $r('app.float.immersive_bottom_content_offset'),
          left: 24,
          right: 24
        })
        .opacity(this.contentShown ? 1 : 0)
        .translate({ y: this.contentShown ? 0 : 14 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(styleForPaper(this.paperId).light.background)
    }
    .hideTitleBar(true)
    .backgroundColor(styleForPaper(this.paperId).light.background)
  }
}
