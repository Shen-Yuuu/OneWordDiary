import { describe, expect, it } from '@ohos/hypium';
import { StylePresetId } from '../main/ets/constants/StyleTokens';
import { FontPresetId } from '../main/ets/constants/FontCatalog';
import { BackgroundImageStore } from '../main/ets/model/BackgroundImage';
import { DailyRecord } from '../main/ets/model/DailyRecord';
import { AppSettings, DEFAULT_APP_SETTINGS, ReminderSettings } from '../main/ets/model/Settings';
import { TodayUiState } from '../main/ets/model/TodayUiState';
import { DiaryRepository, InMemoryDiaryRepository } from '../main/ets/repository/DiaryRepository';
import { SettingsRepository } from '../main/ets/repository/SettingsRepository';
import { CompletionFeedback, NoopCompletionFeedback } from '../main/ets/service/CompletionFeedback';
import { DiaryService } from '../main/ets/service/DiaryService';
import { DiaryTextRules } from '../main/ets/service/DiaryTextRules';
import { FixedClock } from '../main/ets/utils/Clock';
import { FixedLocalTimeResolver } from '../main/ets/utils/LocalTimeResolver';
import { TodayViewModel } from '../main/ets/viewmodel/TodayViewModel';

const FIRST_IMAGE_ID: string = '11111111111111111111111111111111.jpg';
const SECOND_IMAGE_ID: string = '22222222222222222222222222222222.jpg';

class MemorySettingsRepository implements SettingsRepository {
  async load(): Promise<AppSettings> {
    return DEFAULT_APP_SETTINGS;
  }

  async saveStylePresetId(stylePresetId: StylePresetId): Promise<void> {
  }

  async saveFontPresetId(fontPresetId: FontPresetId): Promise<void> {
  }

  async saveReminder(reminder: ReminderSettings): Promise<void> {
  }

  async isResetPending(): Promise<boolean> {
    return false;
  }

  async savePrivacyPolicyAcceptedVersion(version: string): Promise<void> {
  }

  async markResetPending(): Promise<void> {
  }

  async reset(): Promise<void> {
  }
}

class MemoryBackgroundImageStore implements BackgroundImageStore {
  readonly removedIds: string[] = [];
  private importIds: string[] = [];
  failNextImport: boolean = false;

  enqueueImport(id: string): void {
    this.importIds.push(id);
  }

  async importFromUri(uri: string): Promise<string> {
    if (this.failNextImport) {
      this.failNextImport = false;
      throw new Error('unsupported animated image');
    }
    if (this.importIds.length === 0) {
      throw new Error('missing fake image');
    }
    const id = this.importIds[0];
    this.importIds.splice(0, 1);
    return id;
  }

  resolveUri(id: string | null | undefined): string {
    return id === null || id === undefined ? '' : 'file:///' + id;
  }

  remove(id: string): void {
    this.removedIds.push(id);
  }

  clearAll(): void {
  }
}

class DeferredBackgroundImageStore implements BackgroundImageStore {
  readonly removedIds: string[] = [];
  private resolvePending: ((id: string) => void) | null = null;

  importFromUri(uri: string): Promise<string> {
    return new Promise<string>((resolve) => {
      this.resolvePending = resolve;
    });
  }

  finishImport(id: string): void {
    if (this.resolvePending !== null) {
      const resolve = this.resolvePending;
      this.resolvePending = null;
      resolve(id);
    }
  }

  resolveUri(id: string | null | undefined): string {
    return id === null || id === undefined ? '' : 'file:///' + id;
  }

  remove(id: string): void {
    this.removedIds.push(id);
  }

