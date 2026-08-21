export enum AppRouteName {
  SCROLL = 'scroll',
  DETAIL = 'detail',
  SETTINGS = 'settings',
  PRIVACY = 'privacy'
}

export class ScrollRouteParam {
}

export class SettingsRouteParam {
}

export class PrivacyRouteParam {
  readonly paperId: string;

  constructor(paperId: string) {
    this.paperId = paperId;
  }
}

export class DetailRouteParam {
  readonly localDate: string;

  constructor(localDate: string) {
    this.localDate = localDate;
  }
}