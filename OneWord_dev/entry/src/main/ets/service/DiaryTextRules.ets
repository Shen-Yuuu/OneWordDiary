import { AppConstants } from '../constants/AppConstants';
import {
  DiaryEntryInput,
  NormalizedDiaryEntry,
  RecordType
} from '../model/DailyRecord';
import { DiaryError, DiaryErrorCode } from '../model/DiaryError';
import { GraphemeCounter } from '../utils/GraphemeCounter';

export class DiaryTextRules {
  private readonly graphemeCounter: GraphemeCounter = new GraphemeCounter();

  countGraphemes(value: string): number {
    return this.graphemeCounter.count(value);
  }

  normalizeEntry(input: DiaryEntryInput): NormalizedDiaryEntry {
    this.validateStyle(input.fontId, input.paperId);

    if (input.recordType === RecordType.BLANK) {
      return {
        recordType: RecordType.BLANK,
        content: null,
        note: null,
        fontId: input.fontId,
        paperId: input.paperId
      };
    }

    const normalizedContent: string = this.normalizeContent(input.content);
    const normalizedNote: string | null = this.normalizeNote(input.note);
    return {
      recordType: RecordType.WORD,
      content: normalizedContent,
      note: normalizedNote,
      fontId: input.fontId,
      paperId: input.paperId
    };
  }

  normalizeContent(content: string | null): string {
    if (content === null || content.length === 0) {
      throw new DiaryError(DiaryErrorCode.CONTENT_REQUIRED, '正文不能为空');
    }
    if (this.hasLineBreak(content)) {
      throw new DiaryError(DiaryErrorCode.CONTENT_HAS_LINE_BREAK, '正文不能包含换行');
    }

    const normalized: string = content.normalize('NFC').trim();
    if (normalized.length === 0) {
      throw new DiaryError(DiaryErrorCode.CONTENT_REQUIRED, '正文不能为空');
    }

    const count: number = this.countGraphemes(normalized);
    if (count === 0) {
      throw new DiaryError(DiaryErrorCode.CONTENT_REQUIRED, '正文不能为空');
    }
    if (count > AppConstants.RECORD_CONTENT_MAX_GRAPHEMES) {
      throw new DiaryError(DiaryErrorCode.CONTENT_TOO_LONG, '正文最多四个字');
    }
    return normalized;
  }

  normalizeNote(note: string | null): string | null {
    if (note === null || note.length === 0) {
      return null;
    }
    if (this.hasLineBreak(note)) {
      throw new DiaryError(DiaryErrorCode.NOTE_HAS_LINE_BREAK, '注解不能包含换行');
    }

    const normalized: string = note.normalize('NFC').trim();
    if (normalized.length === 0) {
      return null;
    }
    const count: number = this.countGraphemes(normalized);
    if (count === 0) {
      return null;
    }
    if (count > AppConstants.RECORD_NOTE_MAX_GRAPHEMES) {
      throw new DiaryError(DiaryErrorCode.NOTE_TOO_LONG, '注解最多三十个字');
    }
    return normalized;
  }

  private hasLineBreak(value: string): boolean {
    return value.includes('\n') || value.includes('\r');
  }

  private validateStyle(fontId: string, paperId: string): void {
    if (fontId.trim().length === 0 || paperId.trim().length === 0) {
      throw new DiaryError(DiaryErrorCode.STYLE_REQUIRED, '记录样式不能为空');
    }
  }
}
