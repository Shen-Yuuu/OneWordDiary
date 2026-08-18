import { describe, expect, it } from '@ohos/hypium';
import { DailyRecord, RecordType } from '../main/ets/model/DailyRecord';
import { DetailUiState } from '../main/ets/model/DetailUiState';
import { ScrollItemSide } from '../main/ets/model/ScrollDisplayItem';
import { ScrollUiState } from '../main/ets/model/ScrollUiState';
import { DiaryRepository, InMemoryDiaryRepository } from '../main/ets/repository/DiaryRepository';
import { DiaryService } from '../main/ets/service/DiaryService';
import { DiaryTextRules } from '../main/ets/service/DiaryTextRules';
import { FixedClock } from '../main/ets/utils/Clock';
import { DiaryDateFormatter } from '../main/ets/utils/DiaryDateFormatter';
import { FixedLocalTimeResolver } from '../main/ets/utils/LocalTimeResolver';
import { DetailViewModel } from '../main/ets/viewmodel/DetailViewModel';
import { ScrollViewModel } from '../main/ets/viewmodel/ScrollViewModel';

class FailingPageRepository extends InMemoryDiaryRepository {
  private readonly failingCall: number;
  private pageCallCount: number = 0;

  constructor(failingCall: number) {
    super();
    this.failingCall = failingCall;
  }

  async findPageBefore(exclusiveDate: string | null, limit: number): Promise<DailyRecord[]> {
    this.pageCallCount++;
    if (this.pageCallCount === this.failingCall) {
      throw new Error('simulated page failure');
    }
    return super.findPageBefore(exclusiveDate, limit);
  }
}

class FailingDetailRepository extends InMemoryDiaryRepository {
  async findByDate(localDate: string): Promise<DailyRecord | null> {
    throw new Error('simulated detail failure');
  }
}

