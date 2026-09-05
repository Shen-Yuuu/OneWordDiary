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

  contentFontSize(): number {
    if (this.contentCount <= 1) {
      return 50;
    }
    if (this.contentCount === 2) {
      return 40;
    }
    return this.contentCount === 3 ? 33 : 28;
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
          .fontSize(this.contentFontSize())
          .fontWeight(FontWeight.Medium)
          .fontFamily('oneword_wenkai_medium, serif')
          .fontColor($r('app.color.text_primary'))
          .placeholderColor($r('app.color.text_tertiary'))
          .placeholderFont({ size: 28, weight: FontWeight.Lighter })
          .textAlign(TextAlign.Center)
          .caretColor($r('app.color.accent_vermilion'))
          .backgroundColor(Color.Transparent)
          .border({ width: 0 })
          .accessibilityText('今日正文，一至四个字')
          .onChange((value: string) => this.onContentChange(value))

        Text(`${this.contentCount} / 4`)
          .fontSize(13)
          .margin({ top: -40 })
          .fontColor(this.contentError.length > 0 ? $r('app.color.error_danger') : $r('app.color.text_tertiary'))
          .letterSpacing(1.4)

        if (this.contentError.length > 0) {
          Text(this.contentError)
            .fontSize(13)
            .fontColor($r('app.color.error_danger'))
            .textAlign(TextAlign.Center)
            .accessibilityLevel('yes')
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)

      Column({ space: 4 }) {
        TextInput({ text: this.note, placeholder: '为今天留一句注脚（可选）' })
          .width('100%')
          .height(110)
          .fontSize(15)
          .fontFamily('oneword_wenkai, serif')
          .fontColor($r('app.color.text_primary'))
          .placeholderColor($r('app.color.text_tertiary'))
          .placeholderFont({ size: 15, family: 'oneword_wenkai, serif' })
          .textAlign(TextAlign.Center)
          .caretColor($r('app.color.accent_vermilion'))
          .backgroundColor(Color.Transparent)
          .border({ width: 0 })
          .padding({ left: 0, right: 0, top: 6 })
          .accessibilityText('今日备注，可选，最多三十个字，不能换行')
          .onChange((value: string) => this.onNoteChange(value))

        Text(`${this.noteCount} / 30`)
          .fontSize(11)
          .margin({ top: -40 })
          .fontColor(this.noteError.length > 0 ? $r('app.color.error_danger') : $r('app.color.text_tertiary'))
          .width('100%')
          .textAlign(TextAlign.End)

        if (this.noteError.length > 0) {
          Text(this.noteError)
            .fontSize(13)
            .fontColor($r('app.color.error_danger'))
            .width('100%')
            .textAlign(TextAlign.End)
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
            .fontColor($r('app.color.text_tertiary'))

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