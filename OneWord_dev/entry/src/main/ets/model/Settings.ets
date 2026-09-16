import { StylePresetId } from '../constants/StyleTokens';
import { FontPresetId } from '../constants/FontCatalog';

export interface ReminderSettings {
  enabled: boolean;
  hour: number;
  minute: number;
  reminderId: number;
  permissionRequested: boolean;
}

export interface AppSettings {
  stylePresetId: StylePresetId;
  fontPresetId: FontPresetId;
  backgroundOpacity: number;
  reminder: ReminderSettings;
  privacyPolicyAcceptedVersion: string;
}

export const DEFAULT_BACKGROUND_OPACITY: number = 0.10;

export function normalizedBackgroundOpacity(value: number): number {
  if (!Number.isFinite(value)) {
    return DEFAULT_BACKGROUND_OPACITY;
  }
  return Math.max(0, Math.min(1, Math.round(value * 100) / 100));
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
  fontPresetId: FontPresetId.DEFAULT,
  backgroundOpacity: DEFAULT_BACKGROUND_OPACITY,
  reminder: DEFAULT_REMINDER_SETTINGS,
  privacyPolicyAcceptedVersion: ''
};