function createRecord(
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

function createService(repository: DiaryRepository): DiaryService {
  return new DiaryService(
    repository,
    new FixedClock(1000),
    new FixedLocalTimeResolver({
      localDate: '2026-08-18',
      timezoneOffsetMinutes: 480,
      revisionDeadlineAt: 2000
    }),
    new DiaryTextRules()
  );
}

async function seed(repository: DiaryRepository, records: DailyRecord[]): Promise<void> {
  for (const record of records) {
    await repository.insert(record);
  }
}

export default function scrollDetailTest(): void {
  describe('ScrollAndDetail', () => {
    it('queriesDescendingPagesWithAnExclusiveDateCursor', 0, async () => {
      const repository = new InMemoryDiaryRepository();
      await seed(repository, [
        createRecord('2026-08-15', RecordType.WORD, '远'),
        createRecord('2026-08-18', RecordType.WORD, '微风正好'),
        createRecord('2026-08-16', RecordType.BLANK, null),
        createRecord('2026-08-17', RecordType.WORD, '雨')
      ]);

      const first = await repository.findPageBefore(null, 2);
      expect(first.length).assertEqual(2);
      expect(first[0].localDate).assertEqual('2026-08-18');
      expect(first[1].localDate).assertEqual('2026-08-17');

      const second = await repository.findPageBefore(first[1].localDate, 2);
      expect(second.length).assertEqual(2);
      expect(second[0].localDate).assertEqual('2026-08-16');
      expect(second[1].localDate).assertEqual('2026-08-15');
    });

    it('loadsAnEmptyScroll', 0, async () => {
      const repository = new InMemoryDiaryRepository();
      const viewModel = new ScrollViewModel(createService(repository), 30, new DiaryDateFormatter());

      await viewModel.load();
      expect(viewModel.uiState).assertEqual(ScrollUiState.EMPTY);
      expect(viewModel.dataSource.totalCount()).assertEqual(0);
      expect(viewModel.totalCount).assertEqual(0);
    });

    it('buildsMonthSectionsAndKeepsBlankDistinct', 0, async () => {
      const repository = new InMemoryDiaryRepository();
      await seed(repository, [
        createRecord('2026-07-30', RecordType.WORD, '远', null, 'system_sans_dev', 'plain_ash_dev'),
        createRecord('2026-08-17', RecordType.BLANK, null),
        createRecord('2026-08-18', RecordType.WORD, '微风正好')
      ]);
      const viewModel = new ScrollViewModel(createService(repository), 30, new DiaryDateFormatter());

      await viewModel.load();
      const items = viewModel.dataSource.snapshot();
      expect(viewModel.uiState).assertEqual(ScrollUiState.READY);
      expect(items.length).assertEqual(3);
      expect(items[0].showMonthHeader).assertTrue();
      expect(items[0].monthLabel).assertEqual('二〇二六年八月');
      expect(items[0].contentCount).assertEqual(4);
      expect(items[0].side).assertEqual(ScrollItemSide.LEFT);
      expect(items[1].showMonthHeader).assertFalse();
      expect(items[1].recordType).assertEqual(RecordType.BLANK);
      expect(items[1].side).assertEqual(ScrollItemSide.CENTER);
      expect(items[2].showMonthHeader).assertTrue();
      expect(items[2].fontId).assertEqual('system_sans_dev');
      expect(items[2].paperId).assertEqual('plain_ash_dev');
      expect(items[2].side).assertEqual(ScrollItemSide.RIGHT);
    });

    it('appendsWithoutDuplicatesAndStopsAtTheEnd', 0, async () => {
      const repository = new InMemoryDiaryRepository();
      await seed(repository, [
        createRecord('2026-08-16', RecordType.WORD, '远'),
        createRecord('2026-08-17', RecordType.BLANK, null),
        createRecord('2026-08-18', RecordType.WORD, '微风正好')
      ]);
      const viewModel = new ScrollViewModel(createService(repository), 2, new DiaryDateFormatter());

      await viewModel.load();
      expect(viewModel.dataSource.totalCount()).assertEqual(2);
      expect(viewModel.hasMore).assertTrue();
      await viewModel.loadMore();
      expect(viewModel.dataSource.totalCount()).assertEqual(3);
      expect(viewModel.hasMore).assertFalse();
      expect(viewModel.dataSource.snapshot()[2].localDate).assertEqual('2026-08-16');
    });

    it('keepsLoadedItemsWhenAppendingFails', 0, async () => {
      const repository = new FailingPageRepository(2);
      await seed(repository, [
        createRecord('2026-08-16', RecordType.WORD, '远'),
        createRecord('2026-08-17', RecordType.WORD, '雨'),
        createRecord('2026-08-18', RecordType.WORD, '微风正好')
      ]);
      const viewModel = new ScrollViewModel(createService(repository), 2, new DiaryDateFormatter());

      await viewModel.load();
      await viewModel.loadMore();
      expect(viewModel.uiState).assertEqual(ScrollUiState.READY);
      expect(viewModel.dataSource.totalCount()).assertEqual(2);
      expect(viewModel.loadMoreError.length > 0).assertTrue();
    });

    it('reportsTheInitialScrollFailure', 0, async () => {
      const repository = new FailingPageRepository(1);
      const viewModel = new ScrollViewModel(createService(repository), 2, new DiaryDateFormatter());

      await viewModel.load();
      expect(viewModel.uiState).assertEqual(ScrollUiState.INITIAL_ERROR);
      expect(viewModel.dataSource.totalCount()).assertEqual(0);
    });

    it('loadsWordBlankAndMissingDetailStates', 0, async () => {
      const repository = new InMemoryDiaryRepository();
      await seed(repository, [
        createRecord('2026-08-17', RecordType.BLANK, null),
        createRecord('2026-08-18', RecordType.WORD, '微风正好', '风停在窗边')
      ]);
      const viewModel = new DetailViewModel(createService(repository), new DiaryDateFormatter());

      await viewModel.load('2026-08-18');
      expect(viewModel.uiState).assertEqual(DetailUiState.WORD);
      expect(viewModel.contentCount).assertEqual(4);
      expect(viewModel.record !== null && viewModel.record.note === '风停在窗边').assertTrue();
      expect(viewModel.dateLabel).assertEqual('8月18日 星期二');

      await viewModel.load('2026-08-17');
      expect(viewModel.uiState).assertEqual(DetailUiState.BLANK);
      expect(viewModel.record !== null && viewModel.record.content === null).assertTrue();

      await viewModel.load('2026-08-16');
      expect(viewModel.uiState).assertEqual(DetailUiState.NOT_FOUND);
      expect(viewModel.contentCount).assertEqual(0);
    });

    it('reportsTheDetailLoadFailure', 0, async () => {
      const viewModel = new DetailViewModel(
        createService(new FailingDetailRepository()),
        new DiaryDateFormatter()
      );

      await viewModel.load('2026-08-18');
      expect(viewModel.uiState).assertEqual(DetailUiState.LOAD_ERROR);
      expect(viewModel.record === null).assertTrue();
    });
  });
}
