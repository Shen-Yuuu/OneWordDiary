/**
 * Counts the user-perceived characters needed by the MVP input limits.
 * It keeps combining marks, variation selectors, emoji modifiers, flags and
 * zero-width-joiner emoji sequences in the same grapheme cluster.
 */
export class GraphemeCounter {
  count(value: string): number {
    return this.split(value).length;
  }

  split(value: string): string[] {
    const graphemes: string[] = [];
    let current: string = '';
    let index: number = 0;
    let joinsNext: boolean = false;
    let regionalIndicatorRun: number = 0;

    while (index < value.length) {
      const codePoint: number = value.codePointAt(index) ?? 0;
      const codePointLength: number = codePoint > 0xFFFF ? 2 : 1;
      const character: string = value.substring(index, index + codePointLength);
      index += codePointLength;

      if (this.isExtend(codePoint)) {
        current += character;
        continue;
      }
      if (codePoint === 0x200D) {
        current += character;
        joinsNext = current.length > 0;
        continue;
      }
      if (joinsNext) {
        current += character;
        joinsNext = false;
        regionalIndicatorRun = 0;
        continue;
      }
      if (this.isRegionalIndicator(codePoint)) {
        if (regionalIndicatorRun % 2 === 0) {
          this.pushCurrent(graphemes, current);
          current = character;
        } else {
          current += character;
        }
        regionalIndicatorRun += 1;
        continue;
      }

      this.pushCurrent(graphemes, current);
      current = character;
      regionalIndicatorRun = 0;
    }
    this.pushCurrent(graphemes, current);
    return graphemes;
  }

  private pushCurrent(graphemes: string[], current: string): void {
    if (current.length > 0) {
      graphemes.push(current);
    }
  }

  private isRegionalIndicator(codePoint: number): boolean {
    return codePoint >= 0x1F1E6 && codePoint <= 0x1F1FF;
  }

  private isExtend(codePoint: number): boolean {
    return this.isBetween(codePoint, 0x0300, 0x036F) ||
      this.isBetween(codePoint, 0x1AB0, 0x1AFF) ||
      this.isBetween(codePoint, 0x1DC0, 0x1DFF) ||
      this.isBetween(codePoint, 0x20D0, 0x20FF) ||
      this.isBetween(codePoint, 0xFE20, 0xFE2F) ||
      this.isBetween(codePoint, 0xFE00, 0xFE0F) ||
      this.isBetween(codePoint, 0xE0100, 0xE01EF) ||
      this.isBetween(codePoint, 0x1F3FB, 0x1F3FF) ||
      this.isBetween(codePoint, 0xE0020, 0xE007F);
  }

  private isBetween(value: number, start: number, end: number): boolean {
    return value >= start && value <= end;
  }
}
