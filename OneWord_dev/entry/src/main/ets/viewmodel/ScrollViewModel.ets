import { DailyRecord, RecordType } from '../model/DailyRecord';
import { ScrollDisplayItem, ScrollItemSide } from '../model/ScrollDisplayItem';
import { ScrollUiState } from '../model/ScrollUiState';
import { DiaryService } from '../service/DiaryService';
import { DiaryDateFormatter } from '../utils/DiaryDateFormatter';
import { GraphemeCounter } from '../utils/GraphemeCounter';
import { ScrollDataSource } from './ScrollDataSource';

@Observed
export class ScrollViewModel {
  uiState: ScrollUiState = ScrollUiState.INITIAL_LOADING;
  readonly dataSource: ScrollDataSource = new ScrollDataSource();
  isLoadingMore: boolean = false;
  hasMore: boolean = true;
  errorMessage: string = '';
  loadMoreError: string = '';
  totalCount: number = 0;

  private readonly diaryService: DiaryService;
  private readonly pageSize: number;
  private readonly dateFormatter: DiaryDateFormatter;
  private readonly graphemeCounter: GraphemeCounter = new GraphemeCounter();
  private cursorDate: string | null = null;
  private loadedDates: Set<string> = new Set<string>();
  private requestInFlight: boolean = false;
  private nextWordOnLeft: boolean = true;

  constructor(diaryService: DiaryService, pageSize: number, dateFormatter: DiaryDateFormatter) {
    this.diaryService = diaryService;
    this.pageSize = pageSize;
    this.dateFormatter = dateFormatter;
  }

  async load(): Promise<void> {
    if (this.requestInFlight) {
      return;
    }
    this.requestInFlight = true;
    this.uiState = ScrollUiState.INITIAL_LOADING;
    this.errorMessage = '';
    this.loadMoreError = '';
    this.cursorDate = null;
    this.loadedDates = new Set<string>();
    this.nextWordOnLeft = true;
    this.dataSource.replaceAll([]);
    try {
      const records = await this.diaryService.getRecordsPage(null, this.pageSize);
      const totalCount = await this.diaryService.getRecordCount();
      this.totalCount = totalCount;
      this.applyPage(records, true);
      this.uiState = records.length === 0 ? ScrollUiState.EMPTY : ScrollUiState.READY;
    } catch (error) {
      this.uiState = ScrollUiState.INITIAL_ERROR;
      this.errorMessage = '文字长卷暂时无法展开';
    } finally {
      this.requestInFlight = false;
    }
  }

  async loadMore(): Promise<void> {
    if (this.requestInFlight || !this.hasMore || this.uiState !== ScrollUiState.READY) {
      return;
    }
    this.requestInFlight = true;
    this.isLoadingMore = true;
    this.loadMoreError = '';
    try {
      const records = await this.diaryService.getRecordsPage(this.cursorDate, this.pageSize);
      this.applyPage(records, false);
    } catch (error) {
      this.loadMoreError = '后面的记录暂时没有展开';
    } finally {
      this.isLoadingMore = false;
      this.requestInFlight = false;
    }
  }

  retryLoadMore(): Promise<void> {
    return this.loadMore();
  }

  private applyPage(records: DailyRecord[], replace: boolean): void {
    const newItems: ScrollDisplayItem[] = [];
    let previousItem = replace ? null : this.dataSource.lastItem();
    for (const record of records) {
      if (!this.loadedDates.has(record.localDate)) {
        const item = this.createDisplayItem(record, previousItem);
        newItems.push(item);
        this.loadedDates.add(record.localDate);
        previousItem = item;
      }
    }
    if (replace) {
      this.dataSource.replaceAll(newItems);
    } else {
      this.dataSource.append(newItems);
    }
    if (records.length > 0) {
      this.cursorDate = records[records.length - 1].localDate;
    }
    this.hasMore = records.length === this.pageSize;
  }

  private createDisplayItem(
    record: DailyRecord,
    previousItem: ScrollDisplayItem | null
  ): ScrollDisplayItem {
    const monthKey = this.dateFormatter.monthKey(record.localDate);
    const showMonthHeader = previousItem === null || previousItem.monthKey !== monthKey;
    let side = ScrollItemSide.CENTER;
    if (record.recordType === RecordType.WORD) {
      side = this.nextWordOnLeft ? ScrollItemSide.LEFT : ScrollItemSide.RIGHT;
      this.nextWordOnLeft = !this.nextWordOnLeft;
    }
    return new ScrollDisplayItem(
      record.localDate,
      monthKey,
      this.dateFormatter.monthLabel(record.localDate),
      showMonthHeader,
      this.dateFormatter.dayLabel(record.localDate),
      this.dateFormatter.weekdayLabel(record.localDate),
      record.recordType,
      record.content === null ? '' : record.content,
      record.content === null ? 0 : this.graphemeCounter.count(record.content),
      record.fontId,
      record.paperId,
      side
    );
  }
}
