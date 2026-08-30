import { StylePresetId } from '../constants/StyleTokens';
import { DEFAULT_APP_SETTINGS, ReminderSettings } from '../model/Settings';
import { SettingsUiState } from '../model/SettingsUiState';
import { SettingsRepository } from '../repository/SettingsRepository';
import { AppResetService } from '../service/AppResetService';
import { ReminderScheduler } from '../service/ReminderScheduler';
import { AppLogger } from '../utils/AppLogger';

@Observed
export class SettingsViewModel {
  uiState: SettingsUiState = SettingsUiState.LOADING;
  stylePresetId: StylePresetId = StylePresetId.PAPER_INK;
  reminder: ReminderSettings = SettingsViewModel.cloneReminder(DEFAULT_APP_SETTINGS.reminder);
  errorMessage: string = '';

  private readonly settingsRepository: SettingsRepository;
  private readonly reminderScheduler: ReminderScheduler;
  private readonly resetService: AppResetService;

  constructor(
    settingsRepository: SettingsRepository,
    reminderScheduler: ReminderScheduler,
    resetService: AppResetService
  ) {
    this.settingsRepository = settingsRepository;
    this.reminderScheduler = reminderScheduler;
    this.resetService = resetService;
  }

  get isBusy(): boolean {
    return this.uiState === SettingsUiState.LOADING ||
      this.uiState === SettingsUiState.REMINDER_REQUESTING_PERMISSION ||
      this.uiState === SettingsUiState.CLEARING;
  }

  get reminderTimeLabel(): string {
    return `${this.padTwoDigits(this.reminder.hour)}:${this.padTwoDigits(this.reminder.minute)}`;
  }

  get reminderStatusMessage(): string {
    if (this.uiState === SettingsUiState.REMINDER_PERMISSION_DENIED) {
      return '通知尚未允许，日记功能不受影响';
    }
    if (this.uiState === SettingsUiState.REMINDER_DISABLED_BY_SYSTEM) {
      return '系统通知已关闭，当前不会提醒';
    }
    if (this.uiState === SettingsUiState.REMINDER_SCHEDULE_ERROR) {
      return '提醒尚未生效，请重试或稍后再试';
    }
    if (this.reminder.enabled) {
      return '每天固定提醒，已记录后仍会出现';
    }
    return '仅在你主动开启后申请通知权限';
  }

  async load(): Promise<void> {
    this.uiState = SettingsUiState.LOADING;
    this.errorMessage = '';
    try {
      const settings = await this.settingsRepository.load();
      this.stylePresetId = settings.stylePresetId;
      this.syncPaperStorage(settings.stylePresetId);
      AppLogger.info(`style.settings_load preset=${settings.stylePresetId}`);
      this.reminder = SettingsViewModel.cloneReminder(settings.reminder);
      await this.refreshReminderState();
    } catch (error) {
      this.uiState = SettingsUiState.SAVE_ERROR;
      this.errorMessage = '设置暂时无法打开';
    }
  }

  async selectStyle(stylePresetId: StylePresetId): Promise<void> {
    if (this.isBusy || stylePresetId === this.stylePresetId) {
      return;
    }
    const previous = this.stylePresetId;
    this.stylePresetId = stylePresetId;
    try {
      await this.settingsRepository.saveStylePresetId(stylePresetId);
      this.syncPaperStorage(stylePresetId);
      AppLogger.info(`style.select id=${stylePresetId} save=ok`);
      await this.refreshReminderState();
    } catch (error) {
      AppLogger.error(`style.select id=${stylePresetId} save=fail`);
      this.stylePresetId = previous;
      this.syncPaperStorage(previous);
      this.uiState = SettingsUiState.SAVE_ERROR;
      this.errorMessage = '风格未能保存，请重试';
    }
  }

  private syncPaperStorage(stylePresetId: StylePresetId): void {
    AppStorage.setOrCreate('currentPaperId',
      stylePresetId === StylePresetId.PLAIN_ASH ? 'plain_ash_dev' : 'warm_paper_dev');
  }

  async enableReminder(): Promise<void> {
    if (this.isBusy) {
      return;
    }
    this.uiState = SettingsUiState.REMINDER_REQUESTING_PERMISSION;
    this.errorMessage = '';
    const attempted = this.withPermissionRequested(this.reminder);
    try {
      await this.settingsRepository.saveReminder(attempted);
      this.reminder = attempted;
      if (!await this.reminderScheduler.isNotificationEnabled()) {
        try {
          await this.reminderScheduler.requestNotificationPermission();
        } catch (error) {
          this.uiState = SettingsUiState.REMINDER_PERMISSION_DENIED;
          return;
        }
      }
      if (!await this.reminderScheduler.isNotificationEnabled()) {
        this.uiState = SettingsUiState.REMINDER_PERMISSION_DENIED;
        return;
      }
      if (this.reminder.enabled && this.reminder.reminderId >= 0 &&
        await this.reminderScheduler.hasValidReminder()) {
        this.uiState = SettingsUiState.READY;
        return;
      }
      await this.publishAndSave(this.reminder.hour, this.reminder.minute);
    } catch (error) {
      const pending: ReminderSettings = {
        enabled: true,
        hour: this.reminder.hour,
        minute: this.reminder.minute,
        reminderId: -1,
        permissionRequested: true
      };
      try {
        await this.settingsRepository.saveReminder(pending);
        this.reminder = pending;
      } catch (saveError) {
      }
      this.uiState = SettingsUiState.REMINDER_SCHEDULE_ERROR;
      this.errorMessage = '系统暂时无法创建提醒';
    }
  }

