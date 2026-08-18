import { RecordType } from './DailyRecord';

export enum ScrollItemSide {
  LEFT = 'LEFT',
  RIGHT = 'RIGHT',
  CENTER = 'CENTER'
}

export class ScrollDisplayItem {
  readonly localDate: string;
  readonly monthKey: string;
  readonly monthLabel: string;
  readonly showMonthHeader: boolean;
  readonly dayLabel: string;
  readonly weekdayLabel: string;
  readonly recordType: RecordType;
  readonly content: string;
  readonly contentCount: number;
  readonly fontId: string;
  readonly paperId: string;
  readonly side: ScrollItemSide;

  constructor(
    localDate: string,
    monthKey: string,
    monthLabel: string,
    showMonthHeader: boolean,
    dayLabel: string,
    weekdayLabel: string,
    recordType: RecordType,
    content: string,
    contentCount: number,
    fontId: string,
    paperId: string,
    side: ScrollItemSide
  ) {
    this.localDate = localDate;
    this.monthKey = monthKey;
    this.monthLabel = monthLabel;
    this.showMonthHeader = showMonthHeader;
    this.dayLabel = dayLabel;
    this.weekdayLabel = weekdayLabel;
    this.recordType = recordType;
    this.content = content;
    this.contentCount = contentCount;
    this.fontId = fontId;
    this.paperId = paperId;
    this.side = side;
  }
}
