import { GraphemeCounter } from './GraphemeCounter';

export interface NoteTextSegment {
  text: string;
  isEmoji: boolean;
}

/**
 * Keeps diary typography for ordinary text while isolating emoji from custom
 * font fallback metrics. Adjacent graphemes with the same font choice are
 * merged so ArkUI only creates a small number of spans.
 */
export class NoteTextSegmenter {
  private readonly graphemeCounter: GraphemeCounter = new GraphemeCounter();

  segment(value: string): NoteTextSegment[] {
    const result: NoteTextSegment[] = [];
    const graphemes: string[] = this.graphemeCounter.split(value);
    for (const grapheme of graphemes) {
      const isEmoji: boolean = this.isEmojiGrapheme(grapheme);
      const previous: NoteTextSegment | undefined = result.length > 0 ? result[result.length - 1] : undefined;
      if (previous !== undefined && previous.isEmoji === isEmoji) {
        previous.text += grapheme;
      } else {
        result.push({ text: grapheme, isEmoji: isEmoji });
      }
    }
    return result;
  }

  private isEmojiGrapheme(value: string): boolean {
    let index: number = 0;
    while (index < value.length) {
      const codePoint: number = value.codePointAt(index) ?? 0;
      if (codePoint === 0xFE0F || codePoint === 0x20E3 ||
        this.isBetween(codePoint, 0x1F000, 0x1FAFF) ||
        this.isBetween(codePoint, 0x2600, 0x27BF) ||
        this.isBetween(codePoint, 0x2300, 0x23FF)) {
        return true;
      }
      index += codePoint > 0xFFFF ? 2 : 1;
    }
    return false;
  }

  private isBetween(value: number, start: number, end: number): boolean {
    return value >= start && value <= end;
  }
}
