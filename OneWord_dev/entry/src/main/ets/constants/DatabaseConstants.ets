export class DatabaseConstants {
  static readonly DATABASE_NAME: string = 'oneword.db';
  static readonly DATABASE_VERSION: number = 1;
  static readonly TABLE_DAILY_RECORD: string = 'daily_record';

  static readonly COLUMN_LOCAL_DATE: string = 'local_date';
  static readonly COLUMN_CONTENT: string = 'content';
  static readonly COLUMN_NOTE: string = 'note';
  static readonly COLUMN_RECORD_TYPE: string = 'record_type';
  static readonly COLUMN_FONT_ID: string = 'font_id';
  static readonly COLUMN_PAPER_ID: string = 'paper_id';
  static readonly COLUMN_SUBMITTED_AT: string = 'submitted_at';
  static readonly COLUMN_SUBMITTED_TIMEZONE_OFFSET: string = 'submitted_tz_offset';
  static readonly COLUMN_REVISION_DEADLINE_AT: string = 'revision_deadline_at';
  static readonly COLUMN_REVISED_AT: string = 'revised_at';
  static readonly COLUMN_REVISION_USED: string = 'revision_used';
  static readonly COLUMN_SCHEMA_VERSION: string = 'schema_version';

  static readonly CREATE_DAILY_RECORD_TABLE: string =
    'CREATE TABLE IF NOT EXISTS daily_record (' +
    'local_date TEXT PRIMARY KEY, ' +
    'content TEXT, ' +
    'note TEXT, ' +
    "record_type TEXT NOT NULL CHECK(record_type IN ('WORD', 'BLANK')), " +
    'font_id TEXT NOT NULL, ' +
    'paper_id TEXT NOT NULL, ' +
    'submitted_at INTEGER NOT NULL, ' +
    'submitted_tz_offset INTEGER NOT NULL, ' +
    'revision_deadline_at INTEGER NOT NULL, ' +
    'revised_at INTEGER, ' +
    'revision_used INTEGER NOT NULL DEFAULT 0 CHECK(revision_used IN (0, 1)), ' +
    'schema_version INTEGER NOT NULL DEFAULT 1' +
    ')';

  static readonly CREATE_SUBMITTED_AT_INDEX: string =
    'CREATE INDEX IF NOT EXISTS idx_daily_record_submitted_at ON daily_record(submitted_at DESC)';
}
