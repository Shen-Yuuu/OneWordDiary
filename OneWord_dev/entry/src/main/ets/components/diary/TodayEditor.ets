import { InspirationLine } from './InspirationLine';

@Component
export struct TodayEditor {
  @Prop content: string = '';
  @Prop note: string = '';
  @Prop contentCount: number = 0;
  @Prop noteCount: number = 0;
  @Prop recordCount: number = 0;
  @Prop contentError: string = '';
  @Prop noteError: string = '';
  @Prop noteExpanded: boolean = false;
  @Prop canConfirm: boolean = false;
  @Prop isRevision: boolean = false;
  @Prop inspiration: string = '';
  onContentChange: (value: string) => void = (value: string) => {
  };
  onNoteChange: (value: string) => void = (value: string) => {
  };
  onToggleNote: () => void = () => {
  };
  onRefreshInspiration: () => void = () => {
  };
  onConfirmWord: () => void = () => {
  };
  onConfirmBlank: () => void = () => {
  };
  onCancelRevision: () => void = () => {
  };

  build() {
    Column() {
      InspirationLine({
        text: this.inspiration,
        onRefresh: () => this.onRefreshInspiration()
      })
        .margin({ top: 12, bottom: 22 })

      TextInput({ text: this.content, placeholder: '一至四字' })
        .width('100%')
        .height(128)
        .fontSize(72)
        .fontWeight(FontWeight.Medium)
        .fontFamily('serif')
        .fontColor($r('app.color.text_primary'))
        .placeholderColor($r('app.color.divider_subtle'))
        .placeholderFont({ size: 22, weight: FontWeight.Lighter })
        .textAlign(TextAlign.Center)
        .caretColor($r('app.color.accent_vermilion'))
        .backgroundColor(Color.Transparent)
        .border({ width: 0 })
        .accessibilityText('今日正文，一至四个字')
        .onChange((value: string) => this.onContentChange(value))

      Text(`${this.contentCount} / 4`)
        .fontSize(11)
        .fontColor(this.contentError.length > 0 ? '#BA1A1A' : $r('app.color.text_secondary'))
        .letterSpacing(1)
        .margin({ top: 6 })

      if (this.contentError.length > 0) {
        Text(this.contentError)
          .fontSize(12)
          .fontColor('#BA1A1A')
          .margin({ top: 6 })
          .accessibilityLevel('yes')
      }

      Button(this.noteExpanded ? '收起注解' : '添加一句注解')
        .height($r('app.float.touch_target_min'))
        .fontSize(12)
        .fontColor($r('app.color.text_secondary'))
        .backgroundColor(Color.Transparent)
        .margin({ top: 16 })
        .onClick(() => this.onToggleNote())

      if (this.noteExpanded) {
        Column({ space: 7 }) {
          TextArea({ text: this.note, placeholder: '为今天留一句注脚（可选）' })
            .width('100%')
            .height(82)
            .fontSize(15)
            .fontColor($r('app.color.text_primary'))
            .placeholderColor($r('app.color.text_secondary'))
            .textAlign(TextAlign.Center)
            .caretColor($r('app.color.accent_vermilion'))
            .backgroundColor(Color.Transparent)
            .border({ width: { bottom: 1 }, color: $r('app.color.divider_subtle') })
            .accessibilityText('今日注解，最多三十个字，不能换行')
            .onChange((value: string) => this.onNoteChange(value))

          Text(`${this.noteCount} / 30`)
            .fontSize(10)
            .fontColor(this.noteError.length > 0 ? '#BA1A1A' : $r('app.color.text_secondary'))
            .alignSelf(ItemAlign.End)

          if (this.noteError.length > 0) {
            Text(this.noteError)
              .fontSize(12)
              .fontColor('#BA1A1A')
              .accessibilityLevel('yes')
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16 })
      }

      Row({ space: 12 }) {
        Button('留白')
          .layoutWeight(1)
          .height(50)
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
          .backgroundColor(Color.Transparent)
          .border({ width: 1, color: $r('app.color.divider_subtle') })
          .borderRadius(25)
          .accessibilityText('把今天留给空白')
          .onClick(() => this.onConfirmBlank())

        Button(this.isRevision ? '继续确认' : '落字')
          .layoutWeight(1)
          .height(50)
          .fontSize(13)
          .fontColor('#FFFFFF')
          .backgroundColor($r('app.color.text_primary'))
          .borderRadius(25)
          .enabled(this.canConfirm)
          .opacity(this.canConfirm ? 1 : 0.38)
          .onClick(() => this.onConfirmWord())
      }
      .width('100%')
      .margin({ top: 26 })

      if (this.isRevision) {
        Button('取消修订')
          .height($r('app.float.touch_target_min'))
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .backgroundColor(Color.Transparent)
          .margin({ top: 8 })
          .onClick(() => this.onCancelRevision())
      }

      Text(`已留下 ${this.recordCount} 天`)
        .fontSize(11)
        .fontColor($r('app.color.text_secondary'))
        .letterSpacing(1.2)
        .margin({ top: 18, bottom: 22 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }
}
