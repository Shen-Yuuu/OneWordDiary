import { AppErrorPanel, AppLoadingPanel } from '../components/common/AppStatusPanel';
import { DetailRecordContent } from '../components/detail/DetailRecordContent';
import { DailyRecord, RecordType } from '../model/DailyRecord';
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
  onBack: () => void = () => {
  };
  onShare: () => void = () => {
  };

  get record(): DailyRecord | null {
    return this.viewModel.record;
  }

  get recordType(): RecordType {
    return this.record === null ? RecordType.WORD : this.record.recordType;
  }

  get content(): string {
    return this.record === null || this.record.content === null ? '' : this.record.content;
  }

  get note(): string {
    return this.record === null || this.record.note === null ? '' : this.record.note;
  }

  get fontId(): string {
    return this.record === null ? 'system_serif_dev' : this.record.fontId;
  }

  get paperId(): string {
    return this.record === null ? 'warm_paper_dev' : this.record.paperId;
  }

  aboutToAppear(): void {
    this.viewModel.load(this.localDate);
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
            .accessibilityText('返回文字长卷')
            .onClick(() => this.onBack())

          Text('一字日记')
            .fontSize(22)
            .fontFamily('serif')
            .fontColor($r('app.color.text_primary'))
            .letterSpacing(2)

          Row()
            .width($r('app.float.touch_target_min'))
            .height($r('app.float.touch_target_min'))
        }
        .width('100%')
        .height(64)
        .padding({ left: 12, right: 12 })
        .justifyContent(FlexAlign.SpaceBetween)

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
            Text('这一天没有记录')
              .fontSize(22)
              .fontFamily('serif')
              .fontColor($r('app.color.text_primary'))
              .letterSpacing(3)

            Text('它可能已在恢复或清空数据时离开长卷。')
              .fontSize(13)
              .fontColor($r('app.color.text_secondary'))
              .textAlign(TextAlign.Center)

            Button('返回长卷')
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
          DetailRecordContent({
            dateLabel: this.viewModel.dateLabel,
            recordType: this.recordType,
            content: this.content,
            contentCount: this.viewModel.contentCount,
            note: this.note,
            fontId: this.fontId,
            paperId: this.paperId,
            onShare: () => this.onShare()
          })
            .layoutWeight(1)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.paperId === 'plain_ash_dev' ? '#F7F7F5' : '#FDF8F7')
    }
    .hideTitleBar(true)
    .backgroundColor(this.paperId === 'plain_ash_dev' ? '#F7F7F5' : '#FDF8F7')
  }
}
