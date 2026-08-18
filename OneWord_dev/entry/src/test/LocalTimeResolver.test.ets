import { describe, expect, it } from '@ohos/hypium';
import { SystemLocalTimeResolver } from '../main/ets/utils/LocalTimeResolver';

export default function localTimeResolverTest(): void {
  describe('LocalTimeResolver', () => {
    it('usesLocalCalendarDayAndLastMillisecondAsDeadline', 0, () => {
      const timestamp: number = new Date(2026, 7, 18, 21, 30, 0, 0).getTime();
      const expectedDeadline: number = new Date(2026, 7, 19, 0, 0, 0, 0).getTime() - 1;
      const snapshot = new SystemLocalTimeResolver().resolve(timestamp);

      expect(snapshot.localDate).assertEqual('2026-08-18');
      expect(snapshot.revisionDeadlineAt).assertEqual(expectedDeadline);
    });
  });
}
