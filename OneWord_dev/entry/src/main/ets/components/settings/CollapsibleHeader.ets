@Component
export struct CollapsibleHeader {
  @Prop title: string = '';
  @Prop value: string = '';
  @Prop expanded: boolean = false;
  onToggle: () => void = () => {
  };

  build() {
    Row() {
      Text(this.title)
        .fontSize(17)
        .fontColor($r('app.color.text_primary'))

      Blank()

      if (this.value.length > 0) {
        Text(this.value)
          .fontSize(15)
          .fontColor($r('app.color.text_secondary'))
      }

      Text(this.expanded ? '⌄' : '›')
        .fontSize(20)
        .fontColor($r('app.color.text_tertiary'))
        .translate({ y: this.expanded ? -3 : 0 })
        .margin({ left: 10 })
    }
    .width('100%')
    .height(58)
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
    .onClick(() => this.onToggle())
    .accessibilityText(`${this.title}，${this.expanded ? '已展开' : '已收起'}，点按${this.expanded ? '收起' : '展开'}`)
  }
}
