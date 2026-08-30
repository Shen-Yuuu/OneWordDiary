import { curves } from '@kit.ArkUI';

/**
 * 朱红「已」印章：先“盖下”（大倍缩落 + 回正 + 显影），落定后进入极缓慢的呼吸循环。
 * 盖章与呼吸分两层容器，避免同一属性被两段动画争用。
 */
@Component
export struct InkSeal {
  @Prop delay: number = 0;
  @State private stamped: boolean = false;
  @State private breathing: boolean = false;
  private stampTimer: number = -1;
  private breathTimer: number = -1;

  aboutToAppear(): void {
    this.stampTimer = setTimeout(() => {
      this.getUIContext().animateTo({ curve: curves.springMotion(0.5, 0.8) }, () => {
        this.stamped = true;
      });
      this.breathTimer = setTimeout(() => {
        this.getUIContext().animateTo({
          duration: 1300,
          iterations: -1,
          playMode: PlayMode.Alternate,
          curve: Curve.EaseInOut
        }, () => {
          this.breathing = true;
        });
      }, 420);
    }, this.delay);
  }

  aboutToDisappear(): void {
    if (this.stampTimer !== -1) {
      clearTimeout(this.stampTimer);
    }
    if (this.breathTimer !== -1) {
      clearTimeout(this.breathTimer);
    }
  }

  build() {
    Stack() {
      Text('已')
        .width(36)
        .height(36)
        .fontSize(18)
        .fontFamily('oneword_wenkai_medium, serif')
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .backgroundColor($r('app.color.accent_vermilion'))
        .textAlign(TextAlign.Center)
        .borderRadius(3)
        .scale({ x: this.breathing ? 1.12 : 1, y: this.breathing ? 1.12 : 1 })
    }
    .scale({ x: this.stamped ? 1 : 1.45, y: this.stamped ? 1 : 1.45 })
    .rotate({ angle: this.stamped ? 0 : -12 })
    .opacity(this.stamped ? 1 : 0)
  }
}
