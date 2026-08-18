import { describe, expect, it } from '@ohos/hypium';
import { DiaryEntryInput, RecordType } from '../main/ets/model/DailyRecord';
import { DiaryError, DiaryErrorCode } from '../main/ets/model/DiaryError';
import { InMemoryDiaryRepository } from '../main/ets/repository/DiaryRepository';
import { DiaryService } from '../main/ets/service/DiaryService';
import { DiaryTextRules } from '../main/ets/service/DiaryTextRules';
import { FixedClock } from '../main/ets/utils/Clock';
import { FixedLocalTimeResolver } from '../main/ets/utils/LocalTimeResolver';

export default function diaryConcurrencyTest(): void {
  describe('DiaryConcurrency', () => {
    it('opensOnlyOneTransactionForConcurrentSameDaySubmissions', 0, async () => {
      const repository = new InMemoryDiaryRepository();
      const service = new DiaryService(
        repository,
        new FixedClock(1000),
        new FixedLocalTimeResolver({
          localDate: '2026-08-18',
          timezoneOffsetMinutes: 480,
          revisionDeadlineAt: 2000
        }),
        new DiaryTextRules()
      );
      const input: DiaryEntryInput = {
        recordType: RecordType.WORD,
        content: '静',
        note: null,
        fontId: 'system_serif_dev',
        paperId: 'warm_paper_dev'
      };

      const firstSubmission: Promise<void> = service.submit(input).then((): void => {
      });
      let secondErrorCode: string = '';
      try {
        await service.submit(input);
      } catch (error) {
        if (error instanceof DiaryError) {
          secondErrorCode = error.code;
        }
      }
      await firstSubmission;

      expect(secondErrorCode).assertEqual(DiaryErrorCode.ALREADY_RECORDED);
      const stored = await repository.findByDate('2026-08-18');
      expect(stored !== null && stored.content === '静').assertTrue();
    });
  });
}
