import { styleForPaper } from '../../constants/StyleTokens';

@Component
export struct TodayPlaceholder {
  @StorageProp('currentPaperId') paperId: string = 'warm_paper_dev';
  build() {
    Column({ space: 16 }) {
      Divider()
        .width(32)
        .strokeWidth(1)
        .color(styleForPaper(this.paperId).light.accent)

      Text($r('app.string.baseline_ready'))
        .fontSize($r('app.float.body_size'))
        .fontWeight(FontWeight.Lighter)
        .fontColor($r('app.color.text_secondary'))
        .letterSpacing(2)
    }
    .alignItems(HorizontalAlign.Center)
  }
}
