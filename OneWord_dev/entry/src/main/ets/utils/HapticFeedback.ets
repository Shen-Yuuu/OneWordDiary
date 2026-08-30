import { vibrator } from '@kit.SensorServiceKit';

/**
 * 落字等关键仪式时刻的轻振动反馈。
 * 振动失败时静默降级（无马达设备/触感开关关闭），不影响界面流程。
 */
export class HapticFeedback {
  static inkDrop(): void {
    try {
      vibrator.startVibration({ type: 'time', duration: 18 }, { usage: 'touch' });
    } catch (err) {
      // 静默：振动属增强体验，失败不影响落字流程
    }
  }

  private constructor() {
  }
}
