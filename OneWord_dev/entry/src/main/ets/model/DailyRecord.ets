export enum RecordType {
  WORD = 'WORD',
  BLANK = 'BLANK'
}

export interface DailyRecord {
  localDate: string;
  content: string | null;
  note: string | null;
  recordType: RecordType;
  fontId: string;
  paperId: string;
  submittedAt: number;
  submittedTimezoneOffset: number;
  revisionDeadlineAt: number;
  revisedAt: number | null;
  revisionUsed: boolean;
  schemaVersion: number;
}

export interface DiaryEntryInput {
  recordType: RecordType;
  content: string | null;
  note: string | null;
  fontId: string;
  paperId: string;
}

export interface NormalizedDiaryEntry {
  recordType: RecordType;
  content: string | null;
  note: string | null;
  fontId: string;
  paperId: string;
}

export enum RevisionStatus {
  AVAILABLE = 'AVAILABLE',
  USED = 'USED',
  EXPIRED = 'EXPIRED'
}
