import { AppErrorPanel, AppLoadingPanel } from '../components/common/AppStatusPanel';
import { DiaryIconButton } from '../components/common/DiaryIconButton';
import { PaperBackdrop } from '../components/common/PaperBackdrop';
import { allStylePresets, StylePresetId, StyleTokens, styleForPaper } from '../constants/StyleTokens';
import { allFontOptions, FontOption, FontPresetId } from '../constants/FontCatalog';
import { SettingsUiState } from '../model/SettingsUiState';
import { AppServiceContainer } from '../service/AppServiceContainer';
import { SettingsViewModel } from '../viewmodel/SettingsViewModel';

@Component
export struct SettingsPage {
  @State private viewModel: SettingsViewModel = new SettingsViewModel(
    AppServiceContainer.getSettingsRepository(),
    AppServiceContainer.getReminderScheduler(),
    AppServiceContainer.getResetService()
  );
  onBack: () => void = () => {
  };
  onOpenPrivacy: (paperId: string) => void = () => {
  };
  onOpenBackup: (paperId: string) => void = () => {
  };
  onClearComplete: () => void = () => {
  };
  onFontChanged: (fontPresetId: FontPresetId) => void = () => {
  };

  @StorageProp('currentPaperId') paperId: string = 'warm_paper_dev';
  @State private contentShown: boolean = false;
  private revealTimer: number = -1;

  aboutToAppear(): void {
    this.revealTimer = setTimeout(() => {
      this.getUIContext().animateTo({ duration: 300, curve: Curve.EaseOut }, () => {
        this.contentShown = true;
      });
    }, 30);
    void this.loadSettings();
  }

  aboutToDisappear(): void {
    if (this.revealTimer !== -1) {
      clearTimeout(this.revealTimer);
    }
  }

  onPageShow(): void {
    if (this.viewModel.uiState !== SettingsUiState.LOADING) {
      void this.loadSettings();
    }
  }

  private async loadSettings(): Promise<void> {
    await this.viewModel.load();
  }

