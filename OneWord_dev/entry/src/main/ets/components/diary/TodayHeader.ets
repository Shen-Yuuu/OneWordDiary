import { DiaryIconButton } from '../common/DiaryIconButton';

@Component
export struct TodayHeader {
  @Prop dateText: string = '';
  @Prop weekdayText: string = '';
  onScroll: () => void = () => {
  };
  onSettings: () => void = () => {
  };

  build() {
    Row() {
      DiaryIconButton({
        icon: $r('app.media.ic_scroll'),
        accessibilityLabel: '打开文字长卷',
        onTap: () => this.onScroll()
      })

      Column({ space: 3 }) {
        Text(this.dateText)
          .fontSize(16)
          .fontWeight(FontWeight.Lighter)
          .fontColor($r('app.color.text_primary'))
          .letterSpacing(1.5)

        Text(this.weekdayText)
          .fontSize(12)
          .fontColor($r('app.color.text_tertiary'))
          .letterSpacing(1.2)
      }
      .alignItems(HorizontalAlign.Center)
      .accessibilityGroup(true)
      .accessibilityText(`${this.dateText}，${this.weekdayText}`)

      DiaryIconButton({
        icon: $r('app.media.ic_settings'),
        accessibilityLabel: '打开设置',
        onTap: () => this.onSettings()
      })
    }
    .width('100%')
    .height($r('app.float.top_bar_height'))
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
  }
}
