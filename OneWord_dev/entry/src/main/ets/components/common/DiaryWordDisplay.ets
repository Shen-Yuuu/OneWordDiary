import { FallingChar, splitChars } from './FallingChar';

@Component
export struct DiaryWordDisplay {
  @Prop content: string = '';
  @Prop contentCount: number = 0;
  @Prop fontFamily: string = 'oneword_wenkai, serif';
  @Prop stageHeight: number = 160;
  @Prop isHero: boolean = false;
  @Prop accessibilityPrefix: string = '正文';

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Row({ space: this.contentCount > 1 ? 4 : 0 }) {
        ForEach(splitChars(this.content), (char: string, index: number) => {
          FallingChar({
            char: char,
            // 注意：字号必须内联三元（struct getter 传入子组件参数会得到 undefined）
            charSize: this.isHero ?
              (this.contentCount <= 1 ? 210 : this.contentCount === 2 ? 136 : this.contentCount === 3 ? 92 : 66) :
              (this.contentCount <= 1 ? 88 : this.contentCount === 2 ? 72 : this.contentCount === 3 ? 58 : 48),
            fontFamily: this.fontFamily,
            delay: index * 70
          })
        })
      }
      .justifyContent(FlexAlign.Center)
      .accessibilityText(`${this.accessibilityPrefix}，${this.content}`)
    }
    .width('100%')
    .height(this.stageHeight)
  }
}
