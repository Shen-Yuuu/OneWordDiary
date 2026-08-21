export class DiaryDateFormatter {
  private readonly weekdays: string[] = [
    '星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六'
  ];
  private readonly chineseDigits: string[] = ['〇', '一', '二', '三', '四', '五', '六', '七', '八', '九'];
  private readonly chineseMonths: string[] = [
    '', '一', '二', '三', '四', '五', '六', '七', '八', '九', '十', '十一', '十二'
  ];

  monthKey(localDate: string): string {
    return localDate.substring(0, 7);
  }

  monthLabel(localDate: string): string {
    const yearText = localDate.substring(0, 4);
    const month = Number(localDate.substring(5, 7));
    let chineseYear = '';
    for (let index = 0; index < yearText.length; index++) {
      chineseYear += this.chineseDigits[Number(yearText.charAt(index))];
    }
    return `${chineseYear}年${this.chineseMonths[month]}月`;
  }

  dayLabel(localDate: string): string {
    return `${Number(localDate.substring(8, 10))}日`;
  }

  weekdayLabel(localDate: string): string {
    const year = Number(localDate.substring(0, 4));
    const month = Number(localDate.substring(5, 7));
    const day = Number(localDate.substring(8, 10));
    return this.weekdays[new Date(year, month - 1, day).getDay()];
  }

  detailLabel(localDate: string): string {
    return `${Number(localDate.substring(5, 7))}月${Number(localDate.substring(8, 10))}日 ` +
      this.weekdayLabel(localDate);
  }

  compactLabel(localDate: string): string {
    return localDate.replace(/-/g, '.');
  }

  shiftDays(localDate: string, offset: number): string {
    const year = Number(localDate.substring(0, 4));
    const month = Number(localDate.substring(5, 7));
    const day = Number(localDate.substring(8, 10));
    const shifted = new Date(year, month - 1, day + offset, 12, 0, 0, 0);
    return `${shifted.getFullYear()}-${this.padTwoDigits(shifted.getMonth() + 1)}-` +
      `${this.padTwoDigits(shifted.getDate())}`;
  }

  recentDates(anchorDate: string, days: number): string[] {
    const dates: string[] = [];
    for (let offset = 0; offset < days; offset++) {
      dates.push(this.shiftDays(anchorDate, -offset));
    }
    return dates;
  }

  private padTwoDigits(value: number): string {
    return value < 10 ? `0${value}` : value.toString();
  }
}
