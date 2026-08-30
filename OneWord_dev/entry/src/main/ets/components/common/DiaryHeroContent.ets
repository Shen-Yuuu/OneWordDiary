import { curves } from '@kit.ArkUI';
import { FallingChar, splitChars } from './FallingChar';
import { InkSeal } from './InkSeal';
import { FontFamilies } from '../../constants/StyleTokens';
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
  @State private washPlayed: boolean = false;
  @State private washGone: boolean = false;
  private washTimer: number = -1;
  private washClearTimer: number = -1;

  aboutToAppear(): void {
    if (this.recordType !== RecordType.WORD) {
      return;
    }
    this.washTimer = setTimeout(() => {
      // 从一个小点快速放大变浅：墨在纸上迅速晕开
      this.getUIContext().animateTo({ duration: 500, curve: Curve.EaseOut }, () => {
        this.washPlayed = true;
      });
    }, 60);
    this.washClearTimer = setTimeout(() => {
      this.washGone = true;
    }, 650);
  }

  aboutToDisappear(): void {
    if (this.washTimer !== -1) {
      clearTimeout(this.washTimer);
    }
    if (this.washClearTimer !== -1) {
      clearTimeout(this.washClearTimer);
    }
  }

  recordFontFamily(): string {
    return 'oneword_wenkai, serif';
  }

  heroCharSize(): number {
    if (this.contentCount <= 1) {
      return 136;
    }
    if (this.contentCount === 2) {
      return 76;
    }
    return this.contentCount === 3 ? 56 : 44;
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
      Column()
        .width(300)
        .height(300)
        .borderRadius(150)
        .backgroundColor('#1C1814')
        .scale({ x: this.washPlayed ? 1.25 : 0.06, y: this.washPlayed ? 1.25 : 0.06 })
        .opacity(this.washPlayed ? 0 : 0.9)
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
          .backgroundColor($r('app.color.accent_vermilion'))
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
          .fontSize(14)
          .lineHeight(22)
          .fontFamily(this.recordFontFamily())
          .fontColor($r('app.color.text_secondary'))
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
