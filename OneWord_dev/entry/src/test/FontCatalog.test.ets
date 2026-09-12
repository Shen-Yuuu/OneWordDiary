import { describe, expect, it } from '@ohos/hypium';
import {
  allFontOptions,
  FontPresetId,
  fontFamilyForId,
  fontPresetIdFromValue,
  isSupportedFontId
} from '../main/ets/constants/FontCatalog';

export default function fontCatalogTest(): void {
  describe('FontCatalog', () => {
    it('exposesSixSelectableFontsWithStableLabels', 0, () => {
      const options = allFontOptions();
      expect(options.length).assertEqual(6);
      expect(options[0].id).assertEqual(FontPresetId.DEFAULT);
      expect(options[1].displayName).assertEqual('得意黑楷体');
      expect(options[2].displayName).assertEqual('呆萌手写体');
      expect(options[3].displayName).assertEqual('悠然小楷体');
      expect(options[4].displayName).assertEqual('汇文明朝体');
      expect(options[5].displayName).assertEqual('云峰飞云体');
    });

    it('resolvesCustomLegacyAndUnknownIdsSafely', 0, () => {
      expect(fontFamilyForId(FontPresetId.SMILEY_SANS).includes('oneword_smiley_sans')).assertTrue();
      expect(fontFamilyForId('system_serif_dev')).assertEqual('oneword_wenkai, serif');
      expect(fontFamilyForId('system_sans_dev')).assertEqual('oneword_wenkai, serif');
      expect(fontFamilyForId('unknown')).assertEqual('oneword_wenkai, serif');
      expect(isSupportedFontId(FontPresetId.YUNFENG_FEIYUN)).assertTrue();
      expect(isSupportedFontId('system_serif_dev')).assertTrue();
      expect(isSupportedFontId('unknown')).assertFalse();
      expect(fontPresetIdFromValue('unknown')).assertEqual(FontPresetId.DEFAULT);
    });
  });
}
