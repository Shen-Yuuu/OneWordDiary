@Component
export struct DiaryIconButton {
  @Prop icon: Resource = $r('app.media.ic_back');
  @Prop accessibilityLabel: string = '';
  @Prop bordered: boolean = false;
  @State private pressed: boolean = false;
  onTap: () => void = () => {
  };

  build() {
    Button({ type: ButtonType.Circle, stateEffect: true }) {
      Image(this.icon)
        .width(21)
        .height(21)
        .objectFit(ImageFit.Contain)
        .accessibilityLevel('no')
    }
    .width($r('app.float.touch_target_min'))
    .height($r('app.float.touch_target_min'))
    .backgroundColor(this.bordered ? $r('app.color.surface_primary') : Color.Transparent)
    .border({
      width: this.bordered ? 1 : 0,
      color: $r('app.color.outline_soft')
    })
    .scale({ x: this.pressed ? 0.92 : 1, y: this.pressed ? 0.92 : 1 })
    .opacity(this.pressed ? 0.7 : 1)
    .animation({ duration: 120, curve: Curve.EaseOut })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.pressed = true;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.pressed = false;
      }
    })
    .accessibilityText(this.accessibilityLabel)
    .onClick(() => this.onTap())
  }
}
