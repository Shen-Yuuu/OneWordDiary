import { AppErrorPanel, AppLoadingPanel } from '../components/common/AppStatusPanel';
import { DiaryIconButton } from '../components/common/DiaryIconButton';
import { PaperBackdrop } from '../components/common/PaperBackdrop';
import { DetailRecordContent } from '../components/detail/DetailRecordContent';

import { DetailUiState } from '../model/DetailUiState';
import { AppServiceContainer } from '../service/AppServiceContainer';
import { DiaryDateFormatter } from '../utils/DiaryDateFormatter';
import { DetailViewModel } from '../viewmodel/DetailViewModel';

@Component
export struct DetailPage {
  @Prop localDate: string = '';
  @State private viewModel: DetailViewModel = new DetailViewModel(
    AppServiceContainer.getDiaryService(),
    new DiaryDateFormatter()
  );
  @StorageProp('currentPaperId') paperId: string = 'warm_paper_dev';
  onBack: () => void = () => {
  };
  onShare: () => void = () => {
  };


  aboutToAppear(): void {
    this.viewModel.load(this.localDate);
  }

  build() {
    NavDestination() {
      Stack() {
        PaperBackdrop({ paperId: this.paperId })

        Column() {
          Row() {
            DiaryIconButton({
              icon: $r('app.media.ic_back'),
              accessibilityLabel: '返回文字长卷',
              onTap: () => this.onBack()
            })

            Text('一字日记')
              .fontSize(22)
              .fontFamily('oneword_wenkai, serif')
              .fontColor($r('app.color.text_primary'))
              .letterSpacing(2.6)

            Row()
              .width($r('app.float.touch_target_min'))
              .height($r('app.float.touch_target_min'))
          }
          .width('100%')
          .height($r('app.float.top_bar_height'))
          .padding({ left: 12, right: 12 })
          .justifyContent(FlexAlign.SpaceBetween)
          .alignItems(VerticalAlign.Center)

          if (this.viewModel.uiState === DetailUiState.LOADING) {
            AppLoadingPanel()
              .layoutWeight(1)
          } else if (this.viewModel.uiState === DetailUiState.LOAD_ERROR) {
            AppErrorPanel({
              title: '暂时无法打开这一天',
              message: this.viewModel.errorMessage,
              onRetry: () => this.viewModel.load(this.localDate)
            })
              .layoutWeight(1)
          } else if (this.viewModel.uiState === DetailUiState.NOT_FOUND) {
            Column({ space: 18 }) {
              Stack({ alignContent: Alignment.Center }) {
                Row()
                  .width(68)
                  .height(68)
                  .border({ width: 1, color: $r('app.color.outline_soft') })
                  .borderRadius(34)

                Row()
                  .width(6)
                  .height(6)
                  .backgroundColor($r('app.color.text_tertiary'))
                  .borderRadius(3)
              }

              Text('这一天没有记录')
                .fontSize(22)
                .fontFamily('oneword_wenkai, serif')
                .fontColor($r('app.color.text_primary'))
                .letterSpacing(3)

              Text('它可能已在恢复或清空数据时离开长卷。')
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
                .textAlign(TextAlign.Center)

              Button('返回长卷')
                .width($r('app.float.primary_button_width'))
                .height($r('app.float.primary_button_height'))
                .fontSize(14)
                .fontColor($r('app.color.on_ink_button'))
                .backgroundColor($r('app.color.ink_button'))
                .borderRadius(26)
                .onClick(() => this.onBack())
            }
            .layoutWeight(1)
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .padding(32)
            .accessibilityGroup(true)
          } else {
            DetailRecordContent({
              dateLabel: this.viewModel.dateLabel,
              recordType: this.viewModel.recordType,
              content: this.viewModel.content,
              contentCount: this.viewModel.contentCount,
              note: this.viewModel.note,
              fontId: this.viewModel.fontId,
              paperId: this.viewModel.paperId,
              onShare: () => this.onShare()
            })
              .layoutWeight(1)
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor(Color.Transparent)
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
    .backgroundColor(Color.Transparent)
  }
}
