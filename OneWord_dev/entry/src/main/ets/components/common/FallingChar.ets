import { curves } from '@kit.ArkUI';

/**
 * 按码点拆分字符串（代理对安全），用于逐字渲染。
 * 组合符号/emoji 修饰等复杂字素不在此处理——落字动画按可见字位错峰即可。
 */
export function splitChars(value: string): string[] {
  const chars: string[] = [];
  let index: number = 0;
  while (index < value.length) {
    const codePoint: number = value.codePointAt(index) ?? 0;
    const size: number = codePoint > 0xFFFF ? 2 : 1;
    chars.push(value.substring(index, index + size));
    index += size;
  }
  return chars;
}

/**
 * 单个文字的“落字”入场：从下方 26vp 浮起、由虚到实、微微收拢。
 * 延迟由父组件按字序错峰编排。
 */
@Component
export struct FallingChar {
  @Prop char: string = '';
  @Prop charSize: number = 136;
  @Prop fontFamily: string = 'oneword_wenkai, serif';
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
      .fontColor($r('app.color.text_primary'))
      .minFontScale(1)
      .maxFontScale(1)
      .opacity(this.dropped ? 1 : 0)
      .translate({ y: this.dropped ? 0 : 26 })
      .scale({ x: this.dropped ? 1 : 0.94, y: this.dropped ? 1 : 0.94 })
  }
}
