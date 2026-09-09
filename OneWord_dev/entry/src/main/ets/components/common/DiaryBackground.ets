export const PHOTO_IMAGE_OPACITY: number = 0.10;

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
  @Prop reloadKey: number = 0;
  @State private isLoaded: boolean = false;
  onReady: (imageUri: string, reloadKey: number) => void =
    (imageUri: string, reloadKey: number) => {
    };
  onFailed: (imageUri: string, reloadKey: number) => void =
    (imageUri: string, reloadKey: number) => {
    };

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
            .opacity(PHOTO_IMAGE_OPACITY)
            .onComplete((event) => {
              if (event !== undefined && event.loadingStatus === 1) {
                this.handleReady(source);
              }
            })
            .onError(() => this.handleFailed(source))
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
