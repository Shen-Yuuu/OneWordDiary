import { paperIdForStyle, styleForPreset, StylePresetId } from '../constants/StyleTokens';
import { FontPresetId } from '../constants/FontCatalog';
import { BackgroundImageStore } from '../model/BackgroundImage';
import { DailyRecord, DiaryEntryInput, RecordType, RevisionStatus } from '../model/DailyRecord';
import { DiaryError, DiaryErrorCode } from '../model/DiaryError';
import { TodayUiState } from '../model/TodayUiState';
import { SettingsRepository } from '../repository/SettingsRepository';
import { CompletionFeedback } from '../service/CompletionFeedback';
import { DiaryService } from '../service/DiaryService';
import { DiaryTextRules } from '../service/DiaryTextRules';
import { Clock } from '../utils/Clock';
import { AppLogger } from '../utils/AppLogger';
import { LocalTimeResolver } from '../utils/LocalTimeResolver';

@Observed
export class TodayViewModel {
  uiState: TodayUiState = TodayUiState.APP_INITIALIZING;
  record: DailyRecord | null = null;
  draftContent: string = '';
  draftNote: string = '';
  draftType: RecordType = RecordType.WORD;
  contentCount: number = 0;
  noteCount: number = 0;
  contentError: string = '';
  noteError: string = '';
  errorMessage: string = '';
  recordCount: number = 0;
  localDate: string = '';
  weekday: string = '';
  stylePresetId: StylePresetId = StylePresetId.PAPER_INK;
  fontPresetId: FontPresetId = FontPresetId.DEFAULT;
  isRevisionDraft: boolean = false;
  inspirationIndex: number = 0;
  recordDisplayType: RecordType = RecordType.WORD;
  recordDisplayContent: string = '';
  recordDisplayContentCount: number = 0;
  recordDisplayNote: string = '';
  recordFontId: string = 'system_serif_dev';
  recordPaperId: string = 'warm_paper_dev';
  draftBackgroundImageId: string | null = null;
  isPickingBackground: boolean = false;
  backgroundError: string = '';

  private readonly diaryService: DiaryService;
  private readonly completionFeedback: CompletionFeedback;
  private readonly settingsRepository: SettingsRepository;
  private readonly clock: Clock;
  private readonly localTimeResolver: LocalTimeResolver;
  private readonly textRules: DiaryTextRules;
  private readonly backgroundImageStore: BackgroundImageStore | null;
  private draftOwnedBackgroundImageId: string | null = null;
  private backgroundRequestVersion: number = 0;
  private readonly inspirations: string[] = [
    '今天，想留下些什么？',
    '此刻的心，像什么天气？',
    '若只留四字，你会写什么？',
    '让一个字替今天说话。',
    '无需完整，只需真实。'
  ];

  constructor(
    diaryService: DiaryService,
    settingsRepository: SettingsRepository,
    clock: Clock,
    localTimeResolver: LocalTimeResolver,
    textRules: DiaryTextRules,
    completionFeedback: CompletionFeedback,
    backgroundImageStore?: BackgroundImageStore
  ) {
    this.diaryService = diaryService;
    this.settingsRepository = settingsRepository;
    this.clock = clock;
    this.localTimeResolver = localTimeResolver;
    this.textRules = textRules;
    this.completionFeedback = completionFeedback;
    this.backgroundImageStore = backgroundImageStore === undefined ? null : backgroundImageStore;
  }

  get inspiration(): string {
    return this.inspirations[this.inspirationIndex];
  }

  get displayDate(): string {
    return this.localDate.replace(/-/g, '.');
  }

  get canConfirmWord(): boolean {
    return !this.isPickingBackground && this.contentError.length === 0 && this.noteError.length === 0 &&
      this.contentCount >= 1 &&
      this.contentCount <= 4;
  }

  get backgroundImageUri(): string {
    if (this.backgroundImageStore === null) {
      return '';
    }
    const imageId = this.hasDraftContext() ? this.draftBackgroundImageId :
      (this.record === null ? null : this.record.backgroundImageId);
    return this.backgroundImageStore.resolveUri(imageId);
  }

  get isBusy(): boolean {
    return this.uiState === TodayUiState.TODAY_SUBMITTING ||
      this.uiState === TodayUiState.TODAY_REVISION_SAVING;
  }

