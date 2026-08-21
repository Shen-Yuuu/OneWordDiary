import { StylePresetId } from '../constants/StyleTokens';

export interface ReminderSettings {
  enabled: boolean;
  hour: number;
  minute: number;
  reminderId: number;
  permissionRequested: boolean;
}

export interface AppSettings {
  stylePresetId: StylePresetId;
  reminder: ReminderSettings;
}

export const DEFAULT_REMINDER_SETTINGS: ReminderSettings = {
  enabled: false,
  hour: 21,
  minute: 0,
  reminderId: -1,
  permissionRequested: false
};

export const DEFAULT_APP_SETTINGS: AppSettings = {
  stylePresetId: StylePresetId.PAPER_INK,
  reminder: DEFAULT_REMINDER_SETTINGS
};