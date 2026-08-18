import { describe, expect, it } from '@ohos/hypium';
import { DiaryEntryInput, RecordType, RevisionStatus } from '../main/ets/model/DailyRecord';
import { InMemoryDiaryRepository } from '../main/ets/repository/DiaryRepository';
import { DiaryService } from '../main/ets/service/DiaryService';
import { DiaryTextRules } from '../main/ets/service/DiaryTextRules';
import { FixedClock } from '../main/ets/utils/Clock';
import { FixedLocalTimeResolver } from '../main/ets/utils/LocalTimeResolver';

export default function diaryTimePolicyTest(): void {
  describe('DiaryTimePolicy', () => {
    it('keepsTheSubmittedDeadlineAcrossClockRollbackAndTimezoneChange', 0, async () => {
      const repository = new InMemoryDiaryRepository();
      const clock = new FixedClock(1500);
      const resolver = new FixedLocalTimeResolver({
        localDate: '2026-08-18',
        timezoneOffsetMinutes: 480,
        revisionDeadlineAt: 2000
      });
      const service = new DiaryService(repository, clock, resolver, new DiaryTextRules());
      const input: DiaryEntryInput = {
        recordType: RecordType.WORD,
        content: '静',
        note: null,
        fontId: 'system_serif_dev',
        paperId: 'warm_paper_dev'
      };

      const record = await service.submit(input);
      resolver.setSnapshot({
        localDate: '2026-08-18',
        timezoneOffsetMinutes: -300,
        revisionDeadlineAt: 9000
      });
      clock.setTime(1200);
      expect(service.getRevisionStatus(record)).assertEqual(RevisionStatus.AVAILABLE);
      expect(record.submittedTimezoneOffset).assertEqual(480);
      expect(record.revisionDeadlineAt).assertEqual(2000);

      clock.setTime(2001);
      expect(service.getRevisionStatus(record)).assertEqual(RevisionStatus.EXPIRED);
    });
  });
}
