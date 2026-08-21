import { common } from '@kit.AbilityKit';
import { reminderAgentManager } from '@kit.BackgroundTasksKit';
import { notificationManager } from '@kit.NotificationKit';

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
    return notificationManager.isNotificationEnabledSync();
  }

  async requestNotificationPermission(): Promise<void> {
    await notificationManager.requestEnableNotification(this.context);
  }

  async publishDaily(hour: number, minute: number): Promise<number> {
    const request: reminderAgentManager.ReminderRequestAlarm = {
      reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_ALARM,
      hour: hour,
      minute: minute,
      daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
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
    return reminderAgentManager.publishReminder(request);
  }

  async cancel(reminderId: number): Promise<void> {
    if (reminderId >= 0) {
      await reminderAgentManager.cancelReminder(reminderId);
    }
  }

  async cancelAll(): Promise<void> {
    await reminderAgentManager.cancelAllReminders();
  }

  async hasValidReminder(): Promise<boolean> {
    const reminders = await reminderAgentManager.getValidReminders();
    return reminders.length > 0;
  }
}
