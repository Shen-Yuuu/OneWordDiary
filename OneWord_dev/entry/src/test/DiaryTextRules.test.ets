import { describe, expect, it } from '@ohos/hypium';
import { RecordType } from '../main/ets/model/DailyRecord';
import { DiaryTextRules } from '../main/ets/service/DiaryTextRules';
import { GraphemeCounter } from '../main/ets/utils/GraphemeCounter';

export default function diaryTextRulesTest(): void {
  describe('DiaryTextRules', () => {
    const rules: DiaryTextRules = new DiaryTextRules();

    it('countsUserPerceivedCharacters', 0, () => {
      expect(rules.countGraphemes('静')).assertEqual(1);
      expect(rules.countGraphemes('👍🏽')).assertEqual(1);
      expect(rules.countGraphemes('👨‍👩‍👧‍👦')).assertEqual(1);
      expect(rules.countGraphemes('🇨🇳')).assertEqual(1);
      expect(rules.countGraphemes('e\u0301')).assertEqual(1);
      expect(rules.countGraphemes('春夏秋冬')).assertEqual(4);
    });

    it('splitsEmojiSequencesWithoutBreakingVisibleCharacters', 0, () => {
      const graphemes = new GraphemeCounter().split('静👍🏽👨‍👩‍👧‍👦🇨🇳e\u0301');
      expect(graphemes.length).assertEqual(5);
      expect(graphemes[1]).assertEqual('👍🏽');
      expect(graphemes[2]).assertEqual('👨‍👩‍👧‍👦');
      expect(graphemes[3]).assertEqual('🇨🇳');
      expect(graphemes[4]).assertEqual('e\u0301');
    });

    it('normalizesWordAndBlankEntries', 0, () => {
      const word = rules.normalizeEntry({
        recordType: RecordType.WORD,
        content: '  e\u0301  ',
        note: '  今天很好  ',
        fontId: 'system_serif_dev',
        paperId: 'warm_paper_dev'
      });
      expect(word.content).assertEqual('é');
      expect(word.note).assertEqual('今天很好');

      const blank = rules.normalizeEntry({
        recordType: RecordType.BLANK,
        content: '会被忽略',
        note: '也会被忽略',
        fontId: 'system_serif_dev',
        paperId: 'warm_paper_dev'
      });
      expect(blank.content === null).assertTrue();
      expect(blank.note === null).assertTrue();
    });
  });
}
