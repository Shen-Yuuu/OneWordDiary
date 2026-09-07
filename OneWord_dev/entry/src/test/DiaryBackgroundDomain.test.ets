import { describe, expect, it } from '@ohos/hypium';
import { BackgroundImageError } from '../main/ets/model/BackgroundImage';
import { DiaryEntryInput, RecordType } from '../main/ets/model/DailyRecord';
import { InMemoryDiaryRepository } from '../main/ets/repository/DiaryRepository';
import { DiaryService } from '../main/ets/service/DiaryService';
import { DiaryTextRules } from '../main/ets/service/DiaryTextRules';
import { FixedClock } from '../main/ets/utils/Clock';
import { FixedLocalTimeResolver } from '../main/ets/utils/LocalTimeResolver';

const FIRST_IMAGE_ID: string = '11111111111111111111111111111111.jpg';
const SECOND_IMAGE_ID: string = '22222222222222222222222222222222.png';

function wordInput(content: string, backgroundImageId?: string | null): DiaryEntryInput {
  return {
    recordType: RecordType.WORD,
    content: content,
    note: null,
    fontId: 'system_serif_dev',
    paperId: 'warm_paper_dev',
    backgroundImageId: backgroundImageId
  };
}

export default function diaryBackgroundDomainTest(): void {
  describe('DiaryBackgroundDomain', () => {
    it('normalizesLegacyMissingImageToNullAndRejectsExternalPaths', 0, () => {
      const rules = new DiaryTextRules();
      const legacy = rules.normalizeEntry(wordInput('Y'));
      expect(legacy.backgroundImageId === null).assertTrue();

      let rejected: boolean = false;
      try {
        rules.normalizeEntry(wordInput('R', 'file:///data/source.jpg'));
      } catch (error) {
        rejected = error instanceof BackgroundImageError;
      }
      expect(rejected).assertTrue();
    });

    it('keepsBackgroundsIsolatedByLocalDate', 0, async () => {
      const repository = new InMemoryDiaryRepository();
      const clock = new FixedClock(1000);
      const resolver = new FixedLocalTimeResolver({
        localDate: '2026-08-18',
        timezoneOffsetMinutes: 480,
        revisionDeadlineAt: 2000
      });
      const service = new DiaryService(repository, clock, resolver, new DiaryTextRules());
      await service.submit(wordInput('Y', FIRST_IMAGE_ID));

      clock.setTime(3000);
      resolver.setSnapshot({
        localDate: '2026-08-19',
        timezoneOffsetMinutes: 480,
        revisionDeadlineAt: 4000
      });
      await service.submit(wordInput('S', SECOND_IMAGE_ID));

      const first = await repository.findByDate('2026-08-18');
      const second = await repository.findByDate('2026-08-19');
      expect(first !== null && first.backgroundImageId === FIRST_IMAGE_ID).assertTrue();
      expect(second !== null && second.backgroundImageId === SECOND_IMAGE_ID).assertTrue();
    });
  });
}
