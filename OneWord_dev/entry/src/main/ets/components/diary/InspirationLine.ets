import { DiaryIconButton } from '../common/DiaryIconButton';

@Component
export struct InspirationLine {
  @Prop text: string = '';
  onRefresh: () => void = () => {
  };

  build() {
    Row({ space: 2 }) {
      Text(this.text)
        .fontSize(14)
        .fontWeight(FontWeight.Lighter)
        .fontColor($r('app.color.text_secondary'))
        .letterSpacing(0.8)
        .maxLines(2)
        .textAlign(TextAlign.Center)

      DiaryIconButton({
        icon: $r('app.media.ic_refresh'),
        accessibilityLabel: '换一句今日灵感',
        onTap: () => this.onRefresh()
      })
    }
    .width('100%')
    .height(56)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
  }
}
