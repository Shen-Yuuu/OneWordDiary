import { StylePresetId } from '../constants/StyleTokens';
import { DailyRecord, RecordType } from '../model/DailyRecord';
import { DiaryShareMode, ShareDayItem, ShareDayKind, ShareSingleData } from '../model/ShareModel';
import { ShareUiState } from '../model/ShareUiState';
import { SettingsRepository } from '../repository/SettingsRepository';
import { DiaryService } from '../service/DiaryService';
import { Clock } from '../utils/Clock';
import { DiaryDateFormatter } from '../utils/DiaryDateFormatter';
import { LocalTimeResolver } from '../utils/LocalTimeResolver';

@Observed
export class ShareViewModel {
  uiState: ShareUiState = ShareUiState.LOADING;
  mode: DiaryShareMode = DiaryShareMode.SINGLE;
  singleData: ShareSingleData | null = null;
  sevenDays: ShareDayItem[] = [];
  sevenFontId: string = 'system_serif_dev';
  sevenPaperId: string = 'warm_paper_dev';
  errorMessage: string = '';

  private readonly diaryService: DiaryService;
  private readonly settingsRepository: SettingsRepository;
  private readonly clock: Clock;
  private readonly localTimeResolver: LocalTimeResolver;
  private readonly dateFormatter: DiaryDateFormatter;

  constructor(
    diaryService: DiaryService,
    settingsRepository: SettingsRepository,
    clock: Clock,
    localTimeResolver: LocalTimeResolver,
    dateFormatter: DiaryDateFormatter
  ) {
    this.diaryService = diaryService;
    this.settingsRepository = settingsRepository;
    this.clock = clock;
    this.localTimeResolver = localTimeResolver;
    this.dateFormatter = dateFormatter;
  }

  get isBusy(): boolean {
    return this.uiState === ShareUiState.LOADING || this.uiState === ShareUiState.RENDERING;
  }

  get canShare(): boolean {
    if (this.uiState !== ShareUiState.READY && this.uiState !== ShareUiState.RENDER_ERROR) {
      return false;
    }
    return this.mode === DiaryShareMode.SEVEN_DAYS || this.singleData !== null;
  }

  get activePaperId(): string {
    if (this.mode === DiaryShareMode.SINGLE && this.singleData !== null) {
      return this.singleData.paperId;
    }
    return this.sevenPaperId;
  }

  async load(initialMode: DiaryShareMode, preferredSingleDate: string | null): Promise<void> {
    this.uiState = ShareUiState.LOADING;
    this.mode = initialMode;
    this.errorMessage = '';
    this.singleData = null;
    this.sevenDays = [];
    try {
      const today = this.localTimeResolver.resolve(this.clock.now()).localDate;
      const settings = await this.settingsRepository.load();
      this.applySevenDayStyle(settings.stylePresetId);

      const dates = this.dateFormatter.recentDates(today, 7);
      const records = await this.diaryService.getRecordsBetween(dates[dates.length - 1], dates[0]);
      this.sevenDays = this.buildSevenDays(dates, records);

      let singleRecord: DailyRecord | null = null;
      if (preferredSingleDate !== null) {
        singleRecord = await this.diaryService.getRecord(preferredSingleDate);
      } else {
        const latest = await this.diaryService.getRecordsPage(null, 1);
        singleRecord = latest.length === 0 ? null : latest[0];
      }
      this.singleData = singleRecord === null ? null : this.toSingleData(singleRecord);

      if (this.mode === DiaryShareMode.SINGLE && this.singleData === null) {
        this.uiState = ShareUiState.SINGLE_NOT_FOUND;
        return;
      }
      this.uiState = ShareUiState.READY;
    } catch (error) {
      this.uiState = ShareUiState.LOAD_ERROR;
      this.errorMessage = '分享内容暂时无法准备';
    }
  }

  selectMode(mode: DiaryShareMode): void {
    if (this.isBusy || mode === this.mode) {
      return;
    }
    this.mode = mode;
    this.errorMessage = '';
    this.uiState = mode === DiaryShareMode.SINGLE && this.singleData === null ?
      ShareUiState.SINGLE_NOT_FOUND : ShareUiState.READY;
  }

  beginRendering(): boolean {
    if (!this.canShare || this.uiState === ShareUiState.RENDERING) {
      return false;
    }
    this.uiState = ShareUiState.RENDERING;
    this.errorMessage = '';
    return true;
  }

  finishRendering(): void {
    this.uiState = ShareUiState.READY;
    this.errorMessage = '';
  }

  failRendering(): void {
    this.uiState = ShareUiState.RENDER_ERROR;
    this.errorMessage = '分享图未能生成，请重试';
  }

  private applySevenDayStyle(stylePresetId: StylePresetId): void {
    const isPlain = stylePresetId === StylePresetId.PLAIN_ASH;
    this.sevenFontId = isPlain ? 'system_sans_dev' : 'system_serif_dev';
    this.sevenPaperId = isPlain ? 'plain_ash_dev' : 'warm_paper_dev';
  }

  private buildSevenDays(dates: string[], records: DailyRecord[]): ShareDayItem[] {
    const recordByDate: Map<string, DailyRecord> = new Map<string, DailyRecord>();
    records.forEach((record: DailyRecord) => {
      recordByDate.set(record.localDate, record);
    });
    return dates.map((localDate: string, index: number): ShareDayItem => {
      const showMonthHeader = index === 0 ||
        this.dateFormatter.monthKey(localDate) !== this.dateFormatter.monthKey(dates[index - 1]);
      const record = recordByDate.get(localDate);
      if (record === undefined) {
        return this.createDayItem(localDate, ShareDayKind.MISSING, '', '', showMonthHeader);
      }
      const note = record.note === null ? '' : record.note;
      if (record.recordType === RecordType.BLANK) {
        return this.createDayItem(localDate, ShareDayKind.BLANK, '', note, showMonthHeader);
      }
      return this.createDayItem(
        localDate,
        ShareDayKind.WORD,
        record.content === null ? '' : record.content,
        note,
        showMonthHeader
      );
    });
  }

  private createDayItem(
    localDate: string,
    kind: ShareDayKind,
    content: string,
    note: string,
    showMonthHeader: boolean
  ): ShareDayItem {
    return {
      localDate: localDate,
      dateLabel: this.dateFormatter.dayLabel(localDate),
      weekdayLabel: this.dateFormatter.weekdayLabel(localDate),
      monthLabel: this.dateFormatter.monthLabel(localDate),
      showMonthHeader: showMonthHeader,
      kind: kind,
      content: content,
      note: note
    };
  }

  private toSingleData(record: DailyRecord): ShareSingleData {
    return {
      localDate: record.localDate,
      recordType: record.recordType,
      content: record.content === null ? '' : record.content,
      note: record.note === null ? '' : record.note,
      fontId: record.fontId,
      paperId: record.paperId
    };
  }
}
