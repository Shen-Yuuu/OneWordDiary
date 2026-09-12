import { AppErrorPanel, AppLoadingPanel } from '../components/common/AppStatusPanel';
import { DiaryIconButton } from '../components/common/DiaryIconButton';
import { DiaryPrimaryButton } from '../components/common/DiaryPrimaryButton';
import { PaperBackdrop } from '../components/common/PaperBackdrop';
import { styleForPaper } from '../constants/StyleTokens';
import { ShareScrollCard } from '../components/share/ShareScrollCard';
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
  @State private selectedMode: DiaryShareMode = DiaryShareMode.SINGLE;
  @State private viewModel: ShareViewModel = new ShareViewModel(
    AppServiceContainer.getDiaryService(),
    AppServiceContainer.getSettingsRepository(),
    new SystemClock(),
    new SystemLocalTimeResolver(),
    new DiaryDateFormatter()
  );
  private readonly imageService: ShareImageService = new ShareImageService();
  @StorageProp('currentPaperId') paperId: string = 'warm_paper_dev';
  @State private contentShown: boolean = false;
  @State private backgroundImageUri: string = '';
  @State private isBackgroundReady: boolean = true;
  @State private backgroundLoadFailed: boolean = false;
  @State private backgroundReloadKey: number = 0;
  private revealTimer: number = -1;
  private backgroundLoadTimer: number = -1;
  onBack: () => void = () => {
  };

  aboutToAppear(): void {
    this.revealTimer = setTimeout(() => {
      this.getUIContext().animateTo({ duration: 300, curve: Curve.EaseOut }, () => {
        this.contentShown = true;
      });
    }, 30);
    this.selectedMode = this.initialMode;
    this.loadShareData();
  }

  aboutToDisappear(): void {
    if (this.revealTimer !== -1) {
      clearTimeout(this.revealTimer);
    }
    this.clearBackgroundLoadTimer();
    this.imageService.cleanup();
  }

  private async shareCurrentCard(): Promise<void> {
    if (this.selectedMode === DiaryShareMode.SINGLE && !this.isBackgroundReady) {
      return;
    }

    if (!this.viewModel.beginRendering()) {
      return;
    }

    try {
      const fileName = this.selectedMode === DiaryShareMode.SINGLE ?
        'oneword-single-share.png' : 'oneword-seven-days-share.png';

      await this.imageService.shareCard(
        this.getUIContext(),
        AppServiceContainer.getAbilityContext(),
        SHARE_CARD_COMPONENT_ID,
        fileName
      );

      this.viewModel.finishRendering();
    } catch (error) {
      console.error('SharePreviewPage shareCurrentCard failed');
      this.viewModel.failRendering();
    }
  }

  private async loadShareData(): Promise<void> {
    this.backgroundImageUri = '';
    this.isBackgroundReady = true;
    this.backgroundLoadFailed = false;
    await this.viewModel.load(this.initialMode, this.preferredSingleDate);
    this.selectedMode = this.viewModel.mode;
    if (this.viewModel.singleData === null) {
      return;
    }
    this.backgroundImageUri = AppServiceContainer.getBackgroundImageService()
      .resolveUri(this.viewModel.singleData.backgroundImageId);
    if (this.backgroundImageUri.length > 0) {
      this.beginBackgroundLoad();
    }
  }

  private clearBackgroundLoadTimer(): void {
    if (this.backgroundLoadTimer !== -1) {
      clearTimeout(this.backgroundLoadTimer);
      this.backgroundLoadTimer = -1;
    }
  }

  private beginBackgroundLoad(): void {
    this.clearBackgroundLoadTimer();
    this.backgroundLoadFailed = false;
    this.isBackgroundReady = false;
    this.backgroundReloadKey++;
    const generation = this.backgroundReloadKey;
    this.backgroundLoadTimer = setTimeout(() => {
      if (generation !== this.backgroundReloadKey || this.isBackgroundReady) {
        return;
      }
      this.backgroundLoadTimer = -1;
      this.backgroundReloadKey++;
      this.backgroundLoadFailed = true;
      this.isBackgroundReady = true;
    }, 2500);
  }

  private handleBackgroundReady(imageUri: string, reloadKey: number): void {
    if (imageUri !== this.backgroundImageUri || reloadKey !== this.backgroundReloadKey) {
      return;
    }
    this.clearBackgroundLoadTimer();
    this.backgroundLoadFailed = false;
    this.isBackgroundReady = true;
  }

  private handleBackgroundFailed(imageUri: string, reloadKey: number): void {
    if (imageUri !== this.backgroundImageUri || reloadKey !== this.backgroundReloadKey) {
      return;
    }
    this.clearBackgroundLoadTimer();
    this.backgroundReloadKey++;
    this.backgroundLoadFailed = true;
    this.isBackgroundReady = true;
  }

  private retryBackground(): void {
    this.beginBackgroundLoad();
  }

  private selectMode(mode: DiaryShareMode): void {
    this.viewModel.selectMode(mode);
    if (this.viewModel.mode === mode) {
      if (mode === DiaryShareMode.SINGLE && this.backgroundImageUri.length > 0) {
        this.beginBackgroundLoad();
      } else {
        this.clearBackgroundLoadTimer();
      }
      this.getUIContext().animateTo({ duration: 240, curve: Curve.EaseOut }, () => {
        this.selectedMode = mode;
      });
    }
  }

  @Builder
  private modeButton(mode: DiaryShareMode, label: string) {
    Button(label)
      .height(34)
      .padding({ left: 22, right: 22 })
      .fontSize(13)
      .fontColor(this.selectedMode === mode ? $r('app.color.on_ink_button') : $r('app.color.text_secondary'))
      .backgroundColor(this.selectedMode === mode ? $r('app.color.ink_button') : Color.Transparent)
      .borderRadius(17)
      .animation({ duration: 220, curve: Curve.EaseOut })
      .enabled(!this.viewModel.isBusy)
      .onClick(() => this.selectMode(mode))
  }

  @Builder
  private shareCardContent() {
    if (this.selectedMode === DiaryShareMode.SINGLE && this.viewModel.singleData !== null) {
      ShareSingleCard({
        localDate: this.viewModel.singleData.localDate,
        recordType: this.viewModel.singleData.recordType,
        content: this.viewModel.singleData.content,
        fontId: this.viewModel.singleData.fontId,
        paperId: this.viewModel.activePaperId,
        backgroundImageUri: this.backgroundImageUri,
        showBackgroundImage: !this.backgroundLoadFailed,
        backgroundReloadKey: this.backgroundReloadKey,
        onBackgroundReady: (imageUri: string, reloadKey: number) =>
          this.handleBackgroundReady(imageUri, reloadKey),
        onBackgroundFailed: (imageUri: string, reloadKey: number) =>
          this.handleBackgroundFailed(imageUri, reloadKey)
      })
        .transition(TransitionEffect.OPACITY.animation({ duration: 240, curve: Curve.EaseOut }))
    } else if (this.selectedMode === DiaryShareMode.SEVEN_DAYS) {
      ShareScrollCard({
        days: this.viewModel.sevenDays,
        paperId: this.viewModel.activePaperId
      })
        .transition(TransitionEffect.OPACITY.animation({ duration: 240, curve: Curve.EaseOut }))
    }
  }

  @Builder
  private shareCard() {
    Stack() {
      this.shareCardContent()
    }
    .id(SHARE_CARD_COMPONENT_ID)
    .backgroundColor(styleForPaper(this.viewModel.activePaperId).light.background)
  }

  build() {
    NavDestination() {
      Stack() {
        PaperBackdrop({ paperId: this.paperId })

        Column() {
          Row() {
            DiaryIconButton({
              icon: $r('app.media.ic_close'),
              accessibilityLabel: '关闭分享预览',
              onTap: () => this.onBack()
            })

            Text('分享预览')
              .fontSize(22)
              .fontFamily('oneword_wenkai, serif')
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
              onRetry: () => this.loadShareData()
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
            Scroll() {
              Column({ space: 16 }) {
                Row() {
                  this.modeButton(DiaryShareMode.SINGLE, '单日')
                  this.modeButton(DiaryShareMode.SEVEN_DAYS, '最近七日')
                }
                .padding(3)
                .border({ width: 1, color: $r('app.color.outline_soft') })
                .borderRadius(20)

                Stack() {
                  this.shareCard()
                }
                .shadow({ radius: 22, color: '#16000000', offsetX: 0, offsetY: 10 })

                if (this.viewModel.errorMessage.length > 0) {
                  Text(this.viewModel.errorMessage)
                    .fontSize(13)
                    .fontColor($r('app.color.accent_vermilion'))
                    .textAlign(TextAlign.Center)
                }

                if (this.selectedMode === DiaryShareMode.SINGLE && !this.isBackgroundReady) {
                  Text('正在读取背景…')
                    .fontSize(13)
                    .fontColor($r('app.color.text_secondary'))
                }

                if (this.selectedMode === DiaryShareMode.SINGLE && this.backgroundLoadFailed) {
                  Button('背景读取失败，点此重试')
                    .height(40)
                    .fontSize(13)
                    .fontColor($r('app.color.accent_vermilion'))
                    .backgroundColor(Color.Transparent)
                    .onClick(() => this.retryBackground())
                }

                DiaryPrimaryButton({
                  label: this.viewModel.uiState === ShareUiState.RENDERING ? '正在生成…' : '系统分享',
                  isEnabled: this.viewModel.canShare && !this.viewModel.isBusy &&
                    (this.selectedMode === DiaryShareMode.SEVEN_DAYS || this.isBackgroundReady),
                  onTap: () => this.shareCurrentCard()
                })
              }
              .width('100%')
              .alignItems(HorizontalAlign.Center)
              .padding({ top: 12, bottom: 24 })
            }
            .layoutWeight(1)
            .width('100%')
            .scrollBar(BarState.Off)
            .edgeEffect(EdgeEffect.Spring)
          }
        }
        .width('100%')
        .height('100%')
        .padding({
          top: $r('app.float.immersive_top_content_offset'),
          bottom: $r('app.float.immersive_bottom_content_offset'),
          left: 24,
          right: 24
        })
        .opacity(this.contentShown ? 1 : 0)
        .translate({ y: this.contentShown ? 0 : 14 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(styleForPaper(this.paperId).light.background)
    }
    .hideTitleBar(true)
    .backgroundColor(styleForPaper(this.paperId).light.background)
  }
}
