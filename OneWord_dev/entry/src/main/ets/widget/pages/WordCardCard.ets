let storage = new LocalStorage();

@Entry(storage)
@Component
struct WordCardCard {
  @LocalStorageProp('content') content: string = '';
  @LocalStorageProp('date') date: string = '';
  @LocalStorageProp('paperColor') paperColor: string = '#FDF8F7';
  @LocalStorageProp('inkColor') inkColor: string = '#282622';
  @LocalStorageProp('accentColor') accentColor: string = '#A65C4D';
  @LocalStorageProp('fontFamily') fontFamily: string = 'oneword_wenkai, serif';

  build() {
    Column() {
      Text(this.date)
        .fontSize(12)
        .fontFamily(this.fontFamily)
        .fontColor(this.inkColor)
        .opacity(0.6)
        .letterSpacing(1)

      Blank()

      if (this.content.length > 0) {
        Text(this.content)
          .fontSize(52)
          .fontFamily(this.fontFamily)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.inkColor)
          .textAlign(TextAlign.Center)
          .maxLines(1)
      } else {
        Text('一字')
          .fontSize(44)
          .fontWeight(FontWeight.Lighter)
          .fontColor(this.inkColor)
          .opacity(0.4)
          .textAlign(TextAlign.Center)
      }

      Blank()
    }
    .width('100%')
    .height('100%')
    .padding(16)
    .backgroundColor(this.paperColor)
    .alignItems(HorizontalAlign.Center)
  }
}