  get isConfirmationVisible(): boolean {
    return this.uiState === TodayUiState.TODAY_CONFIRM_WORD ||
      this.uiState === TodayUiState.TODAY_CONFIRM_BLANK ||
      this.uiState === TodayUiState.TODAY_REVISION_CONFIRM ||
      this.uiState === TodayUiState.TODAY_SUBMITTING ||
      this.uiState === TodayUiState.TODAY_REVISION_SAVING ||
      this.uiState === TodayUiState.TODAY_SUBMIT_ERROR ||
      this.uiState === TodayUiState.TODAY_REVISION_ERROR;
  }

  get isRecordedState(): boolean {
    return this.uiState === TodayUiState.TODAY_RECORDED_WORD_EDITABLE ||
      this.uiState === TodayUiState.TODAY_RECORDED_BLANK_EDITABLE ||
      this.uiState === TodayUiState.TODAY_FINAL_REVISED ||
      this.uiState === TodayUiState.TODAY_FINAL_EXPIRED;
  }

  get isEditingState(): boolean {
    return this.uiState === TodayUiState.TODAY_EMPTY ||
      this.uiState === TodayUiState.TODAY_EDITING_WORD ||
      this.uiState === TodayUiState.TODAY_INPUT_INVALID ||
      this.uiState === TodayUiState.TODAY_NOTE_INVALID ||
      this.uiState === TodayUiState.TODAY_REVISING_WORD ||
      this.uiState === TodayUiState.TODAY_REVISING_BLANK;
  }

  get revisionDeadlineLabel(): string {
    if (this.record === null) {
      return '';
    }
    const deadline = new Date(this.record.revisionDeadlineAt);
    return `${this.padTwoDigits(deadline.getHours())}:${this.padTwoDigits(deadline.getMinutes())}`;
  }

  async load(preserveDraft: boolean = false): Promise<void> {
    if (this.isBusy) {
      return;
    }
    const timestamp = this.clock.now();
    const snapshot = this.localTimeResolver.resolve(timestamp);
    if (preserveDraft && this.isPickingBackground && this.localDate === snapshot.localDate) {
      return;
    }
    const previousState = this.uiState;
    const shouldPreserveDraft = preserveDraft && this.localDate === snapshot.localDate &&
      this.hasDraftContext();
    if (!shouldPreserveDraft && this.hasDraftContext()) {
      this.resetDraft(true);
    }
    this.uiState = TodayUiState.APP_INITIALIZING;
    this.errorMessage = '';
    try {
      const settings = await this.settingsRepository.load();
      const record = await this.diaryService.getToday();
      const recordCount = await this.diaryService.getRecordCount();

      this.localDate = snapshot.localDate;
      this.weekday = this.formatWeekday(new Date(timestamp).getDay());
      this.stylePresetId = settings.stylePresetId;
      this.fontPresetId = settings.fontPresetId;
      AppStorage.setOrCreate('currentPaperId', paperIdForStyle(settings.stylePresetId));
      AppStorage.setOrCreate('currentFontId', settings.fontPresetId);
      AppLogger.info(`style.today_load preset=${settings.stylePresetId}`);
      this.record = record;
      this.syncRecordPresentation(record);
      this.recordCount = recordCount;
      if (shouldPreserveDraft) {
        this.uiState = previousState;
      } else {
        this.resetDraft(false);
        this.deriveStateFromRecord();
      }
    } catch (error) {
      this.uiState = TodayUiState.APP_STORAGE_ERROR;
      this.errorMessage = '记录暂时无法打开';
    }
  }

  setContent(value: string): void {
    if (this.isBusy) {
      return;
    }
    this.draftContent = value;
    const normalized = value.normalize('NFC').trim();
    this.contentCount = this.textRules.countGraphemes(normalized);
    this.contentError = this.validateContent(value, normalized);
    if (normalized.length > 0) {
      this.draftType = RecordType.WORD;
    }
    this.updateEditingState();
  }

  setNote(value: string): void {
    if (this.isBusy) {
      return;
    }
    this.draftNote = value;
    const normalized = value.normalize('NFC').trim();
    this.noteCount = this.textRules.countGraphemes(normalized);
    this.noteError = this.validateNote(value);
    this.updateEditingState();
  }

  nextInspiration(): void {
    this.inspirationIndex = (this.inspirationIndex + 1) % this.inspirations.length;
  }

