import { describe, expect, it } from '@ohos/hypium';
import { StylePresetId } from '../main/ets/constants/StyleTokens';
import { DailyRecord, RecordType } from '../main/ets/model/DailyRecord';
import { DiaryShareMode, ShareDayKind } from '../main/ets/model/ShareModel';
import { ShareUiState } from '../main/ets/model/ShareUiState';
import { AppSettings, DEFAULT_APP_SETTINGS, ReminderSettings } from '../main/ets/model/Settings';
import { InMemoryDiaryRepository } from '../main/ets/repository/DiaryRepository';
import { SettingsRepository } from '../main/ets/repository/SettingsRepository';
import { DiaryService } from '../main/ets/service/DiaryService';
import { DiaryTextRules } from '../main/ets/service/DiaryTextRules';
import { FixedClock } from '../main/ets/utils/Clock';
import { DiaryDateFormatter } from '../main/ets/utils/DiaryDateFormatter';
import { FixedLocalTimeResolver } from '../main/ets/utils/LocalTimeResolver';
import { ShareViewModel } from '../main/ets/viewmodel/ShareViewModel';

class ShareMemorySettingsRepository implements SettingsRepository {
  private settings: AppSettings = DEFAULT_APP_SETTINGS;

  async load(): Promise<AppSettings> {
    return this.settings;
  }

  async saveStylePresetId(stylePresetId: StylePresetId): Promise<void> {
    this.settings = { stylePresetId: stylePresetId, reminder: this.settings.reminder };
  }

  async saveReminder(reminder: ReminderSettings): Promise<void> {
    this.settings = { stylePresetId: this.settings.stylePresetId, reminder: reminder };
  }

  async isResetPending(): Promise<boolean> {
    return false;
  }

  async markResetPending(): Promise<void> {
  }

  async reset(): Promise<void> {
    this.settings = DEFAULT_APP_SETTINGS;
  }
}

function createShareRecord(
  localDate: string,
  recordType: RecordType,
  content: string | null,
  note: string | null = null,
  fontId: string = 'system_serif_dev',
  paperId: string = 'warm_paper_dev'
): DailyRecord {
  return {
    localDate: localDate,
    content: content,
    note: note,
    recordType: recordType,
    fontId: fontId,
    paperId: paperId,
    submittedAt: 1000,
    submittedTimezoneOffset: 480,
    revisionDeadlineAt: 2000,
    revisedAt: null,
    revisionUsed: false,
    schemaVersion: 1
  };
}

class ShareFixture {
  readonly repository: InMemoryDiaryRepository = new InMemoryDiaryRepository();
  readonly viewModel: ShareViewModel;

  constructor() {
    const clock = new FixedClock(1000);
    const resolver = new FixedLocalTimeResolver({
      localDate: '2026-01-02',
      timezoneOffsetMinutes: 480,
      revisionDeadlineAt: 2000
    });
    this.viewModel = new ShareViewModel(
      new DiaryService(this.repository, clock, resolver, new DiaryTextRules()),
      new ShareMemorySettingsRepository(),
      clock,
      resolver,
      new DiaryDateFormatter()
    );
  }
}

export default function shareViewModelTest(): void {
  describe('ShareViewModel', () => {
    it('usesHistoricalContentAndStyleForSingleShare', 0, async () => {
      const fixture = new ShareFixture();
      await fixture.repository.insert(createShareRecord(
        '2026-01-01', RecordType.WORD, '静', '这是今天留下的一句备注',
        'system_sans_dev', 'plain_ash_dev'
      ));

      await fixture.viewModel.load(DiaryShareMode.SINGLE, '2026-01-01');

      expect(fixture.viewModel.uiState).assertEqual(ShareUiState.READY);
      expect(fixture.viewModel.singleData !== null && fixture.viewModel.singleData.content === '静').assertTrue();
      expect(fixture.viewModel.singleData !== null &&
        fixture.viewModel.singleData.note === '这是今天留下的一句备注').assertTrue();
      expect(fixture.viewModel.singleData !== null &&
        fixture.viewModel.singleData.fontId === 'system_sans_dev').assertTrue();
      expect(fixture.viewModel.activePaperId).assertEqual('plain_ash_dev');
    });

    it('buildsSevenNaturalDaysAcrossYearBoundary', 0, async () => {
      const fixture = new ShareFixture();
      await fixture.repository.insert(createShareRecord(
        '2026-01-02', RecordType.WORD, '新', '跨年的第一句备注'
      ));
      await fixture.repository.insert(createShareRecord('2026-01-01', RecordType.BLANK, null));

      await fixture.viewModel.load(DiaryShareMode.SEVEN_DAYS, null);

      expect(fixture.viewModel.sevenDays.length).assertEqual(7);
      expect(fixture.viewModel.sevenDays[0].localDate).assertEqual('2026-01-02');
      expect(fixture.viewModel.sevenDays[0].kind).assertEqual(ShareDayKind.WORD);
      expect(fixture.viewModel.sevenDays[0].note).assertEqual('跨年的第一句备注');
      expect(fixture.viewModel.sevenDays[0].showMonthHeader).assertTrue();
      expect(fixture.viewModel.sevenDays[0].monthLabel).assertEqual('二〇二六年一月');
      expect(fixture.viewModel.sevenDays[1].kind).assertEqual(ShareDayKind.BLANK);
      expect(fixture.viewModel.sevenDays[2].localDate).assertEqual('2025-12-31');
      expect(fixture.viewModel.sevenDays[2].kind).assertEqual(ShareDayKind.MISSING);
      expect(fixture.viewModel.sevenDays[2].showMonthHeader).assertTrue();
      expect(fixture.viewModel.sevenDays[2].monthLabel).assertEqual('二〇二五年十二月');
    });

    it('guardsRenderingAndAllowsRetryAfterFailure', 0, async () => {
      const fixture = new ShareFixture();
      await fixture.repository.insert(createShareRecord('2026-01-02', RecordType.WORD, '新'));
      await fixture.viewModel.load(DiaryShareMode.SINGLE, '2026-01-02');

      expect(fixture.viewModel.beginRendering()).assertTrue();
      expect(fixture.viewModel.beginRendering()).assertFalse();
      fixture.viewModel.failRendering();
      expect(fixture.viewModel.uiState).assertEqual(ShareUiState.RENDER_ERROR);
      expect(fixture.viewModel.beginRendering()).assertTrue();
      fixture.viewModel.finishRendering();
      expect(fixture.viewModel.uiState).assertEqual(ShareUiState.READY);
    });
  });
}
