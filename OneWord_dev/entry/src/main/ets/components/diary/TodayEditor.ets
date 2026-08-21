import { InspirationLine } from './InspirationLine';
import { DiaryPrimaryButton } from '../common/DiaryPrimaryButton';

@Component
export struct TodayEditor {
  @Prop content: string = '';
  @Prop note: string = '';
  @Prop contentCount: number = 0;
  @Prop noteCount: number = 0;
  @Prop recordCount: number = 0;
  @Prop contentError: string = '';
  @Prop noteError: string = '';
  @Prop canConfirm: boolean = false;
  @Prop isRevision: boolean = false;
  @Prop inspiration: string = '';
  onContentChange: (value: string) => void = (value: string) => {
  };
  onNoteChange: (value: string) => void = (value: string) => {
  };
  onRefreshInspiration: () => void = () => {
  };
  onConfirmWord: () => void = () => {
  };
  onConfirmBlank: () => void = () => {
  };
  onCancelRevision: () => void = () => {
  };

  get contentFontSize(): number {
    if (this.contentCount <= 1) {
      return 108;
    }
    if (this.contentCount === 2) {
      return 82;
    }
    return this.contentCount === 3 ? 66 : 54;
  }

  build() {
    Column() {
      InspirationLine({
        text: this.inspiration,
        onRefresh: () => this.onRefreshInspiration()
      })
        .margin({ top: 10, bottom: 0 })

      Column({ space: 4 }) {
        TextInput({ text: this.content, placeholder: '一至四字' })
          .width('100%')
          .height(140)
          .fontSize(this.contentFontSize)
          .fontWeight(FontWeight.Medium)
          .fontFamily('serif')
          .fontColor($r('app.color.text_primary'))
          .placeholderColor($r('app.color.outline_soft'))
          .placeholderFont({ size: 28, weight: FontWeight.Lighter })
          .textAlign(TextAlign.Center)
          .caretColor($r('app.color.accent_vermilion'))
          .backgroundColor(Color.Transparent)
          .border({ width: 0 })
          .accessibilityText('今日正文，一至四个字')
          .onChange((value: string) => this.onContentChange(value))

        Text(`${this.contentCount} / 4`)
          .fontSize(13)
          .fontColor(this.contentError.length > 0 ? '#BA1A1A' : $r('app.color.text_tertiary'))
          .letterSpacing(1.4)

        if (this.contentError.length > 0) {
          Text(this.contentError)
            .fontSize(13)
            .fontColor('#BA1A1A')
            .textAlign(TextAlign.Center)
            .accessibilityLevel('yes')
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)

      Column({ space: 4 }) {
        Row() {
          Text('备注（可选）')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))

          Blank()

          Text(`${this.noteCount} / 30`)
            .fontSize(13)
            .fontColor(this.noteError.length > 0 ? '#BA1A1A' : $r('app.color.text_tertiary'))
        }
        .width('100%')

        TextInput({ text: this.note, placeholder: '为今天留一句注脚' })
          .width('100%')
          .height(48)
          .fontSize(17)
          .fontColor($r('app.color.text_primary'))
          .placeholderColor($r('app.color.text_tertiary'))
          .textAlign(TextAlign.Start)
          .caretColor($r('app.color.accent_vermilion'))
          .backgroundColor(Color.Transparent)
          .border({ width: { bottom: 1 }, color: $r('app.color.outline_soft') })
          .accessibilityText('今日备注，可选，最多三十个字，不能换行')
          .onChange((value: string) => this.onNoteChange(value))

        if (this.noteError.length > 0) {
          Text(this.noteError)
            .fontSize(13)
            .fontColor('#BA1A1A')
            .textAlign(TextAlign.Start)
            .accessibilityLevel('yes')
        }
      }
      .width('100%')
      .padding({ left: 24, right: 24 })
      .margin({ top: 6 })

      Blank()

      DiaryPrimaryButton({
        label: this.isRevision ? '继续确认' : '落字',
        isEnabled: this.canConfirm,
        onTap: () => this.onConfirmWord()
      })

      if (this.isRevision) {
        Row({ space: 8 }) {
          Button('改为留白')
            .height($r('app.float.touch_target_min'))
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
            .backgroundColor(Color.Transparent)
            .onClick(() => this.onConfirmBlank())

          Text('·')
            .fontSize(13)
            .fontColor($r('app.color.outline_soft'))

          Button('取消修订')
            .height($r('app.float.touch_target_min'))
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
            .backgroundColor(Color.Transparent)
            .onClick(() => this.onCancelRevision())
        }
      } else {
        Button('把今天留给空白')
          .height($r('app.float.touch_target_min'))
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
          .backgroundColor(Color.Transparent)
          .accessibilityText('把今天留给空白')
          .onClick(() => this.onConfirmBlank())
      }

      Text(`已留下 ${this.recordCount} 天`)
        .fontSize(12)
        .fontColor($r('app.color.text_tertiary'))
        .letterSpacing(1.4)
        .margin({ bottom: 14 })
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
  }
}