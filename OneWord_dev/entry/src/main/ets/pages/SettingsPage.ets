import { AppErrorPanel, AppLoadingPanel } from '../components/common/AppStatusPanel';
import { DiaryIconButton } from '../components/common/DiaryIconButton';
import { PaperBackdrop } from '../components/common/PaperBackdrop';
import { StylePresetId } from '../constants/StyleTokens';
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

  get activePaperId(): string {
    return this.viewModel.stylePresetId === StylePresetId.PLAIN_ASH ? 'plain_ash_dev' : 'warm_paper_dev';
  }

  get activePaperColor(): ResourceColor {
    return this.activePaperId === 'plain_ash_dev' ?
      $r('app.color.paper_plain') : $r('app.color.paper_warm');
  }

  aboutToAppear(): void {
    this.viewModel.load();
  }

  onPageShow(): void {
    if (this.viewModel.uiState !== SettingsUiState.LOADING) {
      this.viewModel.load();
    }
  }

  private toggleReminder(isOn: boolean): void {
    if (isOn) {
      this.showReminderExplanation();
    } else {
      this.viewModel.disableReminder();
    }
  }

  private showReminderExplanation(): void {
    AlertDialog.show({
      title: '开启每日提醒？',
      message: '每天在设定时间轻轻提醒你回望今天。即使当天已经记录，提醒仍会出现，且不会包含日记内容。',
      primaryButton: {
        value: '暂不开启',
        action: () => {
        }
      },
      secondaryButton: {
        value: '继续',
        fontColor: $r('app.color.accent_vermilion'),
        action: () => this.viewModel.enableReminder()
      }
    });
  }

  private showTimePicker(): void {
    const selected = new Date();
    selected.setHours(this.viewModel.reminder.hour, this.viewModel.reminder.minute, 0, 0);
    TimePickerDialog.show({
      selected: selected,
      useMilitaryTime: true,
      onAccept: (value: TimePickerResult) => {
        this.viewModel.changeReminderTime(value.hour, value.minute);
      }
    });
  }

  private showFirstClearConfirmation(): void {
    AlertDialog.show({
      title: '清空全部数据？',
      message: '这会删除所有日记，并重置风格和每日提醒。',
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
    AlertDialog.show({
      title: '确认永久清空？',
      message: '设备上的全部记录将永久删除且无法恢复。此操作无法撤销。',
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '确认清空',
        fontColor: '#BA1A1A',
        action: () => this.performClear()
      }
    });
  }

  private async performClear(): Promise<void> {
    if (await this.viewModel.clearAll()) {
      this.getUIContext().getPromptAction().showToast({ message: '已回到最初的一页' });
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
  private styleCard(stylePresetId: StylePresetId, sample: string, label: string, paperColor: ResourceColor) {
    Column({ space: 10 }) {
      Stack({ alignContent: Alignment.Center }) {
        Row()
          .width(70)
          .height(98)
          .backgroundColor(paperColor)
          .border({
            width: this.viewModel.stylePresetId === stylePresetId ? 2 : 1,
            color: this.viewModel.stylePresetId === stylePresetId ?
              $r('app.color.text_primary') : $r('app.color.outline_soft')
          })
          .borderRadius(3)

        Text(sample)
          .fontSize(27)
          .fontFamily(stylePresetId === StylePresetId.PAPER_INK ? 'serif' : 'sans-serif')
          .fontColor($r('app.color.text_primary'))
      }

      Text(label)
        .fontSize(15)
        .fontColor(this.viewModel.stylePresetId === stylePresetId ?
          $r('app.color.text_primary') : $r('app.color.text_secondary'))
    }
    .width(88)
    .padding({ top: 4, bottom: 8 })
    .onClick(() => this.viewModel.selectStyle(stylePresetId))
    .accessibilityGroup(true)
    .accessibilityText(`${label}风格${this.viewModel.stylePresetId === stylePresetId ? '，已选择' : ''}`)
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
        PaperBackdrop({ paperId: this.activePaperId })

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

            Scroll() {
              Column() {
                this.sectionTitle('风格')
                Row({ space: 18 }) {
                  this.styleCard(StylePresetId.PAPER_INK, '墨', '纸墨', $r('app.color.paper_warm'))
                  this.styleCard(StylePresetId.PLAIN_ASH, '灰', '素灰', $r('app.color.paper_plain'))
                }
                .width('100%')
                .padding({ bottom: 12 })

                Divider().color($r('app.color.divider_subtle'))

                this.sectionTitle('提醒')
                Row() {
                  Text('每日回望提醒')
                    .fontSize(17)
                    .fontColor($r('app.color.text_primary'))

                  Toggle({ type: ToggleType.Switch, isOn: this.viewModel.reminder.enabled })
                    .selectedColor($r('app.color.accent_vermilion'))
                    .enabled(!this.viewModel.isBusy)
                    .onChange((isOn: boolean) => this.toggleReminder(isOn))
                }
                .width('100%')
                .height(58)
                .justifyContent(FlexAlign.SpaceBetween)
                .alignItems(VerticalAlign.Center)

                this.navigationRow('提醒时间', this.viewModel.reminderTimeLabel, () => this.showTimePicker())

                Text(this.viewModel.reminderStatusMessage)
                  .width('100%')
                  .fontSize(14)
                  .lineHeight(22)
                  .fontColor(this.viewModel.uiState === SettingsUiState.READY ?
                    $r('app.color.text_tertiary') : $r('app.color.accent_vermilion'))
                  .padding({ bottom: 10 })

                if (this.viewModel.uiState === SettingsUiState.REMINDER_PERMISSION_DENIED ||
                  this.viewModel.uiState === SettingsUiState.REMINDER_DISABLED_BY_SYSTEM ||
                  this.viewModel.uiState === SettingsUiState.REMINDER_SCHEDULE_ERROR) {
                  Button('重新检查并开启')
                    .height(44)
                    .fontSize(14)
                    .fontColor($r('app.color.text_primary'))
                    .backgroundColor(Color.Transparent)
                    .border({ width: 1, color: $r('app.color.outline_soft') })
                    .borderRadius(22)
                    .margin({ bottom: 12 })
                    .onClick(() => this.viewModel.enableReminder())
                }

                Divider().color($r('app.color.divider_subtle'))

                this.sectionTitle('关于数据')
                this.navigationRow('备份与恢复', '', () => this.onOpenBackup(this.activePaperId))
                this.navigationRow('隐私说明', '', () => this.onOpenPrivacy(this.activePaperId))

                Divider().color($r('app.color.divider_subtle'))

                this.sectionTitle('危险操作')
                Text('清空全部数据')
                  .width('100%')
                  .height(58)
                  .fontSize(17)
                  .fontColor('#BA1A1A')
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
          }
          .width('100%')
          .height('100%')
          .padding({ left: 24, right: 24 })
        }

        if (this.viewModel.uiState === SettingsUiState.CLEARING) {
          Column({ space: 14 }) {
            LoadingProgress()
              .width(30)
              .height(30)
              .color($r('app.color.accent_vermilion'))
            Text('正在收起所有文字…')
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
      .backgroundColor(this.activePaperColor)
    }
    .hideTitleBar(true)
    .backgroundColor(this.activePaperColor)
  }
}
