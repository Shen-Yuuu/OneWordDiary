export enum AppErrorCode {
  INITIALIZATION_FAILED = 'initialization_failed',
  STORAGE_UNAVAILABLE = 'storage_unavailable',
  UNEXPECTED = 'unexpected'
}

export class AppError extends Error {
  readonly code: AppErrorCode;

  constructor(code: AppErrorCode, message: string) {
    super(message);
    this.name = 'AppError';
    this.code = code;
  }
}
