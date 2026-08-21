import { StylePresetId } from '../constants/StyleTokens';
import { DailyRecord } from './DailyRecord';

export interface BackupRecordPayload {
  local_date: string;
  content: string | null;
  note: string | null;
  record_type: string;
  font_id: string;
  paper_id: string;
  submitted_at: number;
  submitted_timezone_offset: number;
  revision_deadline_at: number;
  revised_at: number | null;
  revision_used: boolean;
  schema_version: number;
}

export interface BackupDocument {
  format_version: number;
  exported_at: number;
  style_preset_id: string;
  records: BackupRecordPayload[];
}

export class BackupImportPlan {
  readonly records: DailyRecord[];
  readonly importedCount: number;
  readonly skippedCount: number;
  readonly restoreStyle: boolean;
  readonly backupStyle: StylePresetId;

  constructor(
    records: DailyRecord[],
    importedCount: number,
    skippedCount: number,
    restoreStyle: boolean,
    backupStyle: StylePresetId
  ) {
    this.records = records;
    this.importedCount = importedCount;
    this.skippedCount = skippedCount;
    this.restoreStyle = restoreStyle;
    this.backupStyle = backupStyle;
  }
}

export interface BackupImportResult {
  importedCount: number;
  skippedCount: number;
  styleRestored: boolean;
}

export interface DecodedBackup {
  records: DailyRecord[];
  stylePresetId: StylePresetId;
}

export enum BackupUiState {
  READY = 'READY',
  EXPORTING = 'EXPORTING',
  PREPARING_IMPORT = 'PREPARING_IMPORT',
  IMPORT_REVIEW = 'IMPORT_REVIEW',
  IMPORTING = 'IMPORTING',
  RESULT = 'RESULT',
  ERROR = 'ERROR'
}