  clearAll(): void {
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

class DeferredInsertRepository extends InMemoryDiaryRepository {
  private readonly insertGate: Promise<void>;
  private releaseInsert: () => void = (): void => {
  };

  constructor() {
    super();
    this.insertGate = new Promise<void>((resolve) => {
      this.releaseInsert = (): void => {
        resolve();
      };
    });
  }

  async insert(record: DailyRecord): Promise<void> {
    await this.insertGate;
    return super.insert(record);
  }

  finishInsert(): void {
    this.releaseInsert();
  }
}

class FailingPostCommitCountRepository extends InMemoryDiaryRepository {
  async countAll(): Promise<number> {
    const count = await super.countAll();
    if (count > 0) {
      throw new Error('simulated count refresh failure');
    }
    return count;
  }
}

class ThrowingCompletionFeedback implements CompletionFeedback {
  playRecordCommitted(): void {
    throw new Error('simulated feedback failure');
  }
}

class BackgroundFixture {
  readonly repository: DiaryRepository;
  readonly clock: FixedClock = new FixedClock(1000);
  readonly resolver: FixedLocalTimeResolver = new FixedLocalTimeResolver({
    localDate: '2026-08-18',
    timezoneOffsetMinutes: 480,
    revisionDeadlineAt: 2000
  });
  readonly viewModel: TodayViewModel;

  constructor(
    store: BackgroundImageStore,
    repository: DiaryRepository = new InMemoryDiaryRepository(),
    completionFeedback: CompletionFeedback = new NoopCompletionFeedback()
  ) {
    this.repository = repository;
    const rules = new DiaryTextRules();
    this.viewModel = new TodayViewModel(
      new DiaryService(repository, this.clock, this.resolver, rules),
      new MemorySettingsRepository(),
      this.clock,
      this.resolver,
      rules,
      completionFeedback,
      store
    );
  }
}

export default function todayBackgroundLifecycleTest(): void {
  describe('TodayBackgroundLifecycle', () => {
    it('keepsImportedDraftAcrossPickerResumeAndCleansItOnForcedRefresh', 0, async () => {
      const store = new MemoryBackgroundImageStore();
      store.enqueueImport(FIRST_IMAGE_ID);
      const fixture = new BackgroundFixture(store);
      await fixture.viewModel.load();
      await fixture.viewModel.selectBackgroundFromUri('picker://first');

      await fixture.viewModel.load(true);
      expect(fixture.viewModel.draftBackgroundImageId).assertEqual(FIRST_IMAGE_ID);
      expect(fixture.viewModel.backgroundImageUri).assertEqual('file:///' + FIRST_IMAGE_ID);

      await fixture.viewModel.load();
      expect(fixture.viewModel.draftBackgroundImageId === null).assertTrue();
      expect(store.removedIds.includes(FIRST_IMAGE_ID)).assertTrue();
    });

    it('doesNotDeleteCommittedImageWhenRevisionReplacementIsCancelled', 0, async () => {
      const store = new MemoryBackgroundImageStore();
      store.enqueueImport(FIRST_IMAGE_ID);
      store.enqueueImport(SECOND_IMAGE_ID);
      const fixture = new BackgroundFixture(store);
      await fixture.viewModel.load();
      fixture.viewModel.setContent('Y');
      await fixture.viewModel.selectBackgroundFromUri('picker://first');
      fixture.viewModel.showWordConfirmation();
      await fixture.viewModel.confirmPending();

      fixture.clock.setTime(1500);
      fixture.viewModel.startRevision();
      await fixture.viewModel.selectBackgroundFromUri('picker://second');
      fixture.viewModel.cancelRevision();

      expect(store.removedIds.includes(SECOND_IMAGE_ID)).assertTrue();
      expect(store.removedIds.includes(FIRST_IMAGE_ID)).assertFalse();
      expect(fixture.viewModel.backgroundImageUri).assertEqual('file:///' + FIRST_IMAGE_ID);
    });

    it('retainsReplacementForRetryAndDeletesOldImageOnlyAfterCommit', 0, async () => {
      const store = new MemoryBackgroundImageStore();
      store.enqueueImport(FIRST_IMAGE_ID);
      store.enqueueImport(SECOND_IMAGE_ID);
      const fixture = new BackgroundFixture(store, new FailingOnceRevisionRepository());
      await fixture.viewModel.load();
      fixture.viewModel.setContent('Y');
      await fixture.viewModel.selectBackgroundFromUri('picker://first');
      fixture.viewModel.showWordConfirmation();
      await fixture.viewModel.confirmPending();

      fixture.clock.setTime(1500);
      fixture.viewModel.startRevision();
      fixture.viewModel.setContent('R');
      await fixture.viewModel.selectBackgroundFromUri('picker://second');
      fixture.viewModel.showWordConfirmation();
      await fixture.viewModel.confirmPending();
      expect(fixture.viewModel.uiState).assertEqual(TodayUiState.TODAY_REVISION_ERROR);
      expect(fixture.viewModel.draftBackgroundImageId).assertEqual(SECOND_IMAGE_ID);
      expect(store.removedIds.includes(FIRST_IMAGE_ID)).assertFalse();
      expect(store.removedIds.includes(SECOND_IMAGE_ID)).assertFalse();

      await fixture.viewModel.retrySave();
      expect(fixture.viewModel.record !== null &&
        fixture.viewModel.record.backgroundImageId === SECOND_IMAGE_ID).assertTrue();
      expect(store.removedIds.includes(FIRST_IMAGE_ID)).assertTrue();
      expect(store.removedIds.includes(SECOND_IMAGE_ID)).assertFalse();
    });

    it('persistsBackgroundRemovalAndDeletesOldImageOnlyAfterRevisionCommit', 0, async () => {
      const store = new MemoryBackgroundImageStore();
      store.enqueueImport(FIRST_IMAGE_ID);
      const fixture = new BackgroundFixture(store);
      await fixture.viewModel.load();
      fixture.viewModel.setContent('Y');
      await fixture.viewModel.selectBackgroundFromUri('picker://first');
      fixture.viewModel.showWordConfirmation();
      await fixture.viewModel.confirmPending();

      fixture.clock.setTime(1500);
      fixture.viewModel.startRevision();
      fixture.viewModel.removeBackgroundImage();
      fixture.viewModel.showWordConfirmation();
      expect(store.removedIds.includes(FIRST_IMAGE_ID)).assertFalse();
      await fixture.viewModel.confirmPending();

      const saved = await fixture.repository.findByDate('2026-08-18');
      expect(saved !== null && saved.backgroundImageId === null).assertTrue();
      expect(store.removedIds.includes(FIRST_IMAGE_ID)).assertTrue();
    });

    it('finishesCommittedImageSaveWhenCountAndFeedbackRefreshFail', 0, async () => {
      const store = new MemoryBackgroundImageStore();
      store.enqueueImport(FIRST_IMAGE_ID);
      const repository = new FailingPostCommitCountRepository();
      const fixture = new BackgroundFixture(store, repository, new ThrowingCompletionFeedback());
      await fixture.viewModel.load();
      fixture.viewModel.setContent('Y');
      await fixture.viewModel.selectBackgroundFromUri('picker://first');
      fixture.viewModel.showWordConfirmation();
      await fixture.viewModel.confirmPending();

      const saved = await repository.findByDate('2026-08-18');
      expect(saved !== null && saved.backgroundImageId === FIRST_IMAGE_ID).assertTrue();
      expect(fixture.viewModel.uiState).assertEqual(TodayUiState.TODAY_RECORDED_WORD_EDITABLE);
      expect(fixture.viewModel.errorMessage).assertEqual('');
      expect(store.removedIds.includes(FIRST_IMAGE_ID)).assertFalse();
    });

    it('discardsPickerCompletionAfterDayRollover', 0, async () => {
      const store = new DeferredBackgroundImageStore();
      const fixture = new BackgroundFixture(store);
      await fixture.viewModel.load();
      const selection = fixture.viewModel.selectBackgroundFromUri('picker://pending');
      fixture.clock.setTime(3000);
      fixture.resolver.setSnapshot({
        localDate: '2026-08-19',
        timezoneOffsetMinutes: 480,
        revisionDeadlineAt: 4000
      });
      store.finishImport(FIRST_IMAGE_ID);
      await selection;

      expect(fixture.viewModel.draftBackgroundImageId === null).assertTrue();
      expect(store.removedIds.includes(FIRST_IMAGE_ID)).assertTrue();
      expect(await fixture.repository.countAll()).assertEqual(0);
      expect(fixture.viewModel.localDate).assertEqual('2026-08-19');
    });

    it('preventsOldDayDraftFromBeingCommittedAfterMidnight', 0, async () => {
      const store = new MemoryBackgroundImageStore();
      store.enqueueImport(FIRST_IMAGE_ID);
      const fixture = new BackgroundFixture(store);
      await fixture.viewModel.load();
      fixture.viewModel.setContent('Y');
      await fixture.viewModel.selectBackgroundFromUri('picker://first');
      fixture.viewModel.showWordConfirmation();

      fixture.clock.setTime(3000);
      fixture.resolver.setSnapshot({
        localDate: '2026-08-19',
        timezoneOffsetMinutes: 480,
        revisionDeadlineAt: 4000
      });
      await fixture.viewModel.confirmPending();

      expect(await fixture.repository.countAll()).assertEqual(0);
      expect(fixture.viewModel.localDate).assertEqual('2026-08-19');
      expect(store.removedIds.includes(FIRST_IMAGE_ID)).assertTrue();
    });

    it('keepsExistingBackgroundWhenImportFails', 0, async () => {
      const store = new MemoryBackgroundImageStore();
      store.enqueueImport(FIRST_IMAGE_ID);
      const fixture = new BackgroundFixture(store);
      await fixture.viewModel.load();
      fixture.viewModel.setContent('Y');
      await fixture.viewModel.selectBackgroundFromUri('picker://first');
      store.failNextImport = true;
      await fixture.viewModel.selectBackgroundFromUri('picker://animated');

      expect(fixture.viewModel.draftBackgroundImageId).assertEqual(FIRST_IMAGE_ID);
      expect(fixture.viewModel.backgroundError).assertEqual('unsupported animated image');
      expect(store.removedIds.includes(FIRST_IMAGE_ID)).assertFalse();
    });

    it('cleansReplacementAndLeavesExpiredRevisionInFinalState', 0, async () => {
      const store = new MemoryBackgroundImageStore();
      store.enqueueImport(FIRST_IMAGE_ID);
      store.enqueueImport(SECOND_IMAGE_ID);
      const fixture = new BackgroundFixture(store);
      await fixture.viewModel.load();
      fixture.viewModel.setContent('Y');
      await fixture.viewModel.selectBackgroundFromUri('picker://first');
      fixture.viewModel.showWordConfirmation();
      await fixture.viewModel.confirmPending();

      fixture.clock.setTime(1500);
      fixture.viewModel.startRevision();
      fixture.viewModel.setContent('R');
      await fixture.viewModel.selectBackgroundFromUri('picker://second');
      fixture.viewModel.showWordConfirmation();
      fixture.clock.setTime(2001);
      await fixture.viewModel.confirmPending();

      expect(fixture.viewModel.uiState).assertEqual(TodayUiState.TODAY_FINAL_EXPIRED);
      expect(fixture.viewModel.record !== null &&
        fixture.viewModel.record.backgroundImageId === FIRST_IMAGE_ID).assertTrue();
      expect(store.removedIds.includes(SECOND_IMAGE_ID)).assertTrue();
      expect(store.removedIds.includes(FIRST_IMAGE_ID)).assertFalse();
    });

    it('ignoresBackAndRefreshMutationsWhileImageCommitIsInFlight', 0, async () => {
      const store = new MemoryBackgroundImageStore();
      store.enqueueImport(FIRST_IMAGE_ID);
      const repository = new DeferredInsertRepository();
      const fixture = new BackgroundFixture(store, repository);
      await fixture.viewModel.load();
      fixture.viewModel.setContent('R');
      await fixture.viewModel.selectBackgroundFromUri('picker://first');
      fixture.viewModel.showWordConfirmation();

      const commit = fixture.viewModel.confirmPending();
      fixture.viewModel.cancelConfirmation();
      fixture.viewModel.cancelRevision();
      fixture.viewModel.returnFromError();
      fixture.viewModel.removeBackgroundImage();
      fixture.viewModel.setContent('X');
      fixture.viewModel.setNote('changed');
      store.enqueueImport(SECOND_IMAGE_ID);
      await fixture.viewModel.selectBackgroundFromUri('picker://second');
      await fixture.viewModel.load();
      repository.finishInsert();
      await commit;

      const saved = await repository.findByDate('2026-08-18');
      expect(saved !== null && saved.backgroundImageId === FIRST_IMAGE_ID).assertTrue();
      expect(saved !== null && saved.content === 'R').assertTrue();
      expect(store.removedIds.includes(FIRST_IMAGE_ID)).assertFalse();
      expect(fixture.viewModel.uiState).assertEqual(TodayUiState.TODAY_RECORDED_WORD_EDITABLE);
    });
  });
}
