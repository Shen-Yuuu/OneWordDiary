import { vibrator } from '@kit.SensorServiceKit';

export interface CompletionFeedback {
  playRecordCommitted(): void;
}

export class NoopCompletionFeedback implements CompletionFeedback {
  playRecordCommitted(): void {
  }
}

export class SystemCompletionFeedback implements CompletionFeedback {
  playRecordCommitted(): void {
    vibrator.startVibration({
      type: 'preset',
      effectId: vibrator.HapticFeedback.EFFECT_SOFT,
      count: 1,
      intensity: 30
    }, {
      usage: 'touch'
    }).catch(() => {
      // A missing vibrator must never turn a successful diary write into an error.
    });
  }
}
