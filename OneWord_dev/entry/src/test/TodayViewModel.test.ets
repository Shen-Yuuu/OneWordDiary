import { describe, expect, it } from '@ohos/hypium';
import { StylePresetId } from '../main/ets/constants/StyleTokens';
import { DailyRecord, RecordType } from '../main/ets/model/DailyRecord';
import { AppSettings, DEFAULT_APP_SETTINGS, ReminderSettings } from '../main/ets/model/Settings';
import { TodayUiState } from '../main/ets/model/TodayUiState';
import { DiaryRepository, InMemoryDiaryRepository } from '../main/ets/repository/DiaryRepository';
import { SettingsRepository } from '../main/ets/repository/SettingsRepository';
import { NoopCompletionFeedback } from '../main/ets/service/CompletionFeedback';
import { DiaryService } from '../main/ets/service/DiaryService';
import { DiaryTextRules } from '../main/ets/service/DiaryTextRules';
import { FixedClock } from '../main/ets/utils/Clock';
import { FixedLocalTimeResolver } from '../main/ets/utils/LocalTimeResolver';
import { TodayViewModel } from '../main/ets/viewmodel/TodayViewModel';

class MemorySettingsRepository implements SettingsRepository {
  private settings: AppSettings = DEFAULT_APP_SETTINGS;

  async load(): Promise<AppSettings> {
    return this.settings;
  }

  async saveStylePresetId(stylePresetId: StylePresetId): Promise<void> {
    this.settings = {
      stylePresetId: stylePresetId,
      reminder: this.settings.reminder
    };
  }

  async saveReminder(reminder: ReminderSettings): Promise<void> {
    this.settings = {
      stylePresetId: this.settings.stylePresetId,
      reminder: reminder
    };
  }

  async reset(): Promise<void> {
    this.settings = DEFAULT_APP_SETTINGS;
  }
}

class FailingOnceRevisionRepository extends InMemoryDiaryRepository {
  private shouldFail: boolean = true;

  async updateRevision(record: DailyRecord): Promise<boolean> {
    if (this.shouldFail) {
      this.shouldFail = false;
      throw new Error('simulated revision failure');
    }
    return super.updateRevision(record);
  }
}

class ViewModelFixture {
  readonly repository: DiaryRepository;
  readonly clock: FixedClock;
  readonly viewModel: TodayViewModel;

  constructor(repository: DiaryRepository = new InMemoryDiaryRepository()) {
    this.repository = repository;
    this.clock = new FixedClock(1000);
    const resolver = new FixedLocalTimeResolver({
      localDate: '2026-08-18',
      timezoneOffsetMinutes: 480,
      revisionDeadlineAt: 2000
    });
    const rules = new DiaryTextRules();
    const service = new DiaryService(repository, this.clock, resolver, rules);
    this.viewModel = new TodayViewModel(
      service,
      new MemorySettingsRepository(),
      this.clock,
      resolver,
      rules,
      new NoopCompletionFeedback()
    );
  }
}

