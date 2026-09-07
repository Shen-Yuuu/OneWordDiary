import { buffer } from '@kit.ArkTS';
import { StylePresetId } from '../constants/StyleTokens';
import { BackgroundImageBackupData } from '../model/BackgroundImage';
import { BackupDocument, BackupRecordPayload, DecodedBackup } from '../model/BackupModel';
import { BackupError, BackupErrorCode } from '../model/BackupError';
import { DailyRecord, DiaryEntryInput, NormalizedDiaryEntry, RecordType } from '../model/DailyRecord';
import { DiaryTextRules } from './DiaryTextRules';

export class BackupCodec {
  static readonly FORMAT_VERSION: number = 2;
  static readonly LEGACY_FORMAT_VERSION: number = 1;
  static readonly MAX_FILE_BYTES: number = 64 * 1024 * 1024;
  static readonly MAX_TEXT_ONLY_FILE_BYTES: number = 5 * 1024 * 1024;
  static readonly MAX_IMAGE_BYTES: number = 5 * 1024 * 1024;
  static readonly MAX_RECORDS: number = 10000;

  private readonly textRules: DiaryTextRules;

  constructor(textRules: DiaryTextRules) {
    this.textRules = textRules;
  }

  encode(
    records: DailyRecord[],
    stylePresetId: StylePresetId,
    exportedAt: number,
    imagesByDate: Map<string, BackgroundImageBackupData> = new Map<string, BackgroundImageBackupData>()
  ): string {
    if (records.length > BackupCodec.MAX_RECORDS) {
      throw new BackupError(BackupErrorCode.TOO_MANY_RECORDS, '记录数量超过备份上限');
    }
    const hasImages = records.some((record: DailyRecord): boolean => {
      return record.backgroundImageId !== null && record.backgroundImageId !== undefined;
    });
    const payloads: BackupRecordPayload[] = records.map((record: DailyRecord): BackupRecordPayload => {
      return this.toPayload(record, hasImages, imagesByDate);
    });
    const document: BackupDocument = {
      format_version: hasImages ? BackupCodec.FORMAT_VERSION : BackupCodec.LEGACY_FORMAT_VERSION,
      exported_at: exportedAt,
      style_preset_id: stylePresetId,
      records: payloads
    };
    const text = JSON.stringify(document);
    const maxBytes = hasImages ? BackupCodec.MAX_FILE_BYTES : BackupCodec.MAX_TEXT_ONLY_FILE_BYTES;
    if (buffer.byteLength(text, 'utf8') > maxBytes) {
      throw new BackupError(BackupErrorCode.FILE_TOO_LARGE,
        hasImages ? '含图片的备份不能超过 64 MiB' : '纯文字备份不能超过 5 MiB');
    }
    return text;
  }

  decode(text: string): DecodedBackup {
    const textBytes = buffer.byteLength(text, 'utf8');
    if (textBytes > BackupCodec.MAX_FILE_BYTES) {
      throw new BackupError(BackupErrorCode.FILE_TOO_LARGE, '备份文件不能超过 64 MiB');
    }
    let document: BackupDocument;
    try {
      document = JSON.parse(text);
    } catch (error) {
      throw new BackupError(BackupErrorCode.INVALID_JSON, '备份文件不是有效 JSON');
    }
    this.validateDocument(document, textBytes);
    const seenDates: Set<string> = new Set<string>();
    const records: DailyRecord[] = [];
    const imagesByDate = new Map<string, BackgroundImageBackupData>();
    for (let index = 0; index < document.records.length; index++) {
      const payload = document.records[index];
      const record = this.fromPayload(payload);
      if (seenDates.has(record.localDate)) {
        throw new BackupError(BackupErrorCode.DUPLICATE_DATE, '备份中存在重复日期');
      }
      seenDates.add(record.localDate);
      if (document.format_version === BackupCodec.FORMAT_VERSION) {
        if (payload.background_image === undefined) {
          throw new BackupError(BackupErrorCode.INVALID_RECORD, '备份记录缺少背景图片字段');
        }
        if (payload.background_image !== null) {
          imagesByDate.set(record.localDate, this.validateImage(payload.background_image));
        }
      }
      records.push(record);
    }
    records.sort((left: DailyRecord, right: DailyRecord): number => {
      return right.localDate.localeCompare(left.localDate);
    });
    return {
      records: records,
      stylePresetId: this.parseStyle(document.style_preset_id),
      imagesByDate: imagesByDate
    };
  }

