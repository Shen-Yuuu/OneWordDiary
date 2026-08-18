import { relationalStore } from '@kit.ArkData';
import { DatabaseConstants } from '../constants/DatabaseConstants';
import { DailyRecord, RecordType } from '../model/DailyRecord';
import { DiaryRepository } from './DiaryRepository';

export class RdbDiaryRepository implements DiaryRepository {
  private readonly store: relationalStore.RdbStore;

  constructor(store: relationalStore.RdbStore) {
    this.store = store;
  }

  async findByDate(localDate: string): Promise<DailyRecord | null> {
    const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_DAILY_RECORD);
    predicates.equalTo(DatabaseConstants.COLUMN_LOCAL_DATE, localDate);
    const resultSet = await this.store.query(predicates);
    try {
      if (!resultSet.goToFirstRow()) {
        return null;
      }
      return this.readRecord(resultSet);
    } finally {
      resultSet.close();
    }
  }

  async insert(record: DailyRecord): Promise<void> {
    await this.store.insert(DatabaseConstants.TABLE_DAILY_RECORD, this.toValuesBucket(record));
  }

  async updateRevision(record: DailyRecord): Promise<boolean> {
    const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_DAILY_RECORD);
    predicates.equalTo(DatabaseConstants.COLUMN_LOCAL_DATE, record.localDate)
      .and()
      .equalTo(DatabaseConstants.COLUMN_REVISION_USED, 0);
    const changedRows = await this.store.update(this.toValuesBucket(record), predicates);
    return changedRows === 1;
  }

  async clearAll(): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(DatabaseConstants.TABLE_DAILY_RECORD);
    await this.store.delete(predicates);
  }

  async runInTransaction<T>(operation: () => Promise<T>): Promise<T> {
    this.store.beginTransaction();
    try {
      const result = await operation();
      this.store.commit();
      return result;
    } catch (error) {
      this.store.rollBack();
      if (error instanceof Error) {
        throw error;
      }
      throw new Error('database transaction failed');
    }
  }

  private toValuesBucket(record: DailyRecord): relationalStore.ValuesBucket {
    return {
      local_date: record.localDate,
      content: record.content,
      note: record.note,
      record_type: record.recordType,
      font_id: record.fontId,
      paper_id: record.paperId,
      submitted_at: record.submittedAt,
      submitted_tz_offset: record.submittedTimezoneOffset,
      revision_deadline_at: record.revisionDeadlineAt,
      revised_at: record.revisedAt,
      revision_used: record.revisionUsed ? 1 : 0,
      schema_version: record.schemaVersion
    };
  }

  private readRecord(resultSet: relationalStore.ResultSet): DailyRecord {
    const contentIndex = resultSet.getColumnIndex(DatabaseConstants.COLUMN_CONTENT);
    const noteIndex = resultSet.getColumnIndex(DatabaseConstants.COLUMN_NOTE);
    const revisedAtIndex = resultSet.getColumnIndex(DatabaseConstants.COLUMN_REVISED_AT);
    return {
      localDate: resultSet.getString(resultSet.getColumnIndex(DatabaseConstants.COLUMN_LOCAL_DATE)),
      content: resultSet.isColumnNull(contentIndex) ? null : resultSet.getString(contentIndex),
      note: resultSet.isColumnNull(noteIndex) ? null : resultSet.getString(noteIndex),
      recordType: this.parseRecordType(
        resultSet.getString(resultSet.getColumnIndex(DatabaseConstants.COLUMN_RECORD_TYPE))),
      fontId: resultSet.getString(resultSet.getColumnIndex(DatabaseConstants.COLUMN_FONT_ID)),
      paperId: resultSet.getString(resultSet.getColumnIndex(DatabaseConstants.COLUMN_PAPER_ID)),
      submittedAt: resultSet.getLong(resultSet.getColumnIndex(DatabaseConstants.COLUMN_SUBMITTED_AT)),
      submittedTimezoneOffset: resultSet.getLong(
        resultSet.getColumnIndex(DatabaseConstants.COLUMN_SUBMITTED_TIMEZONE_OFFSET)),
      revisionDeadlineAt: resultSet.getLong(
        resultSet.getColumnIndex(DatabaseConstants.COLUMN_REVISION_DEADLINE_AT)),
      revisedAt: resultSet.isColumnNull(revisedAtIndex) ? null : resultSet.getLong(revisedAtIndex),
      revisionUsed: resultSet.getLong(resultSet.getColumnIndex(DatabaseConstants.COLUMN_REVISION_USED)) === 1,
      schemaVersion: resultSet.getLong(resultSet.getColumnIndex(DatabaseConstants.COLUMN_SCHEMA_VERSION))
    };
  }

  private parseRecordType(value: string): RecordType {
    return value === RecordType.BLANK ? RecordType.BLANK : RecordType.WORD;
  }
}
