import { describe, expect, it } from '@ohos/hypium';
import { NoteTextSegmenter } from '../main/ets/utils/NoteTextSegmenter';

export default function noteTextSegmenterTest(): void {
  describe('NoteTextSegmenter', () => {
    const segmenter: NoteTextSegmenter = new NoteTextSegmenter();

    it('separatesEmojiFromDiaryText', 0, () => {
      const segments = segmenter.segment('不想上班😮‍💨但要加油');
      expect(segments.length).assertEqual(3);
      expect(segments[0].text).assertEqual('不想上班');
      expect(segments[0].isEmoji).assertFalse();
      expect(segments[1].text).assertEqual('😮‍💨');
      expect(segments[1].isEmoji).assertTrue();
      expect(segments[2].text).assertEqual('但要加油');
      expect(segments[2].isEmoji).assertFalse();
    });

    it('keepsAdjacentEmojiInOneSystemFontRun', 0, () => {
      const segments = segmenter.segment('今天😀👍🏽🇨🇳');
      expect(segments.length).assertEqual(2);
      expect(segments[1].text).assertEqual('😀👍🏽🇨🇳');
      expect(segments[1].isEmoji).assertTrue();
    });

    it('keepsCombiningTextInTheDiaryFontRun', 0, () => {
      const segments = segmenter.segment('cafe\u0301');
      expect(segments.length).assertEqual(1);
      expect(segments[0].text).assertEqual('cafe\u0301');
      expect(segments[0].isEmoji).assertFalse();
    });
  });
}
