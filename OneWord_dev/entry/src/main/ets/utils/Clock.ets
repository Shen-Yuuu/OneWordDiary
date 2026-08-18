export interface Clock {
  now(): number;
}

export class SystemClock implements Clock {
  now(): number {
    return Date.now();
  }
}

export class FixedClock implements Clock {
  private currentTime: number;

  constructor(currentTime: number) {
    this.currentTime = currentTime;
  }

  now(): number {
    return this.currentTime;
  }

  setTime(currentTime: number): void {
    this.currentTime = currentTime;
  }
}
