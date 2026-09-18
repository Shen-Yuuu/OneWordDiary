import { curves } from '@kit.ArkUI';
import { styleForPaper } from '../../constants/StyleTokens';
import { GraphemeCounter } from '../../utils/GraphemeCounter';

const graphemeCounter: GraphemeCounter = new GraphemeCounter();

/**
 * 按字素簇拆分字符串，用于逐字渲染。
 * 组合符号、变体选择符、emoji 修饰符、旗帜与 ZWJ 序列（如 😮‍💨）保持在同一簇内，
 * 避免多码点 emoji 被拆成独立 Text 后失去连字。
 */
export function splitChars(value: string): string[] {
  return graphemeCounter.split(value);
}

/**
 * 单个文字的“落字”入场：从下方 26vp 浮起、由虚到实、微微收拢。
 * 延迟由父组件按字序错峰编排。墨色跟随当前主题。
 */
@Component
export struct FallingChar {
  @Prop char: string = '';
  @Prop charSize: number = 136;
  @Prop fontFamily: string = 'oneword_wenkai, serif';
  @Prop paperId: string = 'warm_paper_dev';
  @Prop delay: number = 0;
  @State private dropped: boolean = false;
  private dropTimer: number = -1;

  aboutToAppear(): void {
    this.dropTimer = setTimeout(() => {
      this.getUIContext().animateTo({ curve: curves.springMotion(0.55, 0.85) }, () => {
        this.dropped = true;
      });
    }, this.delay);
  }

  aboutToDisappear(): void {
    if (this.dropTimer !== -1) {
      clearTimeout(this.dropTimer);
    }
  }

  build() {
    Text(this.char)
      .fontSize(this.charSize)
      .fontFamily(this.fontFamily)
      .fontWeight(FontWeight.Normal)
      .fontColor(styleForPaper(this.paperId).light.textPrimary)
      .minFontScale(1)
      .maxFontScale(1)
      .opacity(this.dropped ? 1 : 0)
      .translate({ y: this.dropped ? 0 : 26 })
      .scale({ x: this.dropped ? 1 : 0.94, y: this.dropped ? 1 : 0.94 })
  }
}