  private validateDocument(document: BackupDocument, textBytes: number): void {
    if (document === null || typeof document !== 'object' ||
      typeof document.format_version !== 'number' ||
      typeof document.exported_at !== 'number' ||
      typeof document.style_preset_id !== 'string' ||
      !Array.isArray(document.records)) {
      throw new BackupError(BackupErrorCode.INVALID_FORMAT, '备份文件结构不完整');
    }
    if (document.format_version !== BackupCodec.LEGACY_FORMAT_VERSION &&
      document.format_version !== BackupCodec.FORMAT_VERSION) {
      throw new BackupError(BackupErrorCode.UNSUPPORTED_VERSION, '当前版本无法读取此备份');
    }
    if (document.format_version === BackupCodec.LEGACY_FORMAT_VERSION &&
      textBytes > BackupCodec.MAX_TEXT_ONLY_FILE_BYTES) {
      throw new BackupError(BackupErrorCode.FILE_TOO_LARGE, '纯文字备份不能超过 5 MiB');
    }
    if (!Number.isSafeInteger(document.exported_at) || document.exported_at < 0) {
      throw new BackupError(BackupErrorCode.INVALID_FORMAT, '备份导出时间无效');
    }
    this.parseStyle(document.style_preset_id);
    if (document.records.length > BackupCodec.MAX_RECORDS) {
      throw new BackupError(BackupErrorCode.TOO_MANY_RECORDS, '备份中的记录过多');
    }
  }

  private validateImage(value: BackgroundImageBackupData): BackgroundImageBackupData {
    if (value === null || typeof value !== 'object' ||
      (value.mimeType !== 'image/jpeg' && value.mimeType !== 'image/png') ||
      typeof value.byteLength !== 'number' || !Number.isSafeInteger(value.byteLength) ||
      value.byteLength <= 0 || value.byteLength > BackupCodec.MAX_IMAGE_BYTES ||
      typeof value.dataBase64 !== 'string' || value.dataBase64.length === 0 ||
      value.dataBase64.length % 4 !== 0 ||
      value.dataBase64.length > Math.ceil(BackupCodec.MAX_IMAGE_BYTES / 3) * 4 ||
      !/^[A-Za-z0-9+/]*={0,2}$/.test(value.dataBase64)) {
      throw new BackupError(BackupErrorCode.INVALID_IMAGE, '备份包含无效背景图片');
    }
    const padding = value.dataBase64.endsWith('==') ? 2 : value.dataBase64.endsWith('=') ? 1 : 0;
    if (value.dataBase64.length / 4 * 3 - padding !== value.byteLength) {
      throw new BackupError(BackupErrorCode.INVALID_IMAGE, '备份背景图片长度不一致');
    }
    return {
      mimeType: value.mimeType,
      byteLength: value.byteLength,
      dataBase64: value.dataBase64
    };
  }

  private fromPayload(payload: BackupRecordPayload): DailyRecord {
    if (payload === null || typeof payload !== 'object' ||
      typeof payload.local_date !== 'string' ||
      (typeof payload.content !== 'string' && payload.content !== null) ||
      (typeof payload.note !== 'string' && payload.note !== null) ||
      typeof payload.record_type !== 'string' ||
      typeof payload.font_id !== 'string' ||
      typeof payload.paper_id !== 'string' ||
      typeof payload.submitted_at !== 'number' ||
      typeof payload.submitted_timezone_offset !== 'number' ||
      typeof payload.revision_deadline_at !== 'number' ||
      (typeof payload.revised_at !== 'number' && payload.revised_at !== null) ||
      typeof payload.revision_used !== 'boolean' ||
      typeof payload.schema_version !== 'number') {
      throw new BackupError(BackupErrorCode.INVALID_RECORD, '备份包含字段不完整的记录');
    }
    this.validateDate(payload.local_date);
    this.validateInteger(payload.submitted_at);
    this.validateInteger(payload.submitted_timezone_offset);
    this.validateInteger(payload.revision_deadline_at);
    this.validateInteger(payload.schema_version);
    if (payload.revised_at !== null) this.validateInteger(payload.revised_at);
    if (payload.submitted_at < 0 || payload.revision_deadline_at < payload.submitted_at ||
      payload.submitted_timezone_offset < -840 || payload.submitted_timezone_offset > 840 ||
      payload.schema_version !== 1) {
      throw new BackupError(BackupErrorCode.INVALID_RECORD, '备份包含无效时间或数据版本');
    }
    if (payload.revision_used !== (payload.revised_at !== null) ||
      (payload.revised_at !== null && payload.revised_at < payload.submitted_at)) {
      throw new BackupError(BackupErrorCode.INVALID_RECORD, '备份包含无效修订状态');
    }
    const recordType = this.parseRecordType(payload.record_type);
    const entry: DiaryEntryInput = {
      recordType: recordType,
      content: payload.content,
      note: payload.note,
      fontId: payload.font_id,
      paperId: payload.paper_id,
      backgroundImageId: null
    };
    let normalized: NormalizedDiaryEntry;
    try {
      normalized = this.textRules.normalizeEntry(entry);
    } catch (error) {
      throw new BackupError(BackupErrorCode.INVALID_RECORD, '备份包含不符合规则的正文或备注');
    }
    if (normalized.content !== payload.content || normalized.note !== payload.note ||
      normalized.recordType !== recordType) {
      throw new BackupError(BackupErrorCode.INVALID_RECORD, '备份记录未使用规范化文本');
    }
    this.validateRecordStyle(payload.font_id, payload.paper_id);
    return {
      localDate: payload.local_date,
      content: payload.content,
      note: payload.note,
      recordType: recordType,
      fontId: payload.font_id,
      paperId: payload.paper_id,
      backgroundImageId: null,
      submittedAt: payload.submitted_at,
      submittedTimezoneOffset: payload.submitted_timezone_offset,
      revisionDeadlineAt: payload.revision_deadline_at,
      revisedAt: payload.revised_at,
      revisionUsed: payload.revision_used,
      schemaVersion: payload.schema_version
    };
  }

