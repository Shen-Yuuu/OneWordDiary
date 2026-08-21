import { DiaryIconButton } from '../common/DiaryIconButton';
import { DiaryPrimaryButton } from '../common/DiaryPrimaryButton';
import { DiaryWordDisplay } from '../common/DiaryWordDisplay';
import { PaperBackdrop } from '../common/PaperBackdrop';
import { RecordType } from '../../model/DailyRecord';

@Component
export struct TodayConfirmation {
  @Prop dateText: string = '';
  @Prop draftType: RecordType = RecordType.WORD;
  @Prop content: string = '';
  @Prop contentCount: number = 0;
  @Prop note: string = '';
  @Prop paperId: string = 'warm_paper_dev';
  @Prop isRevision: boolean = false;
  @Prop isBusy: boolean = false;
  @Prop errorMessage: string = '';
  onConfirm: () => void = () => {
  };
  onCancel: () => void = () => {
  };

  get primaryLabel(): string {
    if (this.errorMessage.length > 0) {
      return '重新保存';
    }
    if (this.isRevision) {
      return '确认定稿';
    }
    return this.draftType === RecordType.BLANK ? '确认留白' : '收入长卷';
  }


  build() {
    Stack() {
      PaperBackdrop({ paperId: this.paperId })

      Column() {
        Row() {
          DiaryIconButton({
            icon: $r('app.media.ic_close'),
            accessibilityLabel: '返回修改',
            onTap: () => this.onCancel()
          })
            .enabled(!this.isBusy)
            .opacity(this.isBusy ? 0.35 : 1)

          Text(this.dateText)
            .fontSize(15)
            .fontWeight(FontWeight.Lighter)
            .fontColor($r('app.color.text_secondary'))
            .letterSpacing(1.6)

          Row()
            .width($r('app.float.touch_target_min'))
            .height($r('app.float.touch_target_min'))
        }
        .width('100%')
        .height($r('app.float.top_bar_height'))
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(VerticalAlign.Center)

        Blank()

        Column({ space: 18 }) {
          if (this.draftType === RecordType.BLANK) {
            Stack({ alignContent: Alignment.Center }) {
              Row()
                .width(72)
                .height(72)
                .border({ width: 1, color: $r('app.color.outline_soft') })
                .borderRadius(36)

              Row()
                .width(7)
                .height(7)
                .backgroundColor($r('app.color.accent_vermilion'))
                .borderRadius(2)
            }

            Text('把今天留给空白')
              .fontSize(26)
              .fontFamily('serif')
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
              .letterSpacing(4)
              .textAlign(TextAlign.Center)

            Text('留白，也是今天完整的一笔')
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))

            if (this.note.length > 0) {
              Text('确认留白后，已填写的备注不会保存')
                .fontSize(13)
                .fontColor($r('app.color.accent_vermilion'))
                .textAlign(TextAlign.Center)
                .accessibilityLevel('yes')
            }
          } else {
            DiaryWordDisplay({
              content: this.content,
              contentCount: this.contentCount,
              accessibilityPrefix: '今日正文'
            })

            Text('「 见字如面 」')
              .fontSize(14)
              .fontFamily('serif')
              .fontColor($r('app.color.text_tertiary'))
              .letterSpacing(3)

            if (this.note.length > 0) {
              Text(this.note)
                .fontSize(16)
                .fontColor($r('app.color.text_secondary'))
                .lineHeight(24)
                .textAlign(TextAlign.Center)
                .maxLines(3)
                .margin({ top: 6 })
            }
          }

          if (this.isRevision) {
            Text('本次确认后永久定稿')
              .fontSize(14)
              .fontColor($r('app.color.accent_vermilion'))
              .accessibilityLevel('yes')
          }

          if (this.errorMessage.length > 0) {
            Text(this.errorMessage)
              .fontSize(14)
              .fontColor('#BA1A1A')
              .textAlign(TextAlign.Center)
              .accessibilityLevel('yes')
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)

        Blank()

        if (this.isBusy) {
          LoadingProgress()
            .width(26)
            .height(26)
            .color($r('app.color.accent_vermilion'))
            .margin({ bottom: 8 })

          Text(this.isRevision ? '正在定稿…' : '正在收入长卷…')
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
            .margin({ bottom: 14 })
        }

        DiaryPrimaryButton({
          label: this.primaryLabel,
          isEnabled: !this.isBusy,
          onTap: () => this.onConfirm()
        })

        Button(this.errorMessage.length > 0 ? '返回修改' : '再想想')
          .height($r('app.float.touch_target_min'))
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
          .backgroundColor(Color.Transparent)
          .enabled(!this.isBusy)
          .margin({ bottom: 18 })
          .onClick(() => this.onCancel())
      }
      .width('100%')
      .height('100%')
      .padding({ left: $r('app.float.page_horizontal_margin'), right: $r('app.float.page_horizontal_margin') })
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }
}
