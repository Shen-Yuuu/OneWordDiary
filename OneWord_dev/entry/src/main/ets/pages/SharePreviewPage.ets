import { AppErrorPanel, AppLoadingPanel } from '../components/common/AppStatusPanel';
import { DiaryIconButton } from '../components/common/DiaryIconButton';
import { DiaryPrimaryButton } from '../components/common/DiaryPrimaryButton';
import { PaperBackdrop } from '../components/common/PaperBackdrop';
import { ShareSevenCard } from '../components/share/ShareSevenCard';
import { ShareSingleCard } from '../components/share/ShareSingleCard';
import { DiaryShareMode } from '../model/ShareModel';
import { ShareUiState } from '../model/ShareUiState';
import { AppServiceContainer } from '../service/AppServiceContainer';
import { SHARE_CARD_COMPONENT_ID, ShareImageService } from '../service/ShareImageService';
import { SystemClock } from '../utils/Clock';
import { DiaryDateFormatter } from '../utils/DiaryDateFormatter';
import { SystemLocalTimeResolver } from '../utils/LocalTimeResolver';
import { ShareViewModel } from '../viewmodel/ShareViewModel';

@Component
export struct SharePreviewPage {
  @Prop initialMode: DiaryShareMode = DiaryShareMode.SINGLE;
  @Prop preferredSingleDate: string | null = null;
  @State private viewModel: ShareViewModel = new ShareViewModel(
    AppServiceContainer.getDiaryService(),
    AppServiceContainer.getSettingsRepository(),
    new SystemClock(),
    new SystemLocalTimeResolver(),
    new DiaryDateFormatter()
  );
  private readonly imageService: ShareImageService = new ShareImageService();
  onBack: () => void = () => {
  };

  aboutToAppear(): void {
    this.viewModel.load(this.initialMode, this.preferredSingleDate);
  }

  aboutToDisappear(): void {
    this.imageService.cleanup();
  }

  private async shareCurrentCard(): Promise<void> {
    if (!this.viewModel.beginRendering()) {
      return;
    }
    try {
      const fileName = this.viewModel.mode === DiaryShareMode.SINGLE ?
        'oneword-single-share.png' : 'oneword-seven-days-share.png';
      await this.imageService.shareCard(
        this.getUIContext(),
        AppServiceContainer.getAbilityContext(),
        SHARE_CARD_COMPONENT_ID,
        fileName
      );
      this.viewModel.finishRendering();
    } catch (error) {
      this.viewModel.failRendering();
    }
  }

  @Builder
  private modeButton(mode: DiaryShareMode, label: string) {
    Button(label)
      .height(34)
      .padding({ left: 22, right: 22 })
      .fontSize(13)
      .fontColor(this.viewModel.mode === mode ? '#FFFFFF' : $r('app.color.text_secondary'))
      .backgroundColor(this.viewModel.mode === mode ? $r('app.color.ink_button') : Color.Transparent)
      .borderRadius(17)
      .enabled(!this.viewModel.isBusy)
      .onClick(() => this.viewModel.selectMode(mode))
  }

  @Builder
  private shareCard() {
    if (this.viewModel.mode === DiaryShareMode.SINGLE && this.viewModel.singleData !== null) {
      ShareSingleCard({
        localDate: this.viewModel.singleData.localDate,
        recordType: this.viewModel.singleData.recordType,
        content: this.viewModel.singleData.content,
        fontId: this.viewModel.singleData.fontId,
        paperId: this.viewModel.singleData.paperId
      })
        .id(SHARE_CARD_COMPONENT_ID)
    } else if (this.viewModel.mode === DiaryShareMode.SEVEN_DAYS) {
      ShareSevenCard({
        days: this.viewModel.sevenDays,
        fontId: this.viewModel.sevenFontId,
        paperId: this.viewModel.sevenPaperId
      })
        .id(SHARE_CARD_COMPONENT_ID)
    }
  }

  build() {
    NavDestination() {
      Stack() {
        PaperBackdrop({ paperId: this.viewModel.activePaperId })

        Column() {
          Row() {
            DiaryIconButton({
              icon: $r('app.media.ic_close'),
              accessibilityLabel: '关闭分享预览',
              onTap: () => this.onBack()
            })

            Text('分享预览')
              .fontSize(22)
              .fontFamily('serif')
              .fontColor($r('app.color.text_primary'))
              .letterSpacing(3)

            Row()
              .width($r('app.float.touch_target_min'))
              .height($r('app.float.touch_target_min'))
          }
          .width('100%')
          .height($r('app.float.top_bar_height'))
          .justifyContent(FlexAlign.SpaceBetween)
          .alignItems(VerticalAlign.Center)

          if (this.viewModel.uiState === ShareUiState.LOADING) {
            AppLoadingPanel()
              .layoutWeight(1)
          } else if (this.viewModel.uiState === ShareUiState.LOAD_ERROR) {
            AppErrorPanel({
              title: '暂时无法准备分享内容',
              message: this.viewModel.errorMessage,
              onRetry: () => this.viewModel.load(this.initialMode, this.preferredSingleDate)
            })
              .layoutWeight(1)
          } else if (this.viewModel.uiState === ShareUiState.SINGLE_NOT_FOUND) {
            AppErrorPanel({
              title: '这一天没有可分享的记录',
              message: '记录可能已在恢复或清空数据时离开。',
              onRetry: () => this.onBack()
            })
              .layoutWeight(1)
          } else {
            Column({ space: 16 }) {
              Row() {
                this.modeButton(DiaryShareMode.SINGLE, '单日')
                this.modeButton(DiaryShareMode.SEVEN_DAYS, '最近七日')
              }
              .padding(3)
              .border({ width: 1, color: $r('app.color.outline_soft') })
              .borderRadius(20)

              this.shareCard()

              Text('分享图不包含备注')
                .fontSize(12)
                .fontColor($r('app.color.text_tertiary'))
                .letterSpacing(1)

              if (this.viewModel.errorMessage.length > 0) {
                Text(this.viewModel.errorMessage)
                  .fontSize(13)
                  .fontColor($r('app.color.accent_vermilion'))
                  .textAlign(TextAlign.Center)
              }

              DiaryPrimaryButton({
                label: this.viewModel.uiState === ShareUiState.RENDERING ? '正在生成…' : '系统分享',
                isEnabled: this.viewModel.canShare && !this.viewModel.isBusy,
                onTap: () => this.shareCurrentCard()
              })
            }
            .layoutWeight(1)
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .padding({ top: 12, bottom: 18 })
          }
        }
        .width('100%')
        .height('100%')
        .padding({ left: 24, right: 24 })
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
    .backgroundColor(Color.Transparent)
  }
}
