import { AppErrorPanel, AppLoadingPanel } from '../components/common/AppStatusPanel';
import { DiaryIconButton } from '../components/common/DiaryIconButton';
import { DiaryPrimaryButton } from '../components/common/DiaryPrimaryButton';
import { PaperBackdrop } from '../components/common/PaperBackdrop';
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
  @State private showNote: boolean = false;
  @State private renderRevision: number = 0;
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

  get activePaperColor(): ResourceColor {
    return this.activePaperId === 'plain_ash_dev' ?
      $r('app.color.paper_plain') : $r('app.color.paper_warm');
  }

  aboutToAppear(): void {
    this.selectedMode = this.initialMode;
    this.loadShareData();
  }

  aboutToDisappear(): void {
    this.imageService.cleanup();
  }

  private async shareCurrentCard(): Promise<void> {
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
      this.viewModel.failRendering();
    }
  }

  get activePaperId(): string {
    if (this.selectedMode === DiaryShareMode.SINGLE && this.viewModel.singleData !== null) {
      return this.viewModel.singleData.paperId;
    }
    return this.viewModel.sevenPaperId;
  }

  private async loadShareData(): Promise<void> {
    await this.viewModel.load(this.initialMode, this.preferredSingleDate);
    this.selectedMode = this.viewModel.mode;
    this.renderRevision += 1;
  }

  private selectMode(mode: DiaryShareMode): void {
    this.viewModel.selectMode(mode);
    if (this.viewModel.mode === mode) {
      this.selectedMode = mode;
      this.renderRevision += 1;
    }
  }

  @Builder
  private modeButton(mode: DiaryShareMode, label: string) {
    Button(label)
      .height(34)
      .padding({ left: 22, right: 22 })
      .fontSize(13)
      .fontColor(this.selectedMode === mode ? '#FFFFFF' : $r('app.color.text_secondary'))
      .backgroundColor(this.selectedMode === mode ? $r('app.color.ink_button') : Color.Transparent)
      .borderRadius(17)
      .enabled(!this.viewModel.isBusy)
      .onClick(() => this.selectMode(mode))
  }

  @Builder
  private shareCardContent() {
    if (this.selectedMode === DiaryShareMode.SINGLE && this.viewModel.singleData !== null) {
      if (this.showNote) {
        ShareSingleCard({
          localDate: this.viewModel.singleData.localDate,
          recordType: this.viewModel.singleData.recordType,
          content: this.viewModel.singleData.content,
          note: this.viewModel.singleData.note,
          showNote: true,
          fontId: this.viewModel.singleData.fontId,
          paperId: this.viewModel.singleData.paperId
        })
      } else {
        ShareSingleCard({
          localDate: this.viewModel.singleData.localDate,
          recordType: this.viewModel.singleData.recordType,
          content: this.viewModel.singleData.content,
          note: '',
          showNote: false,
          fontId: this.viewModel.singleData.fontId,
          paperId: this.viewModel.singleData.paperId
        })
      }
    } else if (this.selectedMode === DiaryShareMode.SEVEN_DAYS) {
      ShareScrollCard({
        days: this.viewModel.sevenDays,
        includeNote: this.showNote,
        revision: this.renderRevision,
        fontId: this.viewModel.sevenFontId,
        paperId: this.viewModel.sevenPaperId
      })
    }
  }

  @Builder
  private shareCard() {
    Stack() {
      ForEach([this.renderRevision], (revision: number) => {
        this.shareCardContent()
      }, (revision: number): string => `${this.selectedMode}-${revision}`)
    }
    .id(SHARE_CARD_COMPONENT_ID)
    .backgroundColor(this.activePaperColor)
  }

  build() {
    NavDestination() {
      Stack() {
        PaperBackdrop({ paperId: this.activePaperId })

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

                Row() {
                  Column({ space: 3 }) {
                    Text('展示备注')
                      .fontSize(14)
                      .fontColor($r('app.color.text_primary'))

                    Text('仅影响本次预览与分享图')
                      .fontSize(11)
                      .fontColor($r('app.color.text_tertiary'))
                  }
                  .alignItems(HorizontalAlign.Start)

                  Toggle({ type: ToggleType.Switch, isOn: this.showNote })
                    .selectedColor($r('app.color.accent_vermilion'))
                    .enabled(!this.viewModel.isBusy)
                    .onChange((isOn: boolean) => {
                      this.showNote = isOn;
                      this.renderRevision += 1;
                    })
                }
                .width(286)
                .justifyContent(FlexAlign.SpaceBetween)
                .alignItems(VerticalAlign.Center)

                Stack() {
                  this.shareCard()
                }
                .shadow({ radius: 22, color: '#16000000', offsetX: 0, offsetY: 10 })

                Text(this.showNote ? '分享图已展示备注' : '分享图不展示备注')
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
        .padding({ left: 24, right: 24 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(this.activePaperColor)
    }
    .hideTitleBar(true)
    .backgroundColor(this.activePaperColor)
  }
}
