/**
 * A blocking first-use consent surface. The host decides how to open the
 * hosted policy and how to terminate the application after a refusal.
 */
@Component
export struct PrivacyConsentGate {
  @Prop isLoading: boolean = false;
  @Prop isSaving: boolean = false;
  @Prop errorMessage: string = '';
  onViewFullPolicy: () => void = () => {
  };
  onDeclineAndExit: () => void = () => {
  };
  onAcceptAndContinue: () => void = () => {
  };

  build() {
    Column({ space: 20 }) {
      Text('欢迎使用一字日记')
        .fontSize(28)
        .fontFamily('oneword_wenkai, serif')
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .letterSpacing(2)

      Text('在继续前，请阅读并同意《一字日记隐私政策》。日记默认仅保存在本机，不会上传到服务器。')
        .fontSize(16)
        .lineHeight(25)
        .fontColor($r('app.color.text_secondary'))
        .textAlign(TextAlign.Center)

      if (this.isLoading) {
        Text('正在读取同意状态…')
          .fontSize(14)
          .fontColor($r('app.color.text_tertiary'))
      }

      if (this.errorMessage.length > 0) {
        Text(this.errorMessage)
          .fontSize(14)
          .fontColor($r('app.color.error_danger'))
          .textAlign(TextAlign.Center)
      }

      Button('查看完整隐私政策')
        .width('100%')
        .height(48)
        .fontSize(16)
        .fontColor($r('app.color.text_primary'))
        .backgroundColor(Color.Transparent)
        .border({ width: 1, color: $r('app.color.outline_soft') })
        .borderRadius(24)
        .enabled(!this.isSaving)
        .opacity(this.isSaving ? 0.45 : 1)
        .onClick(() => this.onViewFullPolicy())

      Button(this.isSaving ? '正在保存…' : '同意并继续')
        .width('100%')
        .height(48)
        .fontSize(16)
        .fontColor($r('app.color.on_ink_button'))
        .backgroundColor($r('app.color.ink_button'))
        .borderRadius(24)
        .enabled(!this.isLoading && !this.isSaving)
        .opacity(this.isLoading || this.isSaving ? 0.45 : 1)
        .onClick(() => this.onAcceptAndContinue())

      Button('不同意并退出')
        .width('100%')
        .height(44)
        .fontSize(15)
        .fontColor($r('app.color.text_secondary'))
        .backgroundColor(Color.Transparent)
        .enabled(!this.isSaving)
        .opacity(this.isSaving ? 0.45 : 1)
        .onClick(() => this.onDeclineAndExit())
    }
    .width('100%')
    .padding({ left: 32, right: 32, top: 48, bottom: 40 })
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .backgroundColor($r('app.color.app_background'))
  }
}
