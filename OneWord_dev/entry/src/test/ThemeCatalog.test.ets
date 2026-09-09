import { describe, expect, it } from '@ohos/hypium';
import {
  isSupportedPaperId,
  isSupportedStylePreset,
  paperIdForStyle,
  STYLE_PRESETS,
  styleForPaper,
  styleForPreset,
  StylePresetId
} from '../main/ets/constants/StyleTokens';

export default function themeCatalogTest(): void {
  describe('ThemeCatalog', () => {
    it('resolvesEveryPresetToItsUniquePaper', 0, () => {
      expect(STYLE_PRESETS.length).assertEqual(6);
      for (let index = 0; index < STYLE_PRESETS.length; index++) {
        const style = STYLE_PRESETS[index];
        expect(paperIdForStyle(style.id)).assertEqual(style.paperId);
        expect(styleForPreset(style.id).paperId).assertEqual(style.paperId);
        expect(styleForPaper(style.paperId).id).assertEqual(style.id);
        expect(isSupportedStylePreset(style.id)).assertTrue();
        expect(isSupportedPaperId(style.paperId)).assertTrue();
        for (let otherIndex = index + 1; otherIndex < STYLE_PRESETS.length; otherIndex++) {
          expect(style.paperId === STYLE_PRESETS[otherIndex].paperId).assertFalse();
        }
      }
    });

    it('fallsBackForUnknownLookupsWithoutTreatingThemAsSupported', 0, () => {
      expect(styleForPaper('unknown_paper').id).assertEqual(StylePresetId.PAPER_INK);
      expect(isSupportedPaperId('unknown_paper')).assertFalse();
      expect(isSupportedStylePreset('unknown_style')).assertFalse();
      expect(styleForPreset(StylePresetId.ROSE_PINK).paperId).assertEqual('rose_pink_dev');
    });
  });
}
