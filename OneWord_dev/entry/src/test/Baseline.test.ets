import { describe, expect, it } from '@ohos/hypium';
import { AppConstants } from '../main/ets/constants/AppConstants';
import {
  PAPER_INK_STYLE,
  PLAIN_ASH_STYLE,
  StylePresetId
} from '../main/ets/constants/StyleTokens';

export default function baselineTest(): void {
  describe('AppBaseline', () => {
    it('definesProductLimits', 0, () => {
      expect(AppConstants.RECORD_CONTENT_MAX_GRAPHEMES).assertEqual(4);
      expect(AppConstants.RECORD_NOTE_MAX_GRAPHEMES).assertEqual(30);
    });

    it('definesTwoCompleteStylePresets', 0, () => {
      expect(PAPER_INK_STYLE.id).assertEqual(StylePresetId.PAPER_INK);
      expect(PLAIN_ASH_STYLE.id).assertEqual(StylePresetId.PLAIN_ASH);
      expect(PAPER_INK_STYLE.light.background === PLAIN_ASH_STYLE.light.background).assertFalse();
      expect(PAPER_INK_STYLE.dark.background === PLAIN_ASH_STYLE.dark.background).assertFalse();
    });
  });
}
