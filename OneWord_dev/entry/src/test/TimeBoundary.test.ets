import { describe, expect, it } from '@ohos/hypium';
import { SystemLocalTimeResolver } from '../main/ets/utils/LocalTimeResolver';

export default function timeBoundaryTest(): void {
  describe('TimeBoundary', () => {
    const resolver: SystemLocalTimeResolver = new SystemLocalTimeResolver();

    it('keeps2358And2359InTheSameLocalDay', 0, () => {
      const at2358 = resolver.resolve(new Date(2026, 7, 18, 23, 58, 0, 0).getTime());
      const at2359 = resolver.resolve(new Date(2026, 7, 18, 23, 59, 59, 999).getTime());
      const expectedDeadline = new Date(2026, 7, 19, 0, 0, 0, 0).getTime() - 1;

      expect(at2358.localDate).assertEqual('2026-08-18');
      expect(at2359.localDate).assertEqual('2026-08-18');
      expect(at2358.revisionDeadlineAt).assertEqual(expectedDeadline);
      expect(at2359.revisionDeadlineAt).assertEqual(expectedDeadline);
    });

    it('movesToANewRecordKeyAfterLocalMidnight', 0, () => {
      const before = resolver.resolve(new Date(2026, 7, 18, 23, 59, 59, 999).getTime());
      const after = resolver.resolve(new Date(2026, 7, 19, 0, 0, 0, 0).getTime());

      expect(before.localDate).assertEqual('2026-08-18');
      expect(after.localDate).assertEqual('2026-08-19');
      expect(after.timezoneOffsetMinutes).assertEqual(-new Date(2026, 7, 19).getTimezoneOffset());
    });
  });
}
