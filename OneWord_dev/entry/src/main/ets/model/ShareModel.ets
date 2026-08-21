import { RecordType } from './DailyRecord';

export enum DiaryShareMode {
  SINGLE = 'SINGLE',
  SEVEN_DAYS = 'SEVEN_DAYS'
}

export enum ShareDayKind {
  WORD = 'WORD',
  BLANK = 'BLANK',
  MISSING = 'MISSING'
}

export interface ShareSingleData {
  localDate: string;
  recordType: RecordType;
  content: string;
  fontId: string;
  paperId: string;
}

export interface ShareDayItem {
  localDate: string;
  dateLabel: string;
  weekdayLabel: string;
  kind: ShareDayKind;
  content: string;
}

