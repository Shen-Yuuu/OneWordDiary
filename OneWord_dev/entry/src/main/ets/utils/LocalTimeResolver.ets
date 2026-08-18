export interface LocalTimeSnapshot {
  localDate: string;
  timezoneOffsetMinutes: number;
  revisionDeadlineAt: number;
}

export interface LocalTimeResolver {
  resolve(timestamp: number): LocalTimeSnapshot;
}

export class SystemLocalTimeResolver implements LocalTimeResolver {
  resolve(timestamp: number): LocalTimeSnapshot {
    const current: Date = new Date(timestamp);
    const nextMidnight: Date = new Date(
      current.getFullYear(),
      current.getMonth(),
      current.getDate() + 1,
      0,
      0,
      0,
      0
    );

    return {
      localDate: this.formatDate(current.getFullYear(), current.getMonth() + 1, current.getDate()),
      timezoneOffsetMinutes: -current.getTimezoneOffset(),
      revisionDeadlineAt: nextMidnight.getTime() - 1
    };
  }

  private formatDate(year: number, month: number, day: number): string {
    return `${year}-${this.padTwoDigits(month)}-${this.padTwoDigits(day)}`;
  }

  private padTwoDigits(value: number): string {
    return value < 10 ? `0${value}` : value.toString();
  }
}

export class FixedLocalTimeResolver implements LocalTimeResolver {
  private snapshot: LocalTimeSnapshot;

  constructor(snapshot: LocalTimeSnapshot) {
    this.snapshot = snapshot;
  }

  resolve(timestamp: number): LocalTimeSnapshot {
    return {
      localDate: this.snapshot.localDate,
      timezoneOffsetMinutes: this.snapshot.timezoneOffsetMinutes,
      revisionDeadlineAt: this.snapshot.revisionDeadlineAt
    };
  }

  setSnapshot(snapshot: LocalTimeSnapshot): void {
    this.snapshot = snapshot;
  }
}
