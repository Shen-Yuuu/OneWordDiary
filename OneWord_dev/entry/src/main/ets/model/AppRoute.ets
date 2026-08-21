import { DiaryShareMode } from './ShareModel';

export enum AppRouteName {
  SCROLL = 'scroll',
  DETAIL = 'detail',
  SETTINGS = 'settings',
  BACKUP = 'backup',
  PRIVACY = 'privacy',
  SHARE = 'share'
}

export class ScrollRouteParam {
}

export class SettingsRouteParam {
}

export class BackupRouteParam {
  readonly paperId: string;

  constructor(paperId: string) {
    this.paperId = paperId;
  }
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

export class ShareRouteParam {
  readonly mode: DiaryShareMode;
  readonly localDate: string | null;

  constructor(mode: DiaryShareMode, localDate: string | null = null) {
    this.mode = mode;
    this.localDate = localDate;
  }
}