import { DiaryIconButton } from '../components/common/DiaryIconButton';
import { PaperBackdrop } from '../components/common/PaperBackdrop';

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
              Text('你的文字，只属于你。')
                .width('100%')
                .fontSize(27)
                .fontFamily('oneword_wenkai, serif')
                .fontColor($r('app.color.text_primary'))
                .letterSpacing(2)
                .margin({ top: 24, bottom: 18 })

              this.privacyItem('本机保存', '日记默认只保存在当前设备，不需要账号，也不会上传到服务器。')
              this.privacyItem('没有追踪', '应用不申请网络权限，不接入统计、广告或用户画像服务。')
              this.privacyItem('克制的提醒', '每日提醒只显示固定文案，不读取或展示你的日记正文与注解。')
              this.privacyItem('谨慎分享', '分享图片默认不包含注解；分享前始终展示完整预览。')
              this.privacyItem('主动备份', '应用未接入系统备份恢复扩展。只有你主动选择时才会导出或导入；导出的 .oneword 文件未加密，请保存到可信位置。')
              this.officialPolicyEntry()

              Text('一字 1.0 · 离线优先')
                .fontSize(13)
                .fontColor($r('app.color.text_tertiary'))
                .margin({ top: 32, bottom: 44 })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
          }
          .layoutWeight(1)
          .scrollBar(BarState.Off)
        }
        .width('100%')
        .height('100%')
        .padding({ left: 24, right: 24 })
        .opacity(this.contentShown ? 1 : 0)
        .translate({ y: this.contentShown ? 0 : 14 })
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
    .backgroundColor(Color.Transparent)
  }
}
