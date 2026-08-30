
@Component
export struct AppLoadingPanel {
  build() {
    Column({ space: 16 }) {
      Stack({ alignContent: Alignment.Center }) {
        LoadingProgress()
          .width(30)
          .height(30)
          .color($r('app.color.accent_vermilion'))

        Row()
          .width(4)
          .height(4)
          .backgroundColor($r('app.color.paper_warm'))
          .borderRadius(2)
      }

      Text('正在展开今天…')
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
        .letterSpacing(1.2)
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
      Stack({ alignContent: Alignment.Center }) {
        Row()
          .width(56)
          .height(56)
          .border({ width: 1, color: $r('app.color.outline_soft') })
          .borderRadius(28)

        Row()
          .width(6)
          .height(6)
          .backgroundColor($r('app.color.accent_vermilion'))
          .borderRadius(2)
      }

      Text(this.title)
        .fontSize(24)
        .fontFamily('oneword_wenkai, serif')
        .fontColor($r('app.color.text_primary'))
        .letterSpacing(2)

      Text(this.message)
        .fontSize(15)
        .fontColor($r('app.color.text_secondary'))
        .textAlign(TextAlign.Center)

      Button('重试')
        .width($r('app.float.primary_button_width'))
        .height($r('app.float.primary_button_height'))
        .fontSize(14)
        .fontColor($r('app.color.on_ink_button'))
        .backgroundColor($r('app.color.ink_button'))
        .borderRadius(26)
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
