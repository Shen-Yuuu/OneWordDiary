export enum DiaryErrorCode {
  CONTENT_REQUIRED = 'content_required',
  CONTENT_TOO_LONG = 'content_too_long',
  CONTENT_HAS_LINE_BREAK = 'content_has_line_break',
  NOTE_TOO_LONG = 'note_too_long',
  NOTE_HAS_LINE_BREAK = 'note_has_line_break',
  STYLE_REQUIRED = 'style_required',
  ALREADY_RECORDED = 'already_recorded',
  RECORD_NOT_FOUND = 'record_not_found',
  REVISION_USED = 'revision_used',
  REVISION_EXPIRED = 'revision_expired',
  REVISION_CONFLICT = 'revision_conflict',
  STORAGE_FAILED = 'storage_failed'
}

export class DiaryError extends Error {
  readonly code: DiaryErrorCode;

  constructor(code: DiaryErrorCode, message: string) {
    super(message);
    this.name = 'DiaryError';
    this.code = code;
  }
}
