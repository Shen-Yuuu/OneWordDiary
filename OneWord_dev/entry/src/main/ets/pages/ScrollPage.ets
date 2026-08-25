import { AppErrorPanel, AppLoadingPanel } from '../components/common/AppStatusPanel';
import { DiaryIconButton } from '../components/common/DiaryIconButton';
import { PaperBackdrop } from '../components/common/PaperBackdrop';
import { ScrollFooter } from '../components/scroll/ScrollFooter';
import { ScrollRecordNode } from '../components/scroll/ScrollRecordNode';
import { ScrollDisplayItem } from '../model/ScrollDisplayItem';
import { ScrollUiState } from '../model/ScrollUiState';
import { AppServiceContainer } from '../service/AppServiceContainer';
import { DiaryDateFormatter } from '../utils/DiaryDateFormatter';
import { ScrollViewModel } from '../viewmodel/ScrollViewModel';

@Component
export struct ScrollPage {
  @State private viewModel: ScrollViewModel = new ScrollViewModel(
    AppServiceContainer.getDiaryService(),
    30,
    new DiaryDateFormatter()
  );
  onBack: () => void = () => {
  };
  onOpenDetail: (localDate: string) => void = (localDate: string) => {
  };
  onShareSevenDays: () => void = () => {
  };

  aboutToAppear(): void {
    if (this.viewModel.uiState === ScrollUiState.INITIAL_LOADING && this.viewModel.dataSource.totalCount() === 0) {
      this.viewModel.load();
    }
  }

  build() {
    NavDestination() {
      Stack() {
        PaperBackdrop()

        Column() {
          Row() {
            DiaryIconButton({
              icon: $r('app.media.ic_back'),
              accessibilityLabel: '返回今日',
              onTap: () => this.onBack()
            })

            Column({ space: 2 }) {
              Text('文字长卷')
                .fontSize(22)
                .fontFamily('serif')
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.text_primary'))
                .letterSpacing(2.6)

              Text(`已留下 ${this.viewModel.totalCount} 天`)
                .fontSize(11)
                .fontColor($r('app.color.text_tertiary'))
                .letterSpacing(1.2)
            }
            .alignItems(HorizontalAlign.Center)

            DiaryIconButton({
              icon: $r('app.media.ic_share'),
              accessibilityLabel: '分享最近七日',
              onTap: () => this.onShareSevenDays()
            })
          }
          .width('100%')
          .height($r('app.float.top_bar_height'))
          .padding({ left: 12, right: 12 })
          .justifyContent(FlexAlign.SpaceBetween)
          .alignItems(VerticalAlign.Center)

          if (this.viewModel.uiState === ScrollUiState.INITIAL_LOADING) {
            AppLoadingPanel()
              .layoutWeight(1)
          } else if (this.viewModel.uiState === ScrollUiState.INITIAL_ERROR) {
            AppErrorPanel({
              title: '暂时未能展开长卷',
              message: this.viewModel.errorMessage,
              onRetry: () => this.viewModel.load()
            })
              .layoutWeight(1)
          } else if (this.viewModel.uiState === ScrollUiState.EMPTY) {
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
                  .backgroundColor($r('app.color.accent_vermilion'))
                  .borderRadius(2)
              }

              Text('长卷尚空')
                .fontSize(22)
                .fontFamily('serif')
                .fontColor($r('app.color.text_primary'))
                .letterSpacing(4)

              Text('今天落下的字，会从这里慢慢展开。')
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
                .textAlign(TextAlign.Center)

              Button('回到今天')
                .width($r('app.float.primary_button_width'))
                .height($r('app.float.primary_button_height'))
                .fontSize(14)
                .fontColor('#FFFFFF')
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
            List() {
              LazyForEach(this.viewModel.dataSource, (item: ScrollDisplayItem) => {
                ListItem() {
                  ScrollRecordNode({
                    item: item,
                    onOpen: (localDate: string) => this.onOpenDetail(localDate)
                  })
                }
              }, (item: ScrollDisplayItem): string => item.localDate)

              ListItem() {
                ScrollFooter({
                  isLoading: this.viewModel.isLoadingMore,
                  errorMessage: this.viewModel.loadMoreError,
                  hasMore: this.viewModel.hasMore,
                  onRetry: () => this.viewModel.retryLoadMore()
                })
              }
            }
            .layoutWeight(1)
            .width('100%')
            .padding({ left: 20, right: 20 })
            .cachedCount(6)
            .scrollBar(BarState.Off)
            .edgeEffect(EdgeEffect.Spring)
            .onReachEnd(() => this.viewModel.loadMore())
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.paper_warm'))
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.paper_warm'))
    }
    .hideTitleBar(true)
    .backgroundColor($r('app.color.paper_warm'))
  }
}
