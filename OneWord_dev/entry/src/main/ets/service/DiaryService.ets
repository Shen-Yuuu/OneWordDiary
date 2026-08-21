import {
  DailyRecord,
  DiaryEntryInput,
  NormalizedDiaryEntry,
  RecordType,
  RevisionStatus
} from '../model/DailyRecord';
import { DiaryError, DiaryErrorCode } from '../model/DiaryError';
import { DiaryRepository } from '../repository/DiaryRepository';
import { Clock } from '../utils/Clock';
import { LocalTimeResolver, LocalTimeSnapshot } from '../utils/LocalTimeResolver';
import { DiaryTextRules } from './DiaryTextRules';

export class DiaryService {
  private static readonly CURRENT_SCHEMA_VERSION: number = 1;

  private readonly repository: DiaryRepository;
  private readonly clock: Clock;
  private readonly localTimeResolver: LocalTimeResolver;
  private readonly textRules: DiaryTextRules;
  private readonly submissionsInFlight: Set<string> = new Set<string>();
  private readonly revisionsInFlight: Set<string> = new Set<string>();

  constructor(
    repository: DiaryRepository,
    clock: Clock,
    localTimeResolver: LocalTimeResolver,
    textRules: DiaryTextRules
  ) {
    this.repository = repository;
    this.clock = clock;
    this.localTimeResolver = localTimeResolver;
    this.textRules = textRules;
  }

  async getToday(): Promise<DailyRecord | null> {
    const now = this.clock.now();
    const localTime = this.localTimeResolver.resolve(now);
    return this.repository.findByDate(localTime.localDate);
  }

  async getRecord(localDate: string): Promise<DailyRecord | null> {
    return this.repository.findByDate(localDate);
  }

  async getRecordsPage(exclusiveDate: string | null, limit: number): Promise<DailyRecord[]> {
    return this.repository.findPageBefore(exclusiveDate, limit);
  }

  async getRecordsBetween(startDate: string, endDate: string): Promise<DailyRecord[]> {
    return this.repository.findBetween(startDate, endDate);
  }

  async getRecordCount(): Promise<number> {
    return this.repository.countAll();
  }

  async submit(input: DiaryEntryInput): Promise<DailyRecord> {
    const normalized = this.textRules.normalizeEntry(input);
    const now = this.clock.now();
    const localTime = this.localTimeResolver.resolve(now);
    const record = this.createRecord(normalized, now, localTime);

    if (this.submissionsInFlight.has(localTime.localDate)) {
      throw new DiaryError(DiaryErrorCode.ALREADY_RECORDED, '今天的记录正在保存');
    }
    this.submissionsInFlight.add(localTime.localDate);
    try {
      try {
        return await this.repository.runInTransaction(async (): Promise<DailyRecord> => {
          const existing = await this.repository.findByDate(localTime.localDate);
          if (existing !== null) {
            throw new DiaryError(DiaryErrorCode.ALREADY_RECORDED, '今天已经留下记录');
          }
          await this.repository.insert(record);
          return record;
        });
      } catch (error) {
        if (error instanceof DiaryError) {
          throw error;
        }
        const existing = await this.repository.findByDate(localTime.localDate);
        if (existing !== null) {
          throw new DiaryError(DiaryErrorCode.ALREADY_RECORDED, '今天已经留下记录');
        }
        throw new DiaryError(DiaryErrorCode.STORAGE_FAILED, '保存日记失败');
      }
    } finally {
      this.submissionsInFlight.delete(localTime.localDate);
    }
  }

  async revise(localDate: string, input: DiaryEntryInput): Promise<DailyRecord> {
    const normalized = this.textRules.normalizeEntry(input);
    const now = this.clock.now();

    if (this.revisionsInFlight.has(localDate)) {
      throw new DiaryError(DiaryErrorCode.REVISION_CONFLICT, '记录正在修订');
    }
    this.revisionsInFlight.add(localDate);
    try {
      try {
        return await this.repository.runInTransaction(async (): Promise<DailyRecord> => {
          const existing = await this.repository.findByDate(localDate);
          if (existing === null) {
            throw new DiaryError(DiaryErrorCode.RECORD_NOT_FOUND, '没有找到这一天的记录');
          }
          if (existing.revisionUsed) {
            throw new DiaryError(DiaryErrorCode.REVISION_USED, '这一天的修订机会已经使用');
          }
          if (now > existing.revisionDeadlineAt) {
            throw new DiaryError(DiaryErrorCode.REVISION_EXPIRED, '这一天的修订时间已经结束');
          }

          const revised = this.createRevision(existing, normalized, now);
          const updated = await this.repository.updateRevision(revised);
          if (!updated) {
            throw new DiaryError(DiaryErrorCode.REVISION_CONFLICT, '记录已经在其他操作中被修订');
          }
          return revised;
        });
      } catch (error) {
        if (error instanceof DiaryError) {
          throw error;
        }
        throw new DiaryError(DiaryErrorCode.STORAGE_FAILED, '修订日记失败');
      }
    } finally {
      this.revisionsInFlight.delete(localDate);
    }
  }

  getRevisionStatus(record: DailyRecord): RevisionStatus {
    if (record.revisionUsed) {
      return RevisionStatus.USED;
    }
    if (this.clock.now() > record.revisionDeadlineAt) {
      return RevisionStatus.EXPIRED;
    }
    return RevisionStatus.AVAILABLE;
  }

  private createRecord(
    entry: NormalizedDiaryEntry,
    now: number,
    localTime: LocalTimeSnapshot
  ): DailyRecord {
    return {
      localDate: localTime.localDate,
      content: entry.content,
      note: entry.note,
      recordType: entry.recordType,
      fontId: entry.fontId,
      paperId: entry.paperId,
      submittedAt: now,
      submittedTimezoneOffset: localTime.timezoneOffsetMinutes,
      revisionDeadlineAt: localTime.revisionDeadlineAt,
      revisedAt: null,
      revisionUsed: false,
      schemaVersion: DiaryService.CURRENT_SCHEMA_VERSION
    };
  }

  private createRevision(
    existing: DailyRecord,
    entry: NormalizedDiaryEntry,
    now: number
  ): DailyRecord {
    return {
      localDate: existing.localDate,
      content: entry.content,
      note: entry.note,
      recordType: entry.recordType,
      fontId: entry.fontId,
      paperId: entry.paperId,
      submittedAt: existing.submittedAt,
      submittedTimezoneOffset: existing.submittedTimezoneOffset,
      revisionDeadlineAt: existing.revisionDeadlineAt,
      revisedAt: now,
      revisionUsed: true,
      schemaVersion: existing.schemaVersion
    };
  }
}