  async disableReminder(): Promise<void> {
    if (this.isBusy || !this.reminder.enabled) {
      return;
    }
    const previous = SettingsViewModel.cloneReminder(this.reminder);
    try {
      await this.reminderScheduler.cancelAll();
      const disabled: ReminderSettings = {
        enabled: false,
        hour: previous.hour,
        minute: previous.minute,
        reminderId: -1,
        permissionRequested: previous.permissionRequested
      };
      await this.settingsRepository.saveReminder(disabled);
      this.reminder = disabled;
      this.uiState = SettingsUiState.READY;
      this.errorMessage = '';
    } catch (error) {
      this.reminder = previous;
      this.uiState = SettingsUiState.REMINDER_SCHEDULE_ERROR;
      this.errorMessage = '提醒未能关闭，请重试';
    }
  }

  async changeReminderTime(hour: number, minute: number): Promise<void> {
    if (this.isBusy || hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return;
    }
    const previous = SettingsViewModel.cloneReminder(this.reminder);
    if (!previous.enabled) {
      const changed = this.withTime(previous, hour, minute);
      try {
        await this.settingsRepository.saveReminder(changed);
        this.reminder = changed;
        this.uiState = SettingsUiState.READY;
      } catch (error) {
        this.uiState = SettingsUiState.SAVE_ERROR;
        this.errorMessage = '提醒时间未能保存';
      }
      return;
    }

    let newReminderId: number = -1;
    try {
      if (!await this.reminderScheduler.isNotificationEnabled()) {
        const changed = this.withTime(previous, hour, minute);
        await this.settingsRepository.saveReminder(changed);
        this.reminder = changed;
        this.uiState = SettingsUiState.REMINDER_DISABLED_BY_SYSTEM;
        return;
      }
      newReminderId = await this.reminderScheduler.publishDaily(hour, minute);
      await this.reminderScheduler.cancel(previous.reminderId);
      const changed: ReminderSettings = {
        enabled: true,
        hour: hour,
        minute: minute,
        reminderId: newReminderId,
        permissionRequested: true
      };
      await this.settingsRepository.saveReminder(changed);
      this.reminder = changed;
      this.uiState = SettingsUiState.READY;
      this.errorMessage = '';
    } catch (error) {
      if (newReminderId >= 0) {
        try {
          await this.reminderScheduler.cancel(newReminderId);
        } catch (cancelError) {
        }
      }
      this.reminder = previous;
      this.uiState = SettingsUiState.REMINDER_SCHEDULE_ERROR;
      this.errorMessage = '提醒时间未能更新';
    }
  }

  async retryReminder(): Promise<void> {
    if (this.isBusy) {
      return;
    }
    if (!this.reminder.enabled || this.reminder.reminderId < 0) {
      await this.enableReminder();
      return;
    }
    await this.refreshReminderState();
  }

  async clearAll(): Promise<boolean> {
    if (this.isBusy) {
      return false;
    }
    this.uiState = SettingsUiState.CLEARING;
    this.errorMessage = '';
    try {
      await this.resetService.clearAll();
      this.stylePresetId = StylePresetId.PAPER_INK;
      this.reminder = SettingsViewModel.cloneReminder(DEFAULT_APP_SETTINGS.reminder);
      this.uiState = SettingsUiState.READY;
      return true;
    } catch (error) {
      this.uiState = SettingsUiState.CLEAR_ERROR;
      this.errorMessage = '清空尚未完成，可安全重试';
      return false;
    }
  }

  private async publishAndSave(hour: number, minute: number): Promise<void> {
    const reminderId = await this.reminderScheduler.publishDaily(hour, minute);
    const enabled: ReminderSettings = {
      enabled: true,
      hour: hour,
      minute: minute,
      reminderId: reminderId,
      permissionRequested: true
    };
    try {
      await this.settingsRepository.saveReminder(enabled);
      this.reminder = enabled;
      this.uiState = SettingsUiState.READY;
      this.errorMessage = '';
    } catch (error) {
      await this.reminderScheduler.cancel(reminderId);
      throw new Error('reminder settings persistence failed');
    }
  }

  private async refreshReminderState(): Promise<void> {
    if (!this.reminder.enabled) {
      this.uiState = SettingsUiState.READY;
      this.errorMessage = '';
      return;
    }
    if (!await this.reminderScheduler.isNotificationEnabled()) {
      this.uiState = SettingsUiState.REMINDER_DISABLED_BY_SYSTEM;
      return;
    }
    if (!await this.reminderScheduler.hasValidReminder()) {
      this.uiState = SettingsUiState.REMINDER_SCHEDULE_ERROR;
      return;
    }
    this.uiState = SettingsUiState.READY;
    this.errorMessage = '';
  }

  private withPermissionRequested(reminder: ReminderSettings): ReminderSettings {
    return {
      enabled: reminder.enabled,
      hour: reminder.hour,
      minute: reminder.minute,
      reminderId: reminder.reminderId,
      permissionRequested: true
    };
  }

  private withTime(reminder: ReminderSettings, hour: number, minute: number): ReminderSettings {
    return {
      enabled: reminder.enabled,
      hour: hour,
      minute: minute,
      reminderId: reminder.reminderId,
      permissionRequested: reminder.permissionRequested
    };
  }

  private padTwoDigits(value: number): string {
    return value < 10 ? `0${value}` : `${value}`;
  }

  private static cloneReminder(reminder: ReminderSettings): ReminderSettings {
    return {
      enabled: reminder.enabled,
      hour: reminder.hour,
      minute: reminder.minute,
      reminderId: reminder.reminderId,
      permissionRequested: reminder.permissionRequested
    };
  }
}
