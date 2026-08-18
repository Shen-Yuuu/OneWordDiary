@Component
export struct AppLoadingPanel {
  build() {
    Column({ space: 16 }) {
      LoadingProgress()
        .width(28)
        .height(28)
        .color($r('app.color.accent_vermilion'))

      Text('正在展开今天…')
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}

@Component
export struct AppErrorPanel {
  @Prop title: string = '暂时未能展开今天';
  @Prop message: string = '';
  onRetry: () => void = () => {
  };

  build() {
    Column({ space: 18 }) {
      Text(this.title)
        .fontSize(22)
        .fontFamily('serif')
        .fontColor($r('app.color.text_primary'))

      Text(this.message)
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .textAlign(TextAlign.Center)

      Button('重试')
        .width(160)
        .height(50)
        .fontSize(13)
        .fontColor('#FFFFFF')
        .backgroundColor($r('app.color.text_primary'))
        .borderRadius(25)
        .onClick(() => this.onRetry())
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding(32)
    .accessibilityGroup(true)
  }
}
