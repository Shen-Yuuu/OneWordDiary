@Component
export struct DiaryPrimaryButton {
  @Prop label: string = '';
  @Prop isEnabled: boolean = true;
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
    .onClick(() => this.onTap())
    .accessibilityText(this.label)
  }
}
