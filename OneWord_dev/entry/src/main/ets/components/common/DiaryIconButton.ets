@Component
export struct DiaryIconButton {
  @Prop icon: Resource = $r('app.media.ic_back');
  @Prop accessibilityLabel: string = '';
  @Prop bordered: boolean = false;
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
    .accessibilityText(this.accessibilityLabel)
    .onClick(() => this.onTap())
  }
}
