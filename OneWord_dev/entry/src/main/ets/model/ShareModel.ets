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

export function shouldShowShareDayNote(includeNote: boolean, kind: ShareDayKind): boolean {
  return includeNote && kind !== ShareDayKind.MISSING;
}

export function resolveShareNoteText(includeNote: boolean, kind: ShareDayKind, note: string): string {
  if (!includeNote || kind === ShareDayKind.MISSING) {
    return '';
  }
  return note.length > 0 ? note : '这条记录没有备注';
}

export interface ShareSingleData {
  localDate: string;
  recordType: RecordType;
  content: string;
  note: string;
  fontId: string;
  paperId: string;
}

export interface ShareDayItem {
  localDate: string;
  dateLabel: string;
  weekdayLabel: string;
  monthLabel: string;
  showMonthHeader: boolean;
  kind: ShareDayKind;
  content: string;
  note: string;
}
