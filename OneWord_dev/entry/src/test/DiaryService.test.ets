import { describe, expect, it } from '@ohos/hypium';
import { DailyRecord, DiaryEntryInput, RecordType, RevisionStatus } from '../main/ets/model/DailyRecord';
import { DiaryError, DiaryErrorCode } from '../main/ets/model/DiaryError';
import { DiaryRepository, InMemoryDiaryRepository } from '../main/ets/repository/DiaryRepository';
import { DiaryService } from '../main/ets/service/DiaryService';
import { DiaryTextRules } from '../main/ets/service/DiaryTextRules';
import { FixedClock } from '../main/ets/utils/Clock';
import { FixedLocalTimeResolver } from '../main/ets/utils/LocalTimeResolver';

class FailingOnceDiaryRepository extends InMemoryDiaryRepository {
  private shouldFail: boolean = true;

  async updateRevision(record: DailyRecord): Promise<boolean> {
    if (this.shouldFail) {
      this.shouldFail = false;
      throw new Error('simulated storage failure');
    }
    return super.updateRevision(record);
  }
}

function createWord(content: string): DiaryEntryInput {
  return {
    recordType: RecordType.WORD,
    content: content,
    note: null,
    fontId: 'system_serif_dev',
    paperId: 'warm_paper_dev'
  };
}

function createBlank(): DiaryEntryInput {
  return {
    recordType: RecordType.BLANK,
    content: null,
    note: null,
    fontId: 'system_serif_dev',
    paperId: 'warm_paper_dev'
  };
}

function createService(repository: DiaryRepository, clock: FixedClock): DiaryService {
  return new DiaryService(
    repository,
    clock,
    new FixedLocalTimeResolver({
      localDate: '2026-08-18',
      timezoneOffsetMinutes: 480,
      revisionDeadlineAt: 2000
    }),
    new DiaryTextRules()
  );
}

export default function diaryServiceTest(): void {
  describe('DiaryService', () => {
    it('storesOnlyOneRecordForTheLocalDay', 0, async () => {
      const repository = new InMemoryDiaryRepository();
      const service = createService(repository, new FixedClock(1000));
      const record = await service.submit(createWord('静'));
      expect(record.localDate).assertEqual('2026-08-18');
      expect(record.content).assertEqual('静');

      let errorCode: string = '';
      try {
        await service.submit(createWord('雨'));
      } catch (error) {
        if (error instanceof DiaryError) {
          errorCode = error.code;
        }
      }
      expect(errorCode).assertEqual(DiaryErrorCode.ALREADY_RECORDED);
    });

    it('allowsExactlyOneRevisionIncludingWordToBlank', 0, async () => {
      const repository = new InMemoryDiaryRepository();
      const clock = new FixedClock(1000);
      const service = createService(repository, clock);
      await service.submit(createWord('静'));

      clock.setTime(1500);
      const revised = await service.revise('2026-08-18', createBlank());
      expect(revised.recordType).assertEqual(RecordType.BLANK);
      expect(revised.content === null).assertTrue();
      expect(service.getRevisionStatus(revised)).assertEqual(RevisionStatus.USED);

      let errorCode: string = '';
      try {
        await service.revise('2026-08-18', createWord('雨'));
      } catch (error) {
        if (error instanceof DiaryError) {
          errorCode = error.code;
        }
      }
      expect(errorCode).assertEqual(DiaryErrorCode.REVISION_USED);
    });

    it('doesNotConsumeRevisionWhenStorageFails', 0, async () => {
      const repository = new FailingOnceDiaryRepository();
      const clock = new FixedClock(1000);
      const service = createService(repository, clock);
      await service.submit(createWord('静'));

      clock.setTime(1500);
      try {
        await service.revise('2026-08-18', createWord('雨'));
      } catch (error) {
        // The simulated transaction is expected to fail once.
      }

      const unchanged = await repository.findByDate('2026-08-18');
      expect(unchanged !== null && !unchanged.revisionUsed).assertTrue();
      const revised = await service.revise('2026-08-18', createWord('雨'));
      expect(revised.content).assertEqual('雨');
      expect(revised.revisionUsed).assertTrue();
    });

    it('rejectsRevisionAfterLocalDeadline', 0, async () => {
      const repository = new InMemoryDiaryRepository();
      const clock = new FixedClock(1000);
      const service = createService(repository, clock);
      const record = await service.submit(createWord('静'));

      clock.setTime(2001);
      expect(service.getRevisionStatus(record)).assertEqual(RevisionStatus.EXPIRED);
      let errorCode: string = '';
      try {
        await service.revise('2026-08-18', createWord('雨'));
      } catch (error) {
        if (error instanceof DiaryError) {
          errorCode = error.code;
        }
      }
      expect(errorCode).assertEqual(DiaryErrorCode.REVISION_EXPIRED);
    });
  });
}
