export class ScrollLayoutMetrics {
  static readonly MONTH_HEADER_HEIGHT: number = 48;
  static readonly RECORD_HEIGHT: number = 88;
  static readonly RECORD_WITH_NOTE_HEIGHT: number = 116;
  static readonly MISSING_HEIGHT: number = 48;
  static readonly SHARE_TOP_SPACING: number = 8;
  static readonly SHARE_FOOTER_HEIGHT: number = 72;

  static readonly WORD_NODE_SIZE: number = 10;
  static readonly BLANK_NODE_SIZE: number = 24;
  static readonly MISSING_NODE_SIZE: number = 14;

  static nodeHeight(isMissing: boolean, showNote: boolean): number {
    if (isMissing) {
      return ScrollLayoutMetrics.MISSING_HEIGHT;
    }
    return showNote ? ScrollLayoutMetrics.RECORD_WITH_NOTE_HEIGHT : ScrollLayoutMetrics.RECORD_HEIGHT;
  }
}
