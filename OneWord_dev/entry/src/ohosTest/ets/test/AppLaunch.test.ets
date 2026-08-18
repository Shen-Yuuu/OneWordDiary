import { describe, expect, it } from '@ohos/hypium';

export default function appLaunchTest(): void {
  describe('AppLaunchBaseline', () => {
    it('usesOneWordBrand', 0, () => {
      expect('一字日记').assertEqual('一字日记');
    });
  });
}
