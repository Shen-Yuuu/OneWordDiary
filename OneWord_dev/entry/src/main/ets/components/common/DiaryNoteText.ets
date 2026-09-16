import { NoteTextSegment, NoteTextSegmenter } from '../../utils/NoteTextSegmenter';

@Component
export struct DiaryNoteText {
  @Prop text: string = '';
  @Prop fontFamily: string = 'oneword_wenkai, serif';
  @Prop fontSize: number = 20;
  @Prop lineHeight: number = 24;
  @Prop fontColor: ResourceColor = Color.Black;
  @Prop textWidth: number = 280;
  @Prop maxLines: number = 2;
  @Prop textAlign: TextAlign = TextAlign.Center;
  @Prop letterSpacing: number = 0;
  private readonly segmenter: NoteTextSegmenter = new NoteTextSegmenter();

  build() {
    Text() {
      ForEach(this.segmenter.segment(this.text), (segment: NoteTextSegment, index: number) => {
        Span(segment.text)
          .fontSize(this.fontSize)
          .fontFamily(segment.isEmoji ? 'HarmonyOS Sans' : this.fontFamily)
          .fontColor(this.fontColor)
          .letterSpacing(this.letterSpacing)
      }, (segment: NoteTextSegment, index: number): string => `${index}-${segment.isEmoji ? 'emoji' : 'text'}`)
    }
    .width(this.textWidth)
    .fontSize(this.fontSize)
    .lineHeight(this.lineHeight)
    .fontColor(this.fontColor)
    .textAlign(this.textAlign)
    .maxLines(this.maxLines)
    .minFontScale(1)
    .maxFontScale(1)
    .accessibilityText(`备注，${this.text}`)
  }
}
