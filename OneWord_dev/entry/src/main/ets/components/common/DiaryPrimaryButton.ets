@Component
export struct DiaryPrimaryButton {
  @Prop label: string = '';
  @Prop isEnabled: boolean = true;
  @State private pressed: boolean = false;
  onTap: () => void = () => {
  };

  build() {
    Button() {
      Text(this.label)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.on_ink_button'))
        .letterSpacing(0.8)
    }
    .width($r('app.float.primary_button_width'))
    .height($r('app.float.primary_button_height'))
    .backgroundColor($r('app.color.ink_button'))
    .borderRadius(26)
    .enabled(this.isEnabled)
    .opacity(this.isEnabled ? 1 : 0.24)
    .scale({ x: this.pressed ? 0.96 : 1, y: this.pressed ? 0.96 : 1 })
    .animation({ duration: 160, curve: Curve.EaseOut })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.pressed = true;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.pressed = false;
      }
    })
    .onClick(() => this.onTap())
    .accessibilityText(this.label)
  }
}
