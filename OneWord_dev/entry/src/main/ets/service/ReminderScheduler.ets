import { common } from '@kit.AbilityKit';
import { reminderAgentManager } from '@kit.BackgroundTasksKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { notificationManager } from '@kit.NotificationKit';
import { AppLogger } from '../utils/AppLogger';

export interface ReminderScheduler {
  isNotificationEnabled(): Promise<boolean>;
  requestNotificationPermission(): Promise<void>;
  publishDaily(hour: number, minute: number): Promise<number>;
  cancel(reminderId: number): Promise<void>;
  cancelAll(): Promise<void>;
  hasValidReminder(): Promise<boolean>;
}

export class SystemReminderScheduler implements ReminderScheduler {
  private static readonly NOTIFICATION_ID: number = 41001;
  private readonly context: common.UIAbilityContext;

  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  async isNotificationEnabled(): Promise<boolean> {
    const enabled = notificationManager.isNotificationEnabledSync();
    AppLogger.info('reminder.notification_enabled value=' + enabled);
    return enabled;
  }

  async requestNotificationPermission(): Promise<void> {
    AppLogger.info('reminder.notification_permission request=start');
    try {
      await notificationManager.requestEnableNotification(this.context);
      AppLogger.info('reminder.notification_permission request=complete');
    } catch (error) {
      const businessError = error as BusinessError;
      AppLogger.error('reminder.notification_permission request=fail code=' + businessError.code);
      throw new Error('reminder notification_permission failed code=' + businessError.code);
    }
  }

  async publishDaily(hour: number, minute: number): Promise<number> {
    const request: reminderAgentManager.ReminderRequestAlarm = {
      reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_ALARM,
      hour: hour,
      minute: minute,
      daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
      ringDuration: 0,
      tapDismissed: false,
      wantAgent: {
        pkgName: 'com.oneword.diary',
        abilityName: 'EntryAbility'
      },
      title: '一字',
      content: '留一点时间，回望今天。',
      expiredContent: '今日已过，明日再见。',
      notificationId: SystemReminderScheduler.NOTIFICATION_ID,
      slotType: notificationManager.SlotType.CONTENT_INFORMATION
    };
    AppLogger.info('reminder.publish request hour=' + hour + ' minute=' + minute + ' notificationId=' + SystemReminderScheduler.NOTIFICATION_ID);
    try {
      const reminderId = await reminderAgentManager.publishReminder(request);
      AppLogger.info('reminder.publish success reminderId=' + reminderId);
      return reminderId;
    } catch (error) {
      const businessError = error as BusinessError;
      AppLogger.error('reminder.publish fail code=' + businessError.code);
      throw new Error('reminder publish failed code=' + businessError.code);
    }
  }

  async cancel(reminderId: number): Promise<void> {
    if (reminderId >= 0) {
      try {
        await reminderAgentManager.cancelReminder(reminderId);
        AppLogger.info('reminder.cancel success reminderId=' + reminderId);
      } catch (error) {
        const businessError = error as BusinessError;
        AppLogger.error('reminder.cancel fail reminderId=' + reminderId + ' code=' + businessError.code);
        throw new Error('reminder cancel failed code=' + businessError.code);
      }
      return;
    }
  }

  async cancelAll(): Promise<void> {
    try {
      await reminderAgentManager.cancelAllReminders();
      AppLogger.info('reminder.cancel_all success');
    } catch (error) {
      const businessError = error as BusinessError;
      AppLogger.error('reminder.cancel_all fail code=' + businessError.code);
      throw new Error('reminder cancel_all failed code=' + businessError.code);
    }
  }

  async hasValidReminder(): Promise<boolean> {
    try {
      const reminders = await reminderAgentManager.getValidReminders();
      AppLogger.info('reminder.valid_reminders count=' + reminders.length);
      return reminders.length > 0;
    } catch (error) {
      const businessError = error as BusinessError;
      AppLogger.error('reminder.valid_reminders fail code=' + businessError.code);
      throw new Error('reminder valid_reminders failed code=' + businessError.code);
    }
  }
}
