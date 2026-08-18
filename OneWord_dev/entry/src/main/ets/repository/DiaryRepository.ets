import { DailyRecord } from '../model/DailyRecord';

export interface DiaryRepository {
  findByDate(localDate: string): Promise<DailyRecord | null>;
  insert(record: DailyRecord): Promise<void>;
  updateRevision(record: DailyRecord): Promise<boolean>;
  clearAll(): Promise<void>;
  runInTransaction<T>(operation: () => Promise<T>): Promise<T>;
}

export class InMemoryDiaryRepository implements DiaryRepository {
  private records: Map<string, DailyRecord> = new Map<string, DailyRecord>();

  async findByDate(localDate: string): Promise<DailyRecord | null> {
    const record = this.records.get(localDate);
    return record === undefined ? null : this.cloneRecord(record);
  }

  async insert(record: DailyRecord): Promise<void> {
    if (this.records.has(record.localDate)) {
      throw new Error('duplicate local date');
    }
    this.records.set(record.localDate, this.cloneRecord(record));
  }

  async updateRevision(record: DailyRecord): Promise<boolean> {
    const stored = this.records.get(record.localDate);
    if (stored === undefined || stored.revisionUsed) {
      return false;
    }
    this.records.set(record.localDate, this.cloneRecord(record));
    return true;
  }

  async clearAll(): Promise<void> {
    this.records.clear();
  }

  async runInTransaction<T>(operation: () => Promise<T>): Promise<T> {
    const snapshot = new Map<string, DailyRecord>();
    this.records.forEach((value: DailyRecord, key: string) => {
      snapshot.set(key, this.cloneRecord(value));
    });
    try {
      return await operation();
    } catch (error) {
      this.records = snapshot;
      if (error instanceof Error) {
        throw error;
      }
      throw new Error('in-memory transaction failed');
    }
  }

  private cloneRecord(record: DailyRecord): DailyRecord {
    return {
      localDate: record.localDate,
      content: record.content,
      note: record.note,
      recordType: record.recordType,
      fontId: record.fontId,
      paperId: record.paperId,
      submittedAt: record.submittedAt,
      submittedTimezoneOffset: record.submittedTimezoneOffset,
      revisionDeadlineAt: record.revisionDeadlineAt,
      revisedAt: record.revisedAt,
      revisionUsed: record.revisionUsed,
      schemaVersion: record.schemaVersion
    };
  }
}
