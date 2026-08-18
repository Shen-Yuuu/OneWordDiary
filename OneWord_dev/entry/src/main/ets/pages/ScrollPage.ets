import { AppErrorPanel, AppLoadingPanel } from '../components/common/AppStatusPanel';
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
      Column() {
        Row() {
          Button('返回')
            .height($r('app.float.touch_target_min'))
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
            .backgroundColor(Color.Transparent)
            .accessibilityText('返回今日')
            .onClick(() => this.onBack())

          Column({ space: 2 }) {
            Text('文字长卷')
              .fontSize(22)
              .fontFamily('serif')
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
              .letterSpacing(2.4)

            Text(`已留下 ${this.viewModel.totalCount} 天`)
              .fontSize(10)
              .fontColor($r('app.color.text_secondary'))
              .letterSpacing(1)
          }
          .alignItems(HorizontalAlign.Center)

          Button('近七日')
            .height($r('app.float.touch_target_min'))
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
            .backgroundColor(Color.Transparent)
            .accessibilityText('分享最近七日')
            .onClick(() => this.onShareSevenDays())
        }
        .width('100%')
        .height(64)
        .padding({ left: 12, right: 12 })
        .justifyContent(FlexAlign.SpaceBetween)

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
            Text('长卷尚空')
              .fontSize(24)
              .fontFamily('serif')
              .fontColor($r('app.color.text_primary'))
              .letterSpacing(4)

            Text('今天落下的字，会从这里慢慢展开。')
              .fontSize(13)
              .fontColor($r('app.color.text_secondary'))
              .textAlign(TextAlign.Center)

            Button('回到今天')
              .width(160)
              .height(50)
              .fontSize(13)
              .fontColor('#FFFFFF')
              .backgroundColor($r('app.color.text_primary'))
              .borderRadius(25)
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
          .cachedCount(6)
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
          .onReachEnd(() => this.viewModel.loadMore())
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.app_background'))
    }
    .hideTitleBar(true)
    .backgroundColor($r('app.color.app_background'))
  }
}
