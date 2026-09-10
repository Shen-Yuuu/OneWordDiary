import { picker } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { DiaryIconButton } from '../components/common/DiaryIconButton';
import { PaperBackdrop } from '../components/common/PaperBackdrop';
import { styleForPaper } from '../constants/StyleTokens';
import { BackupUiState } from '../model/BackupModel';
import { AppServiceContainer } from '../service/AppServiceContainer';
import { BackupViewModel } from '../viewmodel/BackupViewModel';

@Component
export struct BackupPage {
  @Prop paperId: string = 'warm_paper_dev';
  @State private viewModel: BackupViewModel = new BackupViewModel(AppServiceContainer.getBackupService());
  @State private contentShown: boolean = false;
  private revealTimer: number = -1;
  onBack: () => void = () => {
  };

  aboutToAppear(): void {
    this.revealTimer = setTimeout(() => {
      this.getUIContext().animateTo({ duration: 300, curve: Curve.EaseOut }, () => {
        this.contentShown = true;
      });
    }, 30);
  }

  aboutToDisappear(): void {
    if (this.revealTimer !== -1) {
      clearTimeout(this.revealTimer);
    }
  }

  private showExportWarning(): void {
    this.getUIContext().showAlertDialog({
      title: '导出本地备份？',
      message: '备份文件未加密，包含日记正文和备注。',
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '选择保存位置',
        fontColor: $r('app.color.accent_vermilion'),
        action: () => this.chooseExportLocation()
      }
    });
  }

  private async chooseExportLocation(): Promise<void> {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    if (context === undefined) {
      this.showPickerUnavailable();
      return;
    }
    try {
      const options = new picker.DocumentSaveOptions();
      options.newFileNames = [this.defaultBackupName()];
      options.fileSuffixChoices = ['一字日记备份|.oneword'];
      const uris = await new picker.DocumentViewPicker(context).save(options);
      if (uris.length === 0) {
        return;
      }
      await this.viewModel.exportToUri(uris[0]);
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: '未导出文件' });
    }
  }

  private async chooseImportFile(): Promise<void> {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    if (context === undefined) {
      this.showPickerUnavailable();
      return;
    }
    try {
      const options = new picker.DocumentSelectOptions();
      options.maxSelectNumber = 1;
      options.fileSuffixFilters = ['一字日记备份|.oneword'];
      const uris = await new picker.DocumentViewPicker(context).select(options);
      if (uris.length === 0) {
        return;
      }
      if (await this.viewModel.prepareImport(uris[0])) {
        this.showImportConfirmation();
      }
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({ message: '未选择备份文件' });
    }
  }

  private showImportConfirmation(): void {
    this.getUIContext().showAlertDialog({
      title: '确认导入？',
      message: this.viewModel.importSummary + ' 冲突日期始终保留本机记录。',
      primaryButton: {
        value: '取消',
        action: () => this.viewModel.cancelImportReview()
      },
      secondaryButton: {
        value: '确认导入',
        fontColor: $r('app.color.accent_vermilion'),
        action: () => this.viewModel.confirmImport()
      },
      cancel: () => this.viewModel.cancelImportReview()
    });
  }

  private showPickerUnavailable(): void {
    this.getUIContext().getPromptAction().showToast({ message: '系统文件选择器暂不可用' });
  }

  private defaultBackupName(): string {
    const now = new Date();
    return `oneword-${now.getFullYear()}${this.pad(now.getMonth() + 1)}${this.pad(now.getDate())}.oneword`;
  }

  private pad(value: number): string {
    return value < 10 ? `0${value}` : value.toString();
  }

  @Builder
  private operationCard(icon: string, title: string, description: string, onTap: () => void) {
    Row({ space: 18 }) {
      Stack({ alignContent: Alignment.Center }) {
        Row()
          .width(48)
          .height(48)
          .border({ width: 1, color: $r('app.color.outline_soft') })
          .borderRadius(24)

        Text(icon)
          .fontSize(20)
          .fontColor($r('app.color.text_secondary'))
      }

      Column({ space: 6 }) {
        Text(title)
          .fontSize(18)
          .fontColor($r('app.color.text_primary'))

        Text(description)
          .fontSize(13)
          .lineHeight(20)
          .fontColor($r('app.color.text_secondary'))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Text('›')
        .fontSize(24)
        .fontColor($r('app.color.text_tertiary'))
    }
    .width('100%')
    .padding(18)
    .backgroundColor($r('app.color.card_overlay'))
    .border({ width: 1, color: $r('app.color.divider_subtle') })
    .borderRadius(12)
    .alignItems(VerticalAlign.Center)
    .onClick(() => onTap())
    .accessibilityGroup(true)
    .accessibilityText(`${title}，${description}`)
  }

  build() {
    NavDestination() {
      Stack() {
        PaperBackdrop({ paperId: this.paperId })

        Column() {
          Row() {
            DiaryIconButton({
              icon: $r('app.media.ic_back'),
              accessibilityLabel: '返回设置',
              onTap: () => this.onBack()
            })

            Text('备份与恢复')
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

          Column({ space: 22 }) {
            this.operationCard('↑', '导出备份', '导出 .oneword 文件', () => this.showExportWarning())
            this.operationCard('↓', '导入备份', '从 .oneword 文件恢复', () => this.chooseImportFile())

            if (this.viewModel.resultMessage.length > 0) {
              Column({ space: 10 }) {
                Text(this.viewModel.resultMessage)
                  .fontSize(15)
                  .lineHeight(23)
                  .fontColor($r('app.color.text_primary'))
                  .textAlign(TextAlign.Center)
              }
              .width('100%')
              .padding(18)
              .border({ width: 1, color: $r('app.color.outline_soft') })
              .borderRadius(10)
              .onClick(() => this.viewModel.resetFeedback())
            } else if (this.viewModel.errorMessage.length > 0) {
              Column({ space: 10 }) {
                Text(this.viewModel.errorMessage)
                  .fontSize(15)
                  .lineHeight(23)
                  .fontColor($r('app.color.text_primary'))
                  .textAlign(TextAlign.Center)
              }
              .width('100%')
              .padding(18)
              .border({ width: 1, color: $r('app.color.outline_soft') })
              .borderRadius(10)
              .onClick(() => this.viewModel.resetFeedback())
            }

            Text('同日期记录不会被覆盖')
              .fontSize(12)
              .lineHeight(20)
              .fontColor($r('app.color.text_tertiary'))
              .textAlign(TextAlign.Center)
              .margin({ top: 8 })
          }
          .layoutWeight(1)
          .width('100%')
          .padding({ left: 24, right: 24 })
        }
        .width('100%')
        .height('100%')
        .padding({ top: $r('app.float.immersive_top_content_offset') })
        .opacity(this.contentShown ? 1 : 0)
        .translate({ y: this.contentShown ? 0 : 14 })

        if (this.viewModel.isBusy) {
          Column({ space: 14 }) {
            LoadingProgress()
              .width(30)
              .height(30)
              .color($r('app.color.accent_vermilion'))
            Text(this.viewModel.uiState === BackupUiState.EXPORTING ? '正在导出…' :
              this.viewModel.uiState === BackupUiState.IMPORTING ? '正在导入…' : '正在检查文件…')
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