  async selectBackgroundFromUri(uri: string): Promise<void> {
    if (uri.length === 0) {
      return;
    }
    if (this.isBusy || !this.isBackgroundDraftEditable()) {
      return;
    }
    if (this.backgroundImageStore === null) {
      this.backgroundError = '\u80cc\u666f\u56fe\u670d\u52a1\u6682\u65f6\u4e0d\u53ef\u7528';
      return;
    }

    const requestVersion = ++this.backgroundRequestVersion;
    const requestDate = this.localDate;
    this.isPickingBackground = true;
    this.backgroundError = '';
    let importedId: string | null = null;
    try {
      importedId = await this.backgroundImageStore.importFromUri(uri);
      const currentDate = this.localTimeResolver.resolve(this.clock.now()).localDate;
      if (requestVersion !== this.backgroundRequestVersion || requestDate !== this.localDate ||
        requestDate !== currentDate || !this.isBackgroundDraftEditable()) {
        const shouldReloadForRollover = requestVersion === this.backgroundRequestVersion &&
          requestDate === this.localDate && requestDate !== currentDate;
        this.safeRemoveBackground(importedId);
        importedId = null;
        if (shouldReloadForRollover) {
          this.isPickingBackground = false;
          await this.load();
        }
        return;
      }
      const previousOwnedId = this.draftOwnedBackgroundImageId;
      this.draftBackgroundImageId = importedId;
      this.draftOwnedBackgroundImageId = importedId;
      importedId = null;
      if (previousOwnedId !== null && previousOwnedId !== this.draftOwnedBackgroundImageId) {
        this.safeRemoveBackground(previousOwnedId);
      }
      this.updateEditingState();
    } catch (error) {
      if (requestVersion === this.backgroundRequestVersion) {
        this.backgroundError = this.mapBackgroundError(error);
      }
    } finally {
      if (importedId !== null) {
        this.safeRemoveBackground(importedId);
      }
      if (requestVersion === this.backgroundRequestVersion) {
        this.isPickingBackground = false;
      }
    }
  }

  removeBackgroundImage(): void {
    if (this.isBusy) {
      return;
    }
    this.backgroundRequestVersion++;
    this.isPickingBackground = false;
    this.backgroundError = '';
    if (this.draftOwnedBackgroundImageId !== null) {
      this.safeRemoveBackground(this.draftOwnedBackgroundImageId);
    }
    this.draftOwnedBackgroundImageId = null;
    this.draftBackgroundImageId = null;
  }

  showWordConfirmation(): void {
    if (!this.canConfirmWord || this.isBusy) {
      return;
    }
    try {
      const normalized = this.textRules.normalizeEntry(this.createInput(RecordType.WORD));
      this.draftContent = normalized.content === null ? '' : normalized.content;
      this.draftNote = normalized.note === null ? '' : normalized.note;
      this.draftType = RecordType.WORD;
      this.errorMessage = '';
      this.uiState = this.isRevisionDraft ? TodayUiState.TODAY_REVISION_CONFIRM :
        TodayUiState.TODAY_CONFIRM_WORD;
    } catch (error) {
      this.applyValidationError(error);
    }
  }

  showBlankConfirmation(): void {
    if (this.isBusy || this.isPickingBackground) {
      return;
    }
    this.draftType = RecordType.BLANK;
    this.errorMessage = '';
    this.uiState = this.isRevisionDraft ? TodayUiState.TODAY_REVISION_CONFIRM :
      TodayUiState.TODAY_CONFIRM_BLANK;
  }

  cancelConfirmation(): void {
    if (this.isBusy) {
      return;
    }
    this.errorMessage = '';
    this.updateEditingState();
  }

  async confirmPending(): Promise<void> {
    if (this.isBusy || this.isPickingBackground) {
      return;
    }
    const activeDate = this.localTimeResolver.resolve(this.clock.now()).localDate;
    if (this.localDate !== activeDate) {
      this.resetDraft(true);
      await this.load();
      return;
    }
    this.errorMessage = '';
    this.uiState = this.isRevisionDraft ? TodayUiState.TODAY_REVISION_SAVING :
      TodayUiState.TODAY_SUBMITTING;
    const input = this.createInput(this.draftType);
    const previousBackgroundImageId = this.record === null || this.record.backgroundImageId === undefined ?
      null : this.record.backgroundImageId;
    let saved: DailyRecord;
    try {
      saved = this.isRevisionDraft ? await this.reviseRecord(input) : await this.diaryService.submit(input);
    } catch (error) {
      await this.handleSaveError(error);
      return;
    }

    const committedBackgroundImageId = saved.backgroundImageId === undefined ? null : saved.backgroundImageId;
    if (this.draftOwnedBackgroundImageId === committedBackgroundImageId) {
      this.draftOwnedBackgroundImageId = null;
    }
    this.record = saved;
    this.syncRecordPresentation(saved);
    if (previousBackgroundImageId !== null && previousBackgroundImageId !== committedBackgroundImageId) {
      this.safeRemoveBackground(previousBackgroundImageId);
    }
    try {
      this.recordCount = await this.diaryService.getRecordCount();
    } catch (error) {
      AppLogger.warn('today.record_count_refresh_failed_after_commit');
    }
    try {
      this.completionFeedback.playRecordCommitted();
    } catch (error) {
      AppLogger.warn('today.completion_feedback_failed_after_commit');
    }
    this.resetDraft(false);
    this.deriveStateFromRecord();
  }

