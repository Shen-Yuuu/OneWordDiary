export enum BackupErrorCode {
  FILE_TOO_LARGE = 'FILE_TOO_LARGE',
  INVALID_JSON = 'INVALID_JSON',
  INVALID_FORMAT = 'INVALID_FORMAT',
  UNSUPPORTED_VERSION = 'UNSUPPORTED_VERSION',
  TOO_MANY_RECORDS = 'TOO_MANY_RECORDS',
  INVALID_RECORD = 'INVALID_RECORD',
  DUPLICATE_DATE = 'DUPLICATE_DATE',
  READ_FAILED = 'READ_FAILED',
  WRITE_FAILED = 'WRITE_FAILED',
  IMPORT_FAILED = 'IMPORT_FAILED'
}

export class BackupError extends Error {
  readonly code: BackupErrorCode;

  constructor(code: BackupErrorCode, message: string) {
    super(message);
    this.name = 'BackupError';
    this.code = code;
  }
}

