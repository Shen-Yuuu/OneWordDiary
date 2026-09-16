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

  private flexAlignment(): FlexAlign {
    if (this.textAlign === TextAlign.Start) {
      return FlexAlign.Start;
    }
    if (this.textAlign === TextAlign.End) {
      return FlexAlign.End;
    }
    return FlexAlign.Center;
  }

  private emojiSize(): number {
    return Math.min(this.fontSize, this.lineHeight) * 0.82;
  }

  @Builder
  private noteGrapheme(segment: NoteTextSegment) {
    if (segment.isEmoji) {
      Stack({ alignContent: Alignment.Center }) {
        Text(segment.text)
          .fontSize(this.emojiSize())
          .fontFamily('sans-serif')
          .lineHeight(this.lineHeight)
          .minFontScale(1)
          .maxFontScale(1)
      }
      .width(this.lineHeight)
      .height(this.lineHeight)
      .clip(true)
    } else {
      Text(segment.text)
        .fontSize(this.fontSize)
        .fontFamily(this.fontFamily)
        .fontColor(this.fontColor)
        .lineHeight(this.lineHeight)
        .letterSpacing(this.letterSpacing)
        .height(this.lineHeight)
        .minFontScale(1)
        .maxFontScale(1)
    }
  }

  build() {
    Flex({ wrap: FlexWrap.Wrap, justifyContent: this.flexAlignment(), alignItems: ItemAlign.Center }) {
      ForEach(this.segmenter.graphemes(this.text), (segment: NoteTextSegment, index: number) => {
        this.noteGrapheme(segment)
      }, (segment: NoteTextSegment, index: number): string => `${index}-${segment.isEmoji ? 'emoji' : 'text'}`)
    }
    .width(this.textWidth)
    .height(this.lineHeight * this.maxLines)
    .clip(true)
    .accessibilityText(`备注，${this.text}`)
  }
}