  retrySave(): Promise<void> {
    return this.confirmPending();
  }

  startRevision(): void {
    if (this.isBusy) {
      return;
    }
    if (this.record === null || this.diaryService.getRevisionStatus(this.record) !== RevisionStatus.AVAILABLE) {
      this.deriveStateFromRecord();
      return;
    }
    this.isRevisionDraft = true;
    this.draftType = this.record.recordType;
    this.draftContent = this.record.content === null ? '' : this.record.content;
    this.draftNote = this.record.note === null ? '' : this.record.note;
    this.draftBackgroundImageId = this.record.backgroundImageId === undefined ? null :
      this.record.backgroundImageId;
    this.draftOwnedBackgroundImageId = null;
    this.backgroundError = '';
    this.contentCount = this.textRules.countGraphemes(this.draftContent);
    this.noteCount = this.textRules.countGraphemes(this.draftNote);
    this.contentError = '';
    this.noteError = '';
    this.errorMessage = '';
    this.uiState = this.draftType === RecordType.BLANK ? TodayUiState.TODAY_REVISING_BLANK :
      TodayUiState.TODAY_REVISING_WORD;
  }

  cancelRevision(): void {
    if (this.isBusy) {
      return;
    }
    this.resetDraft(true);
    this.deriveStateFromRecord();
  }

  returnFromError(): void {
    if (this.isBusy) {
      return;
    }
    this.errorMessage = '';
    this.updateEditingState();
  }

  private async reviseRecord(input: DiaryEntryInput): Promise<DailyRecord> {
    if (this.record === null) {
      throw new DiaryError(DiaryErrorCode.RECORD_NOT_FOUND, '没有找到今天的记录');
    }
    return this.diaryService.revise(this.record.localDate, input);
  }

  private async handleSaveError(error: Error): Promise<void> {
    if (error instanceof DiaryError && (error.code === DiaryErrorCode.REVISION_EXPIRED ||
      error.code === DiaryErrorCode.REVISION_USED || error.code === DiaryErrorCode.REVISION_CONFLICT)) {
      this.uiState = TodayUiState.TODAY_REVISION_ERROR;
      this.resetDraft(true);
      await this.load();
      return;
    }
    this.errorMessage = this.mapSaveError(error);
    this.uiState = this.isRevisionDraft ? TodayUiState.TODAY_REVISION_ERROR :
      TodayUiState.TODAY_SUBMIT_ERROR;
  }

  private deriveStateFromRecord(): void {
    if (this.record === null) {
      this.uiState = TodayUiState.TODAY_EMPTY;
      return;
    }
    const revisionStatus = this.diaryService.getRevisionStatus(this.record);
    if (revisionStatus === RevisionStatus.AVAILABLE) {
      this.uiState = this.record.recordType === RecordType.BLANK ?
        TodayUiState.TODAY_RECORDED_BLANK_EDITABLE : TodayUiState.TODAY_RECORDED_WORD_EDITABLE;
      return;
    }
    this.uiState = revisionStatus === RevisionStatus.USED ? TodayUiState.TODAY_FINAL_REVISED :
      TodayUiState.TODAY_FINAL_EXPIRED;
  }

  private updateEditingState(): void {
    if (this.contentError.length > 0) {
      this.uiState = TodayUiState.TODAY_INPUT_INVALID;
      return;
    }
    if (this.noteError.length > 0) {
      this.uiState = TodayUiState.TODAY_NOTE_INVALID;
      return;
    }
    if (this.isRevisionDraft) {
      this.uiState = this.draftType === RecordType.BLANK && this.draftContent.trim().length === 0 ?
        TodayUiState.TODAY_REVISING_BLANK : TodayUiState.TODAY_REVISING_WORD;
      return;
    }
    this.uiState = this.contentCount === 0 ? TodayUiState.TODAY_EMPTY : TodayUiState.TODAY_EDITING_WORD;
  }

