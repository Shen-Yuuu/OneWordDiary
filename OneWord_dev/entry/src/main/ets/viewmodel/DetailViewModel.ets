import { DailyRecord, RecordType } from '../model/DailyRecord';
import { DetailUiState } from '../model/DetailUiState';
import { DiaryService } from '../service/DiaryService';
import { DiaryDateFormatter } from '../utils/DiaryDateFormatter';
import { GraphemeCounter } from '../utils/GraphemeCounter';

@Observed
export class DetailViewModel {
  uiState: DetailUiState = DetailUiState.LOADING;
  record: DailyRecord | null = null;
  dateLabel: string = '';
  errorMessage: string = '';
  contentCount: number = 0;
  recordType: RecordType = RecordType.WORD;
  content: string = '';
  note: string = '';
  fontId: string = 'system_serif_dev';
  paperId: string = 'warm_paper_dev';

  private readonly diaryService: DiaryService;
  private readonly dateFormatter: DiaryDateFormatter;
  private readonly graphemeCounter: GraphemeCounter = new GraphemeCounter();

  constructor(diaryService: DiaryService, dateFormatter: DiaryDateFormatter) {
    this.diaryService = diaryService;
    this.dateFormatter = dateFormatter;
  }

  async load(localDate: string): Promise<void> {
    this.uiState = DetailUiState.LOADING;
    this.errorMessage = '';
    this.record = null;
    this.contentCount = 0;
    this.recordType = RecordType.WORD;
    this.content = '';
    this.note = '';
    this.fontId = 'system_serif_dev';
    this.paperId = 'warm_paper_dev';
    this.dateLabel = this.dateFormatter.detailLabel(localDate);
    try {
      const record = await this.diaryService.getRecord(localDate);
      this.record = record;
      if (record === null) {
        this.uiState = DetailUiState.NOT_FOUND;
        return;
      }
      this.contentCount = record.content === null ? 0 : this.graphemeCounter.count(record.content);
      this.recordType = record.recordType;
      this.content = record.content === null ? '' : record.content;
      this.note = record.note === null ? '' : record.note;
      this.fontId = record.fontId;
      this.paperId = record.paperId;
      this.uiState = record.recordType === RecordType.BLANK ? DetailUiState.BLANK : DetailUiState.WORD;
    } catch (error) {
      this.uiState = DetailUiState.LOAD_ERROR;
      this.errorMessage = '这一天的记录暂时无法打开';
    }
  }
}