  private toPayload(
    record: DailyRecord,
    includeImageField: boolean,
    imagesByDate: Map<string, BackgroundImageBackupData>
  ): BackupRecordPayload {
    const payload: BackupRecordPayload = {
      local_date: record.localDate,
      content: record.content,
      note: record.note,
      record_type: record.recordType,
      font_id: record.fontId,
      paper_id: record.paperId,
      submitted_at: record.submittedAt,
      submitted_timezone_offset: record.submittedTimezoneOffset,
      revision_deadline_at: record.revisionDeadlineAt,
      revised_at: record.revisedAt,
      revision_used: record.revisionUsed,
      schema_version: record.schemaVersion
    };
    if (includeImageField) {
      if (record.backgroundImageId !== null && record.backgroundImageId !== undefined) {
        const imageData = imagesByDate.get(record.localDate);
        if (imageData === undefined) {
          throw new BackupError(BackupErrorCode.IMAGE_MISSING,
            '日记背景图片缺失或已损坏，无法完整备份');
        }
        payload.background_image = imageData;
      } else {
        payload.background_image = null;
      }
    }
    return payload;
  }

  private parseStyle(value: string): StylePresetId {
    if (value === StylePresetId.PAPER_INK) return StylePresetId.PAPER_INK;
    if (value === StylePresetId.PLAIN_ASH) return StylePresetId.PLAIN_ASH;
    throw new BackupError(BackupErrorCode.INVALID_FORMAT, '备份包含未知风格');
  }

  private parseRecordType(value: string): RecordType {
    if (value === RecordType.WORD) return RecordType.WORD;
    if (value === RecordType.BLANK) return RecordType.BLANK;
    throw new BackupError(BackupErrorCode.INVALID_RECORD, '备份包含未知记录类型');
  }

  private validateRecordStyle(fontId: string, paperId: string): void {
    const paperInk = fontId === 'system_serif_dev' && paperId === 'warm_paper_dev';
    const plainAsh = fontId === 'system_sans_dev' && paperId === 'plain_ash_dev';
    if (!paperInk && !plainAsh) {
      throw new BackupError(BackupErrorCode.INVALID_RECORD, '备份包含未知历史风格');
    }
  }

  private validateDate(localDate: string): void {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(localDate)) {
      throw new BackupError(BackupErrorCode.INVALID_RECORD, '备份包含非法日期');
    }
    const year = Number(localDate.substring(0, 4));
    const month = Number(localDate.substring(5, 7));
    const day = Number(localDate.substring(8, 10));
    const date = new Date(year, month - 1, day, 12, 0, 0, 0);
    if (date.getFullYear() !== year || date.getMonth() + 1 !== month || date.getDate() !== day) {
      throw new BackupError(BackupErrorCode.INVALID_RECORD, '备份包含不存在的日期');
    }
  }

  private validateInteger(value: number): void {
    if (!Number.isSafeInteger(value)) {
      throw new BackupError(BackupErrorCode.INVALID_RECORD, '备份包含无效数字字段');
    }
  }
}
