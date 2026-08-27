import { describe, expect, it } from '@ohos/hypium';
import { AppConstants } from '../main/ets/constants/AppConstants';
import { ScrollLayoutMetrics } from '../main/ets/constants/ScrollLayoutMetrics';
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

    it('definesCompactScrollMetrics', 0, () => {
      expect(ScrollLayoutMetrics.MONTH_HEADER_HEIGHT).assertEqual(48);
      expect(ScrollLayoutMetrics.nodeHeight(false, false)).assertEqual(104);
      expect(ScrollLayoutMetrics.nodeHeight(false, true)).assertEqual(128);
      expect(ScrollLayoutMetrics.nodeHeight(true, true)).assertEqual(56);
      expect(ScrollLayoutMetrics.AXIS_MARKER_BOX_SIZE).assertEqual(32);
      expect(ScrollLayoutMetrics.WORD_NODE_SIZE).assertEqual(12);
      expect(ScrollLayoutMetrics.BLANK_NODE_SIZE).assertEqual(24);
      expect(ScrollLayoutMetrics.MISSING_NODE_SIZE).assertEqual(14);
      expect(ScrollLayoutMetrics.totalHeight(false, false, true)).assertEqual(152);
      expect(ScrollLayoutMetrics.totalHeight(false, true, false)).assertEqual(128);
      expect(ScrollLayoutMetrics.totalHeight(true, false, false)).assertEqual(56);
    });

    it('definesTwoCompleteStylePresets', 0, () => {
      expect(PAPER_INK_STYLE.id).assertEqual(StylePresetId.PAPER_INK);
      expect(PLAIN_ASH_STYLE.id).assertEqual(StylePresetId.PLAIN_ASH);
      expect(PAPER_INK_STYLE.light.background === PLAIN_ASH_STYLE.light.background).assertFalse();
      expect(PAPER_INK_STYLE.dark.background === PLAIN_ASH_STYLE.dark.background).assertFalse();
    });
  });
}
