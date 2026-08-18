import { RecordType } from '../../model/DailyRecord';

@Component
export struct TodayConfirmation {
  @Prop dateText: string = '';
  @Prop draftType: RecordType = RecordType.WORD;
  @Prop content: string = '';
  @Prop note: string = '';
  @Prop isRevision: boolean = false;
  @Prop isBusy: boolean = false;
  @Prop errorMessage: string = '';
  onConfirm: () => void = () => {
  };
  onCancel: () => void = () => {
  };

  get primaryLabel(): string {
    if (this.errorMessage.length > 0) {
      return '重新保存';
    }
    if (this.isRevision) {
      return '确认定稿';
    }
    return this.draftType === RecordType.BLANK ? '确认留白' : '收入长卷';
  }

  build() {
    Column() {
      Blank()

      Column({ space: 18 }) {
        if (this.draftType === RecordType.BLANK) {
          Row()
            .width(9)
            .height(9)
            .border({ width: 1, color: $r('app.color.accent_vermilion') })
            .borderRadius(5)
        } else {
          Row()
            .width(7)
            .height(7)
            .backgroundColor($r('app.color.accent_vermilion'))
            .borderRadius(2)
        }

        Text(this.dateText)
          .fontSize(13)
          .fontWeight(FontWeight.Lighter)
          .fontColor($r('app.color.text_secondary'))
          .letterSpacing(1.6)
      }

      Blank()

      if (this.draftType === RecordType.BLANK) {
        Text('把今天留给空白')
          .fontSize(24)
          .fontFamily('serif')
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .letterSpacing(4)
          .textAlign(TextAlign.Center)
          .accessibilityText('正式留白')

        Text('留白也是今天完整的记录')
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 16 })
      } else {
        Text(this.content)
          .fontSize(84)
          .fontFamily('serif')
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .textAlign(TextAlign.Center)
          .maxLines(1)
          .accessibilityText(`今日正文，${this.content}`)

        if (this.note.length > 0) {
          Text(this.note)
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
            .textAlign(TextAlign.Center)
            .margin({ top: 12 })
            .maxLines(2)
        }
      }

      if (this.isRevision) {
        Text('本次确认后永久定稿')
          .fontSize(13)
          .fontColor($r('app.color.accent_vermilion'))
          .margin({ top: 24 })
          .accessibilityLevel('yes')
      }

      if (this.errorMessage.length > 0) {
        Text(this.errorMessage)
          .fontSize(13)
          .fontColor('#BA1A1A')
          .textAlign(TextAlign.Center)
          .margin({ top: 18 })
          .accessibilityLevel('yes')
      }

      Blank()

      if (this.isBusy) {
        LoadingProgress()
          .width(28)
          .height(28)
          .color($r('app.color.accent_vermilion'))
          .margin({ bottom: 18 })

        Text(this.isRevision ? '正在定稿…' : '正在收入长卷…')
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .margin({ bottom: 20 })
      }

      Button(this.primaryLabel)
        .width('100%')
        .height(52)
        .fontSize(13)
        .fontColor('#FFFFFF')
        .backgroundColor($r('app.color.text_primary'))
        .enabled(!this.isBusy)
        .opacity(this.isBusy ? 0.45 : 1)
        .onClick(() => this.onConfirm())

      Button(this.errorMessage.length > 0 ? '返回修改' : '再想想')
        .width('100%')
        .height(52)
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
        .backgroundColor(Color.Transparent)
        .border({ width: 1, color: $r('app.color.divider_subtle') })
        .enabled(!this.isBusy)
        .margin({ top: 12, bottom: 26 })
        .onClick(() => this.onCancel())
    }
    .width('100%')
    .height('100%')
    .padding({ left: 32, right: 32, top: 20 })
    .backgroundColor($r('app.color.app_background'))
    .alignItems(HorizontalAlign.Center)
    .accessibilityGroup(true)
  }
}
