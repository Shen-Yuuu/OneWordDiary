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
        .fontColor(this.isEnabled ? $r('app.color.on_ink_button') : $r('app.color.button_disabled_text'))
        .letterSpacing(0.8)
    }
    .width($r('app.float.primary_button_width'))
    .height($r('app.float.primary_button_height'))
    .backgroundColor(this.isEnabled ? $r('app.color.ink_button') : $r('app.color.button_disabled_background'))
    .borderRadius(26)
    .enabled(true)
    .scale({ x: this.pressed ? 0.96 : 1, y: this.pressed ? 0.96 : 1 })
    .animation({ duration: 160, curve: Curve.EaseOut })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.pressed = true;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.pressed = false;
      }
    })
    .onClick(() => { if (this.isEnabled) { this.onTap(); } })
    .accessibilityText(this.label)
  }
}
