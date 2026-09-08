import { styleForPaper } from '../../constants/StyleTokens';

export const PHOTO_SCRIM_OPACITY: number = 0.74;

export function photoScrimColorForPaper(paperId: string, fixedLightScrim: boolean = false): string {
  if (!fixedLightScrim) {
    return styleForPaper(paperId).light.background;
  }

  switch (paperId) {
    case 'plain_ash_dev':
      return '#EFEFEA';
    case 'pine_mist_dev':
      return '#EAF1EC';
    case 'mist_blue_dev':
      return '#EAF0F6';
    case 'apricot_paper_dev':
      return '#F7EFE2';
    case 'warm_paper_dev':
    default:
      return '#FDF8F7';
  }
}

class DiaryBackgroundSource {
  readonly uri: string;
  readonly reloadKey: number;

  constructor(uri: string, reloadKey: number) {
    this.uri = uri;
    this.reloadKey = reloadKey;
  }
}

@Component
export struct DiaryBackground {
  @Prop @Watch('onImageUriChanged') imageUri: string = '';
  @Prop paperId: string = 'warm_paper_dev';
  @Prop scrimOpacity: number = PHOTO_SCRIM_OPACITY;
  @Prop fixedLightScrim: boolean = false;
  @Prop reloadKey: number = 0;
  @State private isLoaded: boolean = false;
  onReady: (imageUri: string, reloadKey: number) => void =
    (imageUri: string, reloadKey: number) => {
    };
  onFailed: (imageUri: string, reloadKey: number) => void =
    (imageUri: string, reloadKey: number) => {
    };

  get paperColor(): string {
    return photoScrimColorForPaper(this.paperId, this.fixedLightScrim);
  }

  get transparentPaperColor(): string {
    switch (this.paperColor) {
      case '#F7F7F5':
        return 'rgba(247, 247, 245, 0)';
      case '#EFEFEA':
        return 'rgba(239, 239, 234, 0)';
      case '#EAF1EC':
        return 'rgba(234, 241, 236, 0)';
      case '#EAF0F6':
        return 'rgba(234, 240, 246, 0)';
      case '#F7EFE2':
        return 'rgba(247, 239, 226, 0)';
      default:
        return 'rgba(253, 248, 247, 0)';
    }
  }

  get readingPaperColor(): string {
    switch (this.paperColor) {
      case '#F7F7F5':
        return 'rgba(247, 247, 245, 0.12)';
      case '#EFEFEA':
        return 'rgba(239, 239, 234, 0.12)';
      case '#EAF1EC':
        return 'rgba(234, 241, 236, 0.12)';
      case '#EAF0F6':
        return 'rgba(234, 240, 246, 0.12)';
      case '#F7EFE2':
        return 'rgba(247, 239, 226, 0.12)';
      default:
        return 'rgba(253, 248, 247, 0.12)';
    }
  }

  onImageUriChanged(): void {
    this.isLoaded = false;
  }

  private handleReady(source: DiaryBackgroundSource): void {
    if (source.uri !== this.imageUri || source.reloadKey !== this.reloadKey) {
      return;
    }
    this.isLoaded = true;
    this.onReady(source.uri, source.reloadKey);
  }

  private handleFailed(source: DiaryBackgroundSource): void {
    if (source.uri !== this.imageUri || source.reloadKey !== this.reloadKey) {
      return;
    }
    this.isLoaded = false;
    this.onFailed(source.uri, source.reloadKey);
  }

  build() {
    if (this.imageUri.length > 0) {
      ForEach([new DiaryBackgroundSource(this.imageUri, this.reloadKey)], (source: DiaryBackgroundSource) => {
        Stack() {
          Image(source.uri)
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Cover)
            .onComplete((event) => {
              if (event !== undefined && event.loadingStatus === 1) {
                this.handleReady(source);
              }
            })
            .onError(() => this.handleFailed(source))

          Row()
            .width('100%')
            .height('100%')
            .backgroundColor(this.paperColor)
            .opacity(this.scrimOpacity)

          Row()
            .width('100%')
            .height('100%')
            .linearGradient({
              angle: 90,
              colors: [
                [this.transparentPaperColor, 0],
                [this.readingPaperColor, 0.5],
                [this.transparentPaperColor, 1]
              ]
            })
        }
        .width('100%')
        .height('100%')
        .opacity(this.isLoaded ? 1 : 0)
        .hitTestBehavior(HitTestMode.None)
        .accessibilityLevel('no')
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      }, (source: DiaryBackgroundSource) => source.uri + ':' + source.reloadKey.toString())
    }
  }
}