export default function todayViewModelTest(): void {
  describe('TodayViewModel', () => {
    it('loadsTheEmptyTodayState', 0, async () => {
      const fixture = new ViewModelFixture();
      await fixture.viewModel.load();

      expect(fixture.viewModel.uiState).assertEqual(TodayUiState.TODAY_EMPTY);
      expect(fixture.viewModel.localDate).assertEqual('2026-08-18');
      expect(fixture.viewModel.displayDate).assertEqual('2026.08.18');
      expect(fixture.viewModel.recordCount).assertEqual(0);
    });

    it('keepsDraftAndDoesNotPersistWhenConfirmationIsCancelled', 0, async () => {
      const fixture = new ViewModelFixture();
      await fixture.viewModel.load();
      fixture.viewModel.setContent('静');
      fixture.viewModel.setNote('雨后的窗');
      fixture.viewModel.showWordConfirmation();

      expect(fixture.viewModel.uiState).assertEqual(TodayUiState.TODAY_CONFIRM_WORD);
      fixture.viewModel.cancelConfirmation();
      expect(fixture.viewModel.draftContent).assertEqual('静');
      expect(fixture.viewModel.draftNote).assertEqual('雨后的窗');
      expect(await fixture.repository.countAll()).assertEqual(0);
    });

    it('submitsAWordOnlyAfterFinalConfirmation', 0, async () => {
      const fixture = new ViewModelFixture();
      await fixture.viewModel.load();
      fixture.viewModel.setContent('静');
      fixture.viewModel.showWordConfirmation();
      await fixture.viewModel.confirmPending();

      expect(fixture.viewModel.uiState).assertEqual(TodayUiState.TODAY_RECORDED_WORD_EDITABLE);
      expect(fixture.viewModel.record !== null && fixture.viewModel.record.content === '静').assertTrue();
      expect(fixture.viewModel.recordCount).assertEqual(1);
    });

    it('submitsABlankDayAsAnExplicitRecord', 0, async () => {
      const fixture = new ViewModelFixture();
      await fixture.viewModel.load();
      fixture.viewModel.showBlankConfirmation();
      await fixture.viewModel.confirmPending();

      expect(fixture.viewModel.uiState).assertEqual(TodayUiState.TODAY_RECORDED_BLANK_EDITABLE);
      expect(fixture.viewModel.record !== null && fixture.viewModel.record.recordType === RecordType.BLANK).assertTrue();
      expect(fixture.viewModel.record !== null && fixture.viewModel.record.content === null).assertTrue();
    });

    it('exposesInputAndNoteValidationBeforeConfirmation', 0, async () => {
      const fixture = new ViewModelFixture();
      await fixture.viewModel.load();
      fixture.viewModel.setContent('一二三四五');
      expect(fixture.viewModel.uiState).assertEqual(TodayUiState.TODAY_INPUT_INVALID);
      expect(fixture.viewModel.canConfirmWord).assertFalse();

      fixture.viewModel.setContent('静');
      fixture.viewModel.setNote('第一行\n第二行');
      expect(fixture.viewModel.uiState).assertEqual(TodayUiState.TODAY_NOTE_INVALID);
      expect(fixture.viewModel.canConfirmWord).assertFalse();
    });

    it('usesTheOnlyRevisionToChangeAWordIntoBlank', 0, async () => {
      const fixture = new ViewModelFixture();
      await fixture.viewModel.load();
      fixture.viewModel.setContent('静');
      fixture.viewModel.showWordConfirmation();
      await fixture.viewModel.confirmPending();

      fixture.clock.setTime(1500);
      fixture.viewModel.startRevision();
      fixture.viewModel.setContent('');
      fixture.viewModel.showBlankConfirmation();
      await fixture.viewModel.confirmPending();

      expect(fixture.viewModel.uiState).assertEqual(TodayUiState.TODAY_FINAL_REVISED);
      expect(fixture.viewModel.record !== null && fixture.viewModel.record.recordType === RecordType.BLANK).assertTrue();
      expect(fixture.viewModel.record !== null && fixture.viewModel.record.revisionUsed).assertTrue();
    });

    it('keepsTheRevisionAvailableAfterStorageFailure', 0, async () => {
      const fixture = new ViewModelFixture(new FailingOnceRevisionRepository());
      await fixture.viewModel.load();
      fixture.viewModel.setContent('静');
      fixture.viewModel.showWordConfirmation();
      await fixture.viewModel.confirmPending();

      fixture.clock.setTime(1500);
      fixture.viewModel.startRevision();
      fixture.viewModel.setContent('雨');
      fixture.viewModel.showWordConfirmation();
      await fixture.viewModel.confirmPending();
      expect(fixture.viewModel.uiState).assertEqual(TodayUiState.TODAY_REVISION_ERROR);

      const unchanged = await fixture.repository.findByDate('2026-08-18');
      expect(unchanged !== null && !unchanged.revisionUsed).assertTrue();
      await fixture.viewModel.retrySave();
      expect(fixture.viewModel.uiState).assertEqual(TodayUiState.TODAY_FINAL_REVISED);
      expect(fixture.viewModel.record !== null && fixture.viewModel.record.content === '雨').assertTrue();
    });

    it('loadsAnExpiredRecordAsFinal', 0, async () => {
      const fixture = new ViewModelFixture();
      await fixture.viewModel.load();
      fixture.viewModel.setContent('静');
      fixture.viewModel.showWordConfirmation();
      await fixture.viewModel.confirmPending();

      fixture.clock.setTime(2001);
      await fixture.viewModel.load();
      expect(fixture.viewModel.uiState).assertEqual(TodayUiState.TODAY_FINAL_EXPIRED);
    });
  });
}
