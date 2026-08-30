import { DiaryIconButton } from '../common/DiaryIconButton';

@Component
export struct InspirationLine {
  @Prop text: string = '';
  @State private fading: boolean = false;
  private fadeTimer: number = -1;
  onRefresh: () => void = () => {
  };

  aboutToDisappear(): void {
    if (this.fadeTimer !== -1) {
      clearTimeout(this.fadeTimer);
    }
  }

  private refreshWithFade(): void {
    if (this.fading) {
      return;
    }
    this.getUIContext().animateTo({ duration: 150, curve: Curve.EaseIn }, () => {
      this.fading = true;
    });
    this.fadeTimer = setTimeout(() => {
      this.onRefresh();
      this.getUIContext().animateTo({ duration: 200, curve: Curve.EaseOut }, () => {
        this.fading = false;
      });
    }, 160);
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Text(this.text)
        .fontSize(16)
        .fontWeight(FontWeight.Lighter)
        .fontColor($r('app.color.text_secondary'))
        .letterSpacing(0.8)
        .maxLines(2)
        .textAlign(TextAlign.Center)
        .width('100%')
        .padding({ left: 52, right: 52 })
        .opacity(this.fading ? 0 : 1)
        .translate({ y: this.fading ? 4 : 0 })

      Row() {
        Blank()

        DiaryIconButton({
          icon: $r('app.media.ic_refresh'),
          accessibilityLabel: '换一句今日灵感',
          onTap: () => this.refreshWithFade()
        })
          .margin({ right: 2 })
      }
      .width('100%')
    }
    .width('100%')
    .height(56)
  }
}
