import { preferences } from '@kit.ArkData';
import { StylePresetId } from '../constants/StyleTokens';
import { AppSettings, DEFAULT_APP_SETTINGS, ReminderSettings } from '../model/Settings';

const SETTINGS_FILE: string = 'oneword_settings';
const KEY_STYLE_PRESET_ID: string = 'style_preset_id';
const KEY_REMINDER_ENABLED: string = 'reminder_enabled';
const KEY_REMINDER_HOUR: string = 'reminder_hour';
const KEY_REMINDER_MINUTE: string = 'reminder_minute';
const KEY_REMINDER_ID: string = 'reminder_id';
const KEY_PERMISSION_REQUESTED: string = 'reminder_permission_requested';
const KEY_RESET_PENDING: string = 'reset_pending';

export interface SettingsRepository {
  load(): Promise<AppSettings>;
  saveStylePresetId(stylePresetId: StylePresetId): Promise<void>;
  saveReminder(reminder: ReminderSettings): Promise<void>;
  isResetPending(): Promise<boolean>;
  markResetPending(): Promise<void>;
  reset(): Promise<void>;
}

export class PreferencesSettingsRepository implements SettingsRepository {
  private readonly store: preferences.Preferences;

  private constructor(store: preferences.Preferences) {
    this.store = store;
  }

  static async create(context: Context): Promise<PreferencesSettingsRepository> {
    const store = await preferences.getPreferences(context, SETTINGS_FILE);
    return new PreferencesSettingsRepository(store);
  }

  async load(): Promise<AppSettings> {
    const styleValue = await this.store.get(KEY_STYLE_PRESET_ID, DEFAULT_APP_SETTINGS.stylePresetId);
    const enabledValue = await this.store.get(KEY_REMINDER_ENABLED, DEFAULT_APP_SETTINGS.reminder.enabled);
    const hourValue = await this.store.get(KEY_REMINDER_HOUR, DEFAULT_APP_SETTINGS.reminder.hour);
    const minuteValue = await this.store.get(KEY_REMINDER_MINUTE, DEFAULT_APP_SETTINGS.reminder.minute);
    const reminderIdValue = await this.store.get(KEY_REMINDER_ID, DEFAULT_APP_SETTINGS.reminder.reminderId);
    const permissionRequestedValue = await this.store.get(
      KEY_PERMISSION_REQUESTED,
      DEFAULT_APP_SETTINGS.reminder.permissionRequested
    );

    const stylePresetId: StylePresetId = typeof styleValue === 'string' && this.isSupportedStyle(styleValue) ?
      this.toStylePresetId(styleValue) : DEFAULT_APP_SETTINGS.stylePresetId;
    const enabled = typeof enabledValue === 'boolean' ? enabledValue : DEFAULT_APP_SETTINGS.reminder.enabled;
    const hour = typeof hourValue === 'number' && hourValue >= 0 && hourValue <= 23 ?
      hourValue : DEFAULT_APP_SETTINGS.reminder.hour;
    const minute = typeof minuteValue === 'number' && minuteValue >= 0 && minuteValue <= 59 ?
      minuteValue : DEFAULT_APP_SETTINGS.reminder.minute;
    const reminderId = typeof reminderIdValue === 'number' ? reminderIdValue :
      DEFAULT_APP_SETTINGS.reminder.reminderId;
    const permissionRequested = typeof permissionRequestedValue === 'boolean' ? permissionRequestedValue :
      DEFAULT_APP_SETTINGS.reminder.permissionRequested;

    const settings: AppSettings = {
      stylePresetId: stylePresetId,
      reminder: {
        enabled: enabled,
        hour: hour,
        minute: minute,
        reminderId: reminderId,
        permissionRequested: permissionRequested
      }
    };
    return settings;
  }

  async saveStylePresetId(stylePresetId: StylePresetId): Promise<void> {
    if (!this.isSupportedStyle(stylePresetId)) {
      throw new Error('unsupported paper style');
    }
    await this.store.put(KEY_STYLE_PRESET_ID, stylePresetId);
    await this.store.flush();
  }

  async saveReminder(reminder: ReminderSettings): Promise<void> {
    if (reminder.hour < 0 || reminder.hour > 23 || reminder.minute < 0 || reminder.minute > 59) {
      throw new Error('invalid reminder time');
    }
    await this.store.put(KEY_REMINDER_ENABLED, reminder.enabled);
    await this.store.put(KEY_REMINDER_HOUR, reminder.hour);
    await this.store.put(KEY_REMINDER_MINUTE, reminder.minute);
    await this.store.put(KEY_REMINDER_ID, reminder.reminderId);
    await this.store.put(KEY_PERMISSION_REQUESTED, reminder.permissionRequested);
    await this.store.flush();
  }

  async isResetPending(): Promise<boolean> {
    const value = await this.store.get(KEY_RESET_PENDING, false);
    return typeof value === 'boolean' ? value : false;
  }

  async markResetPending(): Promise<void> {
    await this.store.put(KEY_RESET_PENDING, true);
    await this.store.flush();
  }

  async reset(): Promise<void> {
    await this.store.clear();
    await this.store.flush();
  }

  private isSupportedStyle(stylePresetId: string): boolean {
    return stylePresetId === StylePresetId.PAPER_INK || stylePresetId === StylePresetId.PLAIN_ASH;
  }

  private toStylePresetId(value: string): StylePresetId {
    return value === StylePresetId.PLAIN_ASH ? StylePresetId.PLAIN_ASH : StylePresetId.PAPER_INK;
  }
}