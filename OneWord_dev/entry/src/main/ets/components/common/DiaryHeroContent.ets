import lottie from '@ohos/lottie';
import { FallingChar, splitChars } from './FallingChar';
import { InkSeal } from './InkSeal';
import { FontFamilies, styleForPaper } from '../../constants/StyleTokens';
import { fontFamilyForId } from '../../constants/FontCatalog';
import { RecordType } from '../../model/DailyRecord';

const CHAR_STAGGER_MS: number = 80;

@Component
export struct DiaryHeroContent {
  @Prop recordType: RecordType = RecordType.WORD;
  @Prop content: string = '';
  @Prop contentCount: number = 0;
  @Prop note: string = '';
  @Prop fontId: string = 'system_serif_dev';
  @Prop accessibilityPrefix: string = '日记正文';
  @StorageProp('currentPaperId') paperId: string = 'warm_paper_dev';
  @State private washGone: boolean = false;
  private washContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true));
  private washClearTimer: number = -1;

  aboutToAppear(): void {
    if (this.recordType !== RecordType.WORD) {
      return;
    }
    this.washClearTimer = setTimeout(() => {
      this.washGone = true;
      lottie.destroy('ink_drop');
    }, 1250);
  }

  aboutToDisappear(): void {
    if (this.washClearTimer !== -1) {
      clearTimeout(this.washClearTimer);
    }
    lottie.destroy('ink_drop');
  }

  recordFontFamily(): string {
    return fontFamilyForId(this.fontId);
  }

  heroCharSize(): number {
    if (this.contentCount <= 1) {
      return 142;
    }
    if (this.contentCount === 2) {
      return 85;
    }
    return this.contentCount === 3 ? 65 : 54;
  }

  charGap(): number {
    return this.contentCount > 1 ? 5 : 0;
  }

  sealDelay(): number {
    return 190 + this.contentCount * CHAR_STAGGER_MS + 80;
  }

  @Builder
  private inkWash() {
    if (this.recordType === RecordType.WORD && !this.washGone) {
      Canvas(this.washContext)
        .width(320)
        .height(320)
        .onReady(() => {
          this.washContext.imageSmoothingEnabled = true;
          this.washContext.imageSmoothingQuality = 'medium';
          lottie.loadAnimation({
            container: this.washContext,
            renderer: 'canvas',
            loop: false,
            autoplay: true,
            name: 'ink_drop',
            contentMode: 'Contain',
            path: 'ink_drop.json'
          });
        })
    }
  }

  @Builder
  private recordedWord() {
    if (this.contentCount <= 2) {
      Column({ space: this.contentCount > 1 ? 10 : 0 }) {
        ForEach(splitChars(this.content), (char: string, index: number) => {
          FallingChar({
            char: char,
            charSize: this.heroCharSize(),
            fontFamily: this.recordFontFamily(),
            delay: 60 + index * CHAR_STAGGER_MS
          })
        })
      }
      .justifyContent(FlexAlign.Center)
      .accessibilityText(`${this.accessibilityPrefix}，${this.content}`)
    } else {
      Row({ space: this.charGap() }) {
        ForEach(splitChars(this.content), (char: string, index: number) => {
          FallingChar({
            char: char,
            charSize: this.heroCharSize(),
            fontFamily: this.recordFontFamily(),
            delay: 60 + index * CHAR_STAGGER_MS
          })
        })
      }
      .justifyContent(FlexAlign.Center)
      .accessibilityText(`${this.accessibilityPrefix}，${this.content}`)
    }
  }

  @Builder
  private recordedBlank() {
    Column({ space: 14 }) {
      Stack({ alignContent: Alignment.Center }) {
        Row()
          .width(86)
          .height(86)
          .border({ width: 1, color: $r('app.color.outline_soft') })
          .borderRadius(43)

        Row()
          .width(8)
          .height(8)
          .backgroundColor(styleForPaper(this.paperId).light.accent)
          .borderRadius(2)
      }

      Text('今日留白')
        .fontSize(24)
        .fontFamily(FontFamilies.SERIF)
        .fontColor($r('app.color.text_primary'))
        .letterSpacing(4)
    }
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    Column({ space: 10 }) {
      Stack({ alignContent: Alignment.Center }) {
        this.inkWash()

        if (this.recordType === RecordType.BLANK) {
          this.recordedBlank()
        } else {
          this.recordedWord()
        }

        Row() {
          Blank()

          InkSeal({ delay: this.sealDelay() })
        }
        .width(260)
        .height(300)
        .padding({ top: 52 })
        .alignItems(VerticalAlign.Top)
      }
      .width(286)
      .height(300)

      if (this.recordType === RecordType.WORD) {
        Text('「 见字如面 」')
          .fontSize(14)
          .fontFamily(FontFamilies.SERIF)
          .fontColor($r('app.color.text_tertiary'))
          .letterSpacing(3)
      }

      if (this.note.length > 0) {
        Text(this.note)
          .width(280)
          .fontSize(20)
          .lineHeight(22)
          .fontFamily(this.recordFontFamily())
          .fontColor($r('app.color.text_primary'))
          .letterSpacing(0.6)
          .textAlign(TextAlign.Center)
          .maxLines(2)
          .accessibilityText(`备注，${this.note}`)
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .accessibilityGroup(true)
    .accessibilityText(this.recordType === RecordType.BLANK ?
      `正式留白${this.note.length > 0 ? `，备注，${this.note}` : ''}` :
      `${this.accessibilityPrefix}，${this.content}${this.note.length > 0 ? `，备注，${this.note}` : ''}`)
  }
}
