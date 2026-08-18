export enum AppRouteName {
  SCROLL = 'scroll',
  DETAIL = 'detail'
}

export class ScrollRouteParam {
}

export class DetailRouteParam {
  readonly localDate: string;

  constructor(localDate: string) {
    this.localDate = localDate;
  }
}