  private createInput(type: RecordType): DiaryEntryInput {
    const style = styleForPreset(this.stylePresetId);
    return {
      recordType: type,
      content: type === RecordType.BLANK ? null : this.draftContent,
      note: type === RecordType.BLANK || this.draftNote.trim().length === 0 ? null : this.draftNote,
      fontId: this.fontPresetId,
      paperId: style.paperId,
      backgroundImageId: this.draftBackgroundImageId
    };
  }

  private validateContent(raw: string, normalized: string): string {
    if (raw.includes('\n') || raw.includes('\r')) {
      return '正文不能换行';
    }
    if (raw.length > 0 && normalized.length === 0) {
      return '请留下 1 至 4 个字';
    }
    if (this.contentCount > 4) {
      return '最多留下 4 个字';
    }
    return '';
  }

  private validateNote(raw: string): string {
    if (raw.includes('\n') || raw.includes('\r')) {
      return '注解不能换行';
    }
    if (this.noteCount > 30) {
      return '注解最多 30 个字';
    }
    return '';
  }

  private applyValidationError(error: Error): void {
    if (error instanceof DiaryError && (error.code === DiaryErrorCode.NOTE_HAS_LINE_BREAK ||
      error.code === DiaryErrorCode.NOTE_TOO_LONG)) {
      this.noteError = error.message;
      this.uiState = TodayUiState.TODAY_NOTE_INVALID;
      return;
    }
    this.contentError = error instanceof DiaryError ? error.message : '请检查今日正文';
    this.uiState = TodayUiState.TODAY_INPUT_INVALID;
  }

  private mapSaveError(error: Error): string {
    if (error instanceof DiaryError && error.code === DiaryErrorCode.ALREADY_RECORDED) {
      return '今天已经留下记录';
    }
    return this.isRevisionDraft ? '修订没有保存，机会仍然保留' : '暂时没有保存，请再试一次';
  }

  private resetDraft(removeOwnedBackground: boolean): void {
    this.backgroundRequestVersion++;
    this.isPickingBackground = false;
    if (removeOwnedBackground && this.draftOwnedBackgroundImageId !== null) {
      this.safeRemoveBackground(this.draftOwnedBackgroundImageId);
    }
    this.draftOwnedBackgroundImageId = null;
    this.draftBackgroundImageId = null;
    this.backgroundError = '';
    this.draftContent = '';
    this.draftNote = '';
    this.draftType = RecordType.WORD;
    this.contentCount = 0;
    this.noteCount = 0;
    this.contentError = '';
    this.noteError = '';
    this.isRevisionDraft = false;
  }

  private hasDraftContext(): boolean {
    return this.isRevisionDraft || this.isPickingBackground || this.draftContent.length > 0 ||
      this.draftNote.length > 0 || this.draftBackgroundImageId !== null || this.isConfirmationVisible ||
      this.uiState === TodayUiState.TODAY_SUBMIT_ERROR || this.uiState === TodayUiState.TODAY_REVISION_ERROR;
  }

  private isBackgroundDraftEditable(): boolean {
    return this.isRevisionDraft || this.record === null;
  }

  private safeRemoveBackground(id: string): void {
    if (this.backgroundImageStore === null) {
      return;
    }
    try {
      this.backgroundImageStore.remove(id);
    } catch (error) {
      AppLogger.warn('today.background_cleanup_failed');
    }
  }

  private mapBackgroundError(error: Error): string {
    if (error instanceof Error && error.message.trim().length > 0) {
      return error.message;
    }
    return '\u80cc\u666f\u56fe\u5904\u7406\u5931\u8d25\uff0c\u8bf7\u91cd\u8bd5';
  }

  private syncRecordPresentation(record: DailyRecord | null): void {
    if (record === null) {
      this.recordDisplayType = RecordType.WORD;
      this.recordDisplayContent = '';
      this.recordDisplayContentCount = 0;
      this.recordDisplayNote = '';
      this.recordFontId = 'system_serif_dev';
      this.recordPaperId = 'warm_paper_dev';
      return;
    }
    this.recordDisplayType = record.recordType;
    this.recordDisplayContent = record.content === null ? '' : record.content;
    this.recordDisplayContentCount = this.textRules.countGraphemes(this.recordDisplayContent);
    this.recordDisplayNote = record.note === null ? '' : record.note;
    this.recordFontId = record.fontId;
    this.recordPaperId = record.paperId;
  }

  private formatWeekday(day: number): string {
    const weekdays: string[] = ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六'];
    return weekdays[day];
  }

  private padTwoDigits(value: number): string {
    return value < 10 ? `0${value}` : value.toString();
  }
}
