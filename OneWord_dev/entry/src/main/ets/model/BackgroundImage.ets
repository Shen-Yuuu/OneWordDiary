export interface BackgroundImageStore {
  importFromUri(uri: string): Promise<string>;
  resolveUri(id: string | null | undefined): string;
  remove(id: string): void;
  clearAll(): void;
 }

export interface BackgroundImageBackupData {
  mimeType: string;
  byteLength: number;
  dataBase64: string;
}

export interface BackgroundImageBackupStore extends BackgroundImageStore {
  readForBackup(id: string): Promise<BackgroundImageBackupData>;
  importFromBackup(data: BackgroundImageBackupData): Promise<string>;
  removeMany(ids: string[]): void;
  cleanupOrphans(referencedIds: Set<string>): void;
}

export enum BackgroundImageErrorCode {
  INVALID_IMAGE = 'INVALID_IMAGE',
  ANIMATED_IMAGE = 'ANIMATED_IMAGE',
  SOURCE_TOO_LARGE = 'SOURCE_TOO_LARGE',
  DIMENSIONS_TOO_LARGE = 'DIMENSIONS_TOO_LARGE',
  OUTPUT_TOO_LARGE = 'OUTPUT_TOO_LARGE',
  STORAGE_FAILED = 'STORAGE_FAILED'
}

export class BackgroundImageError extends Error {
  readonly code: BackgroundImageErrorCode;

  constructor(code: BackgroundImageErrorCode, message: string) {
    super(message);
    this.name = 'BackgroundImageError';
    this.code = code;
  }
}

export function isValidBackgroundImageId(id: string | null | undefined): boolean {
  if (id === null || id === undefined) {
    return false;
  }
  return /^[0-9a-f]{32}\.(jpg|png)$/.test(id);
}