  private showFirstClearConfirmation(): void {
    this.getUIContext().showAlertDialog({
      title: '清空全部数据？',
      message: '这会永久删除设备上的全部日记和背景图片，并恢复默认设置。',
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '继续',
        fontColor: $r('app.color.accent_vermilion'),
        action: () => this.showFinalClearConfirmation()
      }
    });
  }

  private showFinalClearConfirmation(): void {
    this.getUIContext().showAlertDialog({
      title: '确认永久清空？',
      message: '设备上的全部记录将永久删除且无法恢复。此操作无法撤销。',
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '确认清空',
        fontColor: $r('app.color.error_danger'),
        action: () => this.performClear()
      }
    });
  }

  private async performClear(): Promise<void> {
    if (await this.viewModel.clearAll()) {
      try {
        this.getUIContext().getPromptAction().showToast({ message: '已清空全部数据' });
      } catch (error) {
        // 提示失败不影响清空结果
      }
      this.onClearComplete();
    }
  }

  @Builder
  private sectionTitle(title: string) {
    Text(title)
      .width('100%')
      .fontSize(13)
      .fontWeight(FontWeight.Medium)
      .fontColor($r('app.color.text_tertiary'))
      .letterSpacing(1.6)
      .padding({ top: 16, bottom: 10 })
  }

  @Builder
  private styleCard(style: StyleTokens, label: string, sample: string) {
    Column({ space: 10 }) {
      Stack({ alignContent: Alignment.Center }) {
        Row()
          .width(70)
          .height(98)
          .backgroundColor(style.light.background)
          .border({
            width: this.viewModel.stylePresetId === style.id ? 2 : 1,
            color: this.viewModel.stylePresetId === style.id ?
              $r('app.color.text_primary') : $r('app.color.outline_soft')
          })
          .borderRadius(3)
          .animation({ duration: 220, curve: Curve.EaseOut })

        Text(sample)
          .fontSize(27)
          .fontFamily('oneword_wenkai, serif')
          .fontColor($r('app.color.text_primary'))
          .scale({
            x: this.viewModel.stylePresetId === style.id ? 1.08 : 1,
            y: this.viewModel.stylePresetId === style.id ? 1.08 : 1
          })
          .animation({ duration: 220, curve: Curve.EaseOut })
      }

      Text(label)
        .fontSize(15)
        .fontColor(this.viewModel.stylePresetId === style.id ?
          $r('app.color.text_primary') : $r('app.color.text_secondary'))
    }
    .width(88)
    .height(144)
    .padding({ top: 4, bottom: 8 })
    .margin({ right: 12, bottom: 8 })
    .onClick(() => this.viewModel.selectStyle(style.id))
    .accessibilityGroup(true)
    .accessibilityText(`${label}风格${this.viewModel.stylePresetId === style.id ? '，已选择' : ''}`)
  }

  private styleLabel(id: StylePresetId): string {
    switch (id) {
      case StylePresetId.PLAIN_ASH:
        return '素灰';
      case StylePresetId.PINE_MIST:
        return '松青';
      case StylePresetId.MIST_BLUE:
        return '雾蓝';
      case StylePresetId.APRICOT_PAPER:
        return '杏笺';
      case StylePresetId.ROSE_PINK:
        return '瑰粉';
      case StylePresetId.PAPER_INK:
      default:
        return '纸墨';
    }
  }

  private styleSample(id: StylePresetId): string {
    switch (id) {
      case StylePresetId.PLAIN_ASH:
        return '灰';
      case StylePresetId.PINE_MIST:
        return '松';
      case StylePresetId.MIST_BLUE:
        return '蓝';
      case StylePresetId.APRICOT_PAPER:
        return '杏';
      case StylePresetId.ROSE_PINK:
        return '瑰';
      case StylePresetId.PAPER_INK:
      default:
        return '墨';
    }
  }

  @Builder
  private fontCard(option: FontOption) {
    Column({ space: 2 }) {
      Text(option.sample)
        .fontSize(21)
        .fontFamily(option.fontFamily)
        .fontColor($r('app.color.text_primary'))

      Text(option.displayName)
        .fontSize(10)
        .fontColor(this.viewModel.fontPresetId === option.id ?
          $r('app.color.text_primary') : $r('app.color.text_secondary'))
        .maxLines(1)
    }
    .width('100%')
    .height(52)
    .justifyContent(FlexAlign.Center)
    .border({
      width: this.viewModel.fontPresetId === option.id ? 2 : 1,
      color: this.viewModel.fontPresetId === option.id ?
        $r('app.color.text_primary') : $r('app.color.outline_soft')
    })
    .borderRadius(10)
    .backgroundColor($r('app.color.surface_primary'))
    .animation({ duration: 180, curve: Curve.EaseOut })
    .onClick(() => this.selectFont(option.id))
    .accessibilityGroup(true)
    .accessibilityText(`${option.displayName}${this.viewModel.fontPresetId === option.id ? '，已选择' : ''}`)
  }

  private async selectFont(fontPresetId: FontPresetId): Promise<void> {
    if (await this.viewModel.selectFont(fontPresetId)) {
      this.onFontChanged(fontPresetId);
    }
  }

  @Builder
  private navigationRow(title: string, value: string, onTap: () => void) {
    Row() {
      Text(title)
        .fontSize(17)
        .fontColor($r('app.color.text_primary'))

      Row({ space: 8 }) {
        if (value.length > 0) {
          Text(value)
            .fontSize(15)
            .fontColor($r('app.color.text_secondary'))
        }
        Text('›')
          .fontSize(24)
          .fontColor($r('app.color.text_tertiary'))
      }
    }
    .width('100%')
    .height(58)
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
    .onClick(() => onTap())
  }

  build() {
    NavDestination() {
      Stack() {
        PaperBackdrop({ paperId: this.paperId })

        if (this.viewModel.uiState === SettingsUiState.LOADING) {
          AppLoadingPanel()
        } else if (this.viewModel.uiState === SettingsUiState.SAVE_ERROR &&
          this.viewModel.errorMessage === '设置暂时无法打开') {
          AppErrorPanel({
            title: '暂时无法打开设置',
            message: this.viewModel.errorMessage,
            onRetry: () => this.viewModel.load()
          })
        } else {
          Column() {
            Row() {
              DiaryIconButton({
                icon: $r('app.media.ic_back'),
                accessibilityLabel: '返回今日',
                onTap: () => this.onBack()
              })

              Text('设置')
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

            Scroll() {
              Column() {
                this.sectionTitle('风格')
                Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
                  ForEach(allStylePresets(), (style: StyleTokens) => {
                    this.styleCard(style, this.styleLabel(style.id), this.styleSample(style.id))
                  }, (style: StyleTokens): string => style.id)
                }
                .width('100%')
                .padding({ bottom: 12 })

                Divider().color($r('app.color.divider_subtle'))

                this.sectionTitle('字体')
                Grid() {
                  ForEach(allFontOptions(), (option: FontOption) => {
                    GridItem() {
                      this.fontCard(option)
                    }
                  }, (option: FontOption): string => option.id)
                }
                .width('100%')
                .height(184)
                .columnsTemplate('1fr 1fr')
                .columnsGap(10)
                .rowsGap(8)
                .padding({ bottom: 12 })

                Divider().color($r('app.color.divider_subtle'))

                this.sectionTitle('关于数据')
                this.navigationRow('备份与恢复', '', () => this.onOpenBackup(this.paperId))
                this.navigationRow('隐私政策', '', () => this.onOpenPrivacy(this.paperId))

                Divider().color($r('app.color.divider_subtle'))

                this.sectionTitle('危险操作')
                Text('清空全部数据')
                  .width('100%')
                  .height(58)
                  .fontSize(17)
                  .fontColor($r('app.color.error_danger'))
                  .textAlign(TextAlign.Start)
                  .onClick(() => this.showFirstClearConfirmation())
                  .accessibilityText('清空全部数据，危险操作')

                if (this.viewModel.errorMessage.length > 0) {
                  Text(this.viewModel.errorMessage)
                    .width('100%')
                    .fontSize(14)
                    .fontColor($r('app.color.accent_vermilion'))
                    .padding({ top: 6, bottom: 24 })
                } else {
                  Row().height(36)
                }
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
            }
            .layoutWeight(1)
            .scrollBar(BarState.Off)
            .edgeEffect(EdgeEffect.Spring)
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

        if (this.viewModel.uiState === SettingsUiState.CLEARING) {
          Column({ space: 14 }) {
            LoadingProgress()
              .width(30)
              .height(30)
              .color($r('app.color.accent_vermilion'))
            Text('正在清空…')
              .fontSize(15)
              .fontColor($r('app.color.text_secondary'))
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor($r('app.color.scrim_paper'))
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(styleForPaper(this.paperId).light.background)
    }
    .hideTitleBar(true)
    .backgroundColor(styleForPaper(this.paperId).light.background)
  }
}
