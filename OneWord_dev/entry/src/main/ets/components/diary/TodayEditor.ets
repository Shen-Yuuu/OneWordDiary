import { DiaryIconButton } from '../common/DiaryIconButton';
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

  get contentFontSize(): number {
    if (this.contentCount <= 1) {
      return 104;
    }
    if (this.contentCount === 2) {
      return 78;
    }
    return this.contentCount === 3 ? 62 : 50;
  }

  build() {
    Column() {
      InspirationLine({
        text: this.inspiration,
        onRefresh: () => this.onRefreshInspiration()
      })
        .margin({ top: 20, bottom: 4 })

      Column({ space: 4 }) {
        TextInput({ text: this.content, placeholder: '一至四字' })
          .width('100%')
          .height(158)
          .fontSize(this.contentFontSize)
          .fontWeight(FontWeight.Medium)
          .fontFamily('serif')
          .fontColor($r('app.color.text_primary'))
          .placeholderColor($r('app.color.outline_soft'))
          .placeholderFont({ size: 24, weight: FontWeight.Lighter })
          .textAlign(TextAlign.Center)
          .caretColor($r('app.color.accent_vermilion'))
          .backgroundColor(Color.Transparent)
          .border({ width: 0 })
          .accessibilityText('今日正文，一至四个字')
          .onChange((value: string) => this.onContentChange(value))

        Text(`${this.contentCount} / 4`)
          .fontSize(10)
          .fontColor(this.contentError.length > 0 ? '#BA1A1A' : $r('app.color.text_tertiary'))
          .letterSpacing(1.4)

        if (this.contentError.length > 0) {
          Text(this.contentError)
            .fontSize(11)
            .fontColor('#BA1A1A')
            .textAlign(TextAlign.Center)
            .accessibilityLevel('yes')
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)

      if (this.noteExpanded) {
        Column({ space: 6 }) {
          TextArea({ text: this.note, placeholder: '为今天留一句注脚（可选）' })
            .width('100%')
            .height(72)
            .fontSize(15)
            .fontColor($r('app.color.text_primary'))
            .placeholderColor($r('app.color.text_tertiary'))
            .textAlign(TextAlign.Center)
            .caretColor($r('app.color.accent_vermilion'))
            .backgroundColor(Color.Transparent)
            .border({ width: { bottom: 1 }, color: $r('app.color.outline_soft') })
            .accessibilityText('今日注解，最多三十个字，不能换行')
            .onChange((value: string) => this.onNoteChange(value))

          Text(`${this.noteCount} / 30`)
            .fontSize(10)
            .fontColor(this.noteError.length > 0 ? '#BA1A1A' : $r('app.color.text_tertiary'))
            .alignSelf(ItemAlign.End)

          if (this.noteError.length > 0) {
            Text(this.noteError)
              .fontSize(11)
              .fontColor('#BA1A1A')
              .textAlign(TextAlign.Center)
              .accessibilityLevel('yes')
          }
        }
        .width('100%')
        .padding({ left: 24, right: 24 })
        .margin({ top: 10 })
      }

      Blank()

      Row({ space: 8 }) {
        Row()
          .width($r('app.float.touch_target_min'))
          .height($r('app.float.touch_target_min'))

        Button(this.isRevision ? '继续确认' : '落字')
          .width($r('app.float.primary_button_width'))
          .height($r('app.float.primary_button_height'))
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .backgroundColor($r('app.color.ink_button'))
          .borderRadius(26)
          .enabled(this.canConfirm)
          .opacity(this.canConfirm ? 1 : 0.24)
          .onClick(() => this.onConfirmWord())

        DiaryIconButton({
          icon: $r('app.media.ic_note'),
          accessibilityLabel: this.noteExpanded ? '收起注解' : '添加一句注解',
          bordered: true,
          onTap: () => this.onToggleNote()
        })
      }
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)

      if (this.isRevision) {
        Row({ space: 8 }) {
          Button('改为留白')
            .height($r('app.float.touch_target_min'))
            .fontSize(11)
            .fontColor($r('app.color.text_secondary'))
            .backgroundColor(Color.Transparent)
            .onClick(() => this.onConfirmBlank())

          Text('·')
            .fontSize(11)
            .fontColor($r('app.color.outline_soft'))

          Button('取消修订')
            .height($r('app.float.touch_target_min'))
            .fontSize(11)
            .fontColor($r('app.color.text_secondary'))
            .backgroundColor(Color.Transparent)
            .onClick(() => this.onCancelRevision())
        }
      } else {
        Button('把今天留给空白')
          .height($r('app.float.touch_target_min'))
          .fontSize(11)
          .fontColor($r('app.color.text_secondary'))
          .backgroundColor(Color.Transparent)
          .accessibilityText('把今天留给空白')
          .onClick(() => this.onConfirmBlank())
      }

      Text(`已留下 ${this.recordCount} 天`)
        .fontSize(10)
        .fontColor($r('app.color.text_tertiary'))
        .letterSpacing(1.4)
        .margin({ bottom: 14 })
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
  }
}
