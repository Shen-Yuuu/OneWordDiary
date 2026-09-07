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
  @Prop scrimOpacity: number = 0.68;
  @Prop fixedLightScrim: boolean = false;
  @Prop reloadKey: number = 0;
  @State private isLoaded: boolean = false;
  onReady: (imageUri: string, reloadKey: number) => void =
    (imageUri: string, reloadKey: number) => {
    };
  onFailed: (imageUri: string, reloadKey: number) => void =
    (imageUri: string, reloadKey: number) => {
    };

  get paperColor(): ResourceColor {
    if (this.fixedLightScrim) {
      return this.paperId === 'plain_ash_dev' ? '#F7F7F5' : '#FDF8F7';
    }
    return this.paperId === 'plain_ash_dev' ? $r('app.color.paper_plain') : $r('app.color.paper_warm');
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
        }
        .width('100%')
        .height('100%')
        .opacity(this.isLoaded ? 1 : 0)
        .hitTestBehavior(HitTestMode.None)
        .accessibilityLevel('no')
      }, (source: DiaryBackgroundSource) => source.uri + ':' + source.reloadKey.toString())
    }
  }
}
