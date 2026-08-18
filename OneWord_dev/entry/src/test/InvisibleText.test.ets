import { describe, expect, it } from '@ohos/hypium';
import { DiaryError, DiaryErrorCode } from '../main/ets/model/DiaryError';
import { DiaryTextRules } from '../main/ets/service/DiaryTextRules';

export default function invisibleTextTest(): void {
  describe('InvisibleText', () => {
    it('doesNotAcceptAZeroWidthJoinerAsVisibleContent', 0, () => {
      const rules = new DiaryTextRules();
      let errorCode: string = '';
      try {
        rules.normalizeContent('\u200D');
      } catch (error) {
        if (error instanceof DiaryError) {
          errorCode = error.code;
        }
      }
      expect(errorCode).assertEqual(DiaryErrorCode.CONTENT_REQUIRED);
      expect(rules.normalizeNote('\u200D') === null).assertTrue();
    });
  });
}
