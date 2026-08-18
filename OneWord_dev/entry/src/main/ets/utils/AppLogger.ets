import { hilog } from '@kit.PerformanceAnalysisKit';

const LOG_DOMAIN: number = 0x4F57;
const LOG_TAG: string = 'OneWord';

export class AppLogger {
  static info(event: string): void {
    hilog.info(LOG_DOMAIN, LOG_TAG, '%{public}s', event);
  }

  static warn(event: string): void {
    hilog.warn(LOG_DOMAIN, LOG_TAG, '%{public}s', event);
  }

  static error(event: string): void {
    hilog.error(LOG_DOMAIN, LOG_TAG, '%{public}s', event);
  }

  private constructor() {
  }
}
