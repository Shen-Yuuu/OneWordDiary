import { picker } from '@kit.CoreFileKit';
import { DiaryIconButton } from '../components/common/DiaryIconButton';
import { PaperBackdrop } from '../components/common/PaperBackdrop';
import { BackupUiState } from '../model/BackupModel';
import { AppServiceContainer } from '../service/AppServiceContainer';
import { BackupViewModel } from '../viewmodel/BackupViewModel';

@Component
export struct BackupPage {
  @Prop paperId: string = 'warm_paper_dev';
  @State private viewModel: BackupViewModel = new BackupViewModel(AppServiceContainer.getBackupService());
  onBack: () => void = () => {
  };

  private showExportWarning(): void {
    AlertDialog.show({
      title: '导出本地备份？',
      message: '备份文件未加密，包含全部日记正文与备注。请保存到可信位置并谨慎分享。',
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
    const context = this.getUIContext().getHostContext();
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
    const context = this.getUIContext().getHostContext();
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
    AlertDialog.show({
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
    .backgroundColor('#66FFFFFF')
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

          Column({ space: 22 }) {
            Column({ space: 8 }) {
              Text('只在你主动选择时读写文件')
                .fontSize(18)
                .fontFamily('serif')
                .fontColor($r('app.color.text_primary'))
                .letterSpacing(1.4)

              Text('备份不经过网络，也不会包含通知权限与提醒时间。')
                .fontSize(14)
                .lineHeight(22)
                .fontColor($r('app.color.text_secondary'))
                .textAlign(TextAlign.Center)
            }
            .padding({ top: 26, bottom: 14 })
            .alignItems(HorizontalAlign.Center)

            this.operationCard('↑', '导出备份', '生成未加密的 .oneword 文件', () => this.showExportWarning())
            this.operationCard('↓', '导入备份', '预检完整文件后，只补入缺失日期', () => this.chooseImportFile())

            if (this.viewModel.resultMessage.length > 0) {
              Column({ space: 10 }) {
                Text('完成')
                  .fontSize(14)
                  .fontColor($r('app.color.accent_vermilion'))
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
                Text('没有改动本机数据')
                  .fontSize(14)
                  .fontColor($r('app.color.accent_vermilion'))
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

            Text('导入不会覆盖同一天的本机记录。文件上限 5 MiB、10000 条记录。')
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

        if (this.viewModel.isBusy) {
          Column({ space: 14 }) {
            LoadingProgress()
              .width(30)
              .height(30)
              .color($r('app.color.accent_vermilion'))
            Text(this.viewModel.uiState === BackupUiState.EXPORTING ? '正在整理备份…' :
              this.viewModel.uiState === BackupUiState.IMPORTING ? '正在收入长卷…' : '正在检查文件…')
              .fontSize(15)
              .fontColor($r('app.color.text_secondary'))
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor('#E6FDF8F7')
        }
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
    .backgroundColor(Color.Transparent)
  }
}

