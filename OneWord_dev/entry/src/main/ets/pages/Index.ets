import { common, Want } from '@kit.AbilityKit';
import { curves } from '@kit.ArkUI';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { AppErrorPanel, AppLoadingPanel } from '../components/common/AppStatusPanel';
import { PaperBackdrop } from '../components/common/PaperBackdrop';
import { DiaryBackground } from '../components/common/DiaryBackground';
import { WidgetSnapshotCard } from '../components/common/WidgetSnapshotCard';
import { TodayConfirmation } from '../components/diary/TodayConfirmation';
import { TodayEditor } from '../components/diary/TodayEditor';
import { TodayHeader } from '../components/diary/TodayHeader';
import { TodayRecordCard } from '../components/diary/TodayRecordCard';
import { styleForPaper } from '../constants/StyleTokens';
import { FontPresetId } from '../constants/FontCatalog';
import {
  AppRouteName,
  BackupRouteParam,
  DetailRouteParam,
  PrivacyRouteParam,
  ScrollRouteParam,
  SettingsRouteParam,
  ShareRouteParam
} from '../model/AppRoute';
import { DiaryShareMode } from '../model/ShareModel';
import { PRIVACY_POLICY_URL } from '../model/PrivacyPolicy';
import { TodayUiState } from '../model/TodayUiState';
import { BackupPage } from './BackupPage';
import { DetailPage } from './DetailPage';
import { ScrollPage } from './ScrollPage';
import { PrivacyPage } from './PrivacyPage';
import { SettingsPage } from './SettingsPage';
import { SharePreviewPage } from './SharePreviewPage';
import { AppServiceContainer } from '../service/AppServiceContainer';
import { SystemCompletionFeedback } from '../service/CompletionFeedback';
import { DiaryTextRules } from '../service/DiaryTextRules';
import { SystemClock } from '../utils/Clock';
import { AppLogger } from '../utils/AppLogger';

import { SystemLocalTimeResolver } from '../utils/LocalTimeResolver';
import { TodayViewModel } from '../viewmodel/TodayViewModel';

@Entry
@Component
struct Index {
  private navPathStack: NavPathStack = new NavPathStack();
  private readonly clock: SystemClock = new SystemClock();
  private readonly localTimeResolver: SystemLocalTimeResolver = new SystemLocalTimeResolver();
  private midnightRefreshTimer: number = -1;
  private isPageActive: boolean = false;

  @State private viewModel: TodayViewModel = new TodayViewModel(
    AppServiceContainer.getDiaryService(),
    AppServiceContainer.getSettingsRepository(),
    this.clock,
    this.localTimeResolver,
    new DiaryTextRules(),
    new SystemCompletionFeedback(),
    AppServiceContainer.getBackgroundImageService()
  );
  @StorageProp('currentPaperId') paperId: string = 'warm_paper_dev';
  @State private pickerResumePending: boolean = false;
  @State private pickerError: string = '';

  aboutToAppear(): void {
    this.isPageActive = true;
    this.scheduleMidnightRefresh();
    this.viewModel.load();
  }

  onPageShow(): void {
    this.isPageActive = true;
    this.scheduleMidnightRefresh();
    if (this.pickerResumePending) {
      this.pickerResumePending = false;
      return;
    }
    if (this.viewModel.uiState !== TodayUiState.APP_INITIALIZING && !this.viewModel.isPickingBackground) {
      this.viewModel.load(true);
    }
  }

  onPageHide(): void {
    this.isPageActive = false;
    this.clearMidnightRefreshTimer();
  }

  aboutToDisappear(): void {
    this.isPageActive = false;
    this.clearMidnightRefreshTimer();
  }

  private clearMidnightRefreshTimer(): void {
    if (this.midnightRefreshTimer !== -1) {
      clearTimeout(this.midnightRefreshTimer);
      this.midnightRefreshTimer = -1;
    }
  }

  private scheduleMidnightRefresh(): void {
    this.clearMidnightRefreshTimer();
    if (!this.isPageActive) {
      return;
    }
    const now = this.clock.now();
    const refreshAt = this.localTimeResolver.resolve(now).revisionDeadlineAt + 1;
    this.midnightRefreshTimer = setTimeout(() => this.refreshForNewLocalDate(), Math.max(1, refreshAt - now));
  }

  private async refreshForNewLocalDate(): Promise<void> {
    this.midnightRefreshTimer = -1;
    if (!this.isPageActive) {
      return;
    }
    if (this.viewModel.isBusy) {
      this.midnightRefreshTimer = setTimeout(() => this.refreshForNewLocalDate(), 1000);
      return;
    }
    await this.viewModel.load();
    this.scheduleMidnightRefresh();
  }

  onBackPress(): boolean {
    if (this.viewModel.isConfirmationVisible) {
      this.viewModel.cancelConfirmation();
      return true;
    }
    if (this.viewModel.isRevisionDraft) {
      this.viewModel.cancelRevision();
      return true;
    }
    return false;
  }

  private async chooseBackground(): Promise<void> {
    if (this.viewModel.isPickingBackground) {
      return;
    }
    this.pickerError = '';
    this.pickerResumePending = true;
    const pickerDate = this.viewModel.localDate;
    try {
      const options = new photoAccessHelper.PhotoSelectOptions();
      options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      options.maxSelectNumber = 1;
      const picker = new photoAccessHelper.PhotoViewPicker();
      const result = await picker.select(options);
      const currentDate = this.localTimeResolver.resolve(this.clock.now()).localDate;
      if (pickerDate.length === 0 || pickerDate !== this.viewModel.localDate || currentDate !== pickerDate) {
        this.pickerResumePending = false;
        await this.viewModel.load();
        return;
      }
      if (result.photoUris.length === 0) {
        return;
      }
      await this.viewModel.selectBackgroundFromUri(result.photoUris[0]);
    } catch (error) {
      this.pickerError = '暂时无法打开相册，请稍后再试';
    }
  }
  private openScroll(): void {
    this.navPathStack.pushPath({
      name: AppRouteName.SCROLL,
      param: new ScrollRouteParam()
    }, true);
  }

  private openDetail(localDate: string, sharedElementId: string): void {
    if (sharedElementId.length > 0) {
      this.getUIContext().animateTo({ curve: curves.interpolatingSpring(0, 1, 342, 38) }, () => {
        this.navPathStack.pushPath({
          name: AppRouteName.DETAIL,
          param: new DetailRouteParam(localDate, sharedElementId)
        }, false);
      });
    } else {
      this.navPathStack.pushPath({
        name: AppRouteName.DETAIL,
        param: new DetailRouteParam(localDate)
      }, true);
    }
  }

  private openSingleShare(localDate: string): void {
    this.navPathStack.pushPath({
      name: AppRouteName.SHARE,
      param: new ShareRouteParam(DiaryShareMode.SINGLE, localDate)
    }, true);
  }

  private openSevenDayShare(): void {
    this.navPathStack.pushPath({
      name: AppRouteName.SHARE,
      param: new ShareRouteParam(DiaryShareMode.SEVEN_DAYS)
    }, true);
  }

  private openSettings(): void {
    this.navPathStack.pushPath({
      name: AppRouteName.SETTINGS,
      param: new SettingsRouteParam()
    }, true);
  }

  private openBackup(paperId: string): void {
    this.navPathStack.pushPath({
      name: AppRouteName.BACKUP,
      param: new BackupRouteParam(paperId)
    }, true);
  }

  private openPrivacy(paperId: string): void {
    this.navPathStack.pushPath({
      name: AppRouteName.PRIVACY,
      param: new PrivacyRouteParam(paperId)
    }, true);
  }

  private finishClear(): void {
    this.navPathStack.clear();
    this.viewModel.load();
  }

  private refreshAfterImport(): void {
    AppLogger.info('backup.import_complete refresh_today');
    this.viewModel.load();
  }

  private closeDestination(): void {
    this.navPathStack.pop();
  }

  private closeDetail(sharedElementId: string): void {
    if (sharedElementId.length > 0) {
      this.getUIContext().animateTo({ curve: curves.interpolatingSpring(0, 1, 342, 38) }, () => {
        this.navPathStack.pop(false);
      });
    } else {
      this.closeDestination();
    }
  }

  private applySelectedFont(fontPresetId: FontPresetId): void {
    AppLogger.info(`font.index_receive id=${fontPresetId}`);
    this.viewModel.applyFontPreference(fontPresetId);
  }

  private applySelectedBackgroundOpacity(backgroundOpacity: number): void {
    this.viewModel.applyBackgroundOpacityPreference(backgroundOpacity);
  }


  private async openOfficialPrivacyPolicy(): Promise<void> {
    const abilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
    if (abilityContext === undefined) {
      AppLogger.error('privacy_policy.open_failed context_unavailable');
      return;
    }
    const want: Want = {
      action: 'ohos.want.action.viewData',
      uri: PRIVACY_POLICY_URL,
      entities: ['entity.system.browsable']
    };
    try {
      await abilityContext.startAbility(want);
    } catch (error) {
      AppLogger.error('privacy_policy.open_failed');
    }
  }

  @Builder
  private routeBuilder(name: string, param: Object) {
    if (name === AppRouteName.SCROLL) {
      ScrollPage({
        onBack: () => this.closeDestination(),
        onOpenDetail: (localDate: string, sharedElementId: string) => this.openDetail(localDate, sharedElementId),
        onShareSevenDays: () => this.openSevenDayShare()
      })
    } else if (name === AppRouteName.DETAIL && param instanceof DetailRouteParam) {
      DetailPage({
        localDate: param.localDate,
        sharedElementId: param.sharedElementId,
        onBack: () => this.closeDetail(param.sharedElementId),
        onShare: () => this.openSingleShare(param.localDate)
      })
    } else if (name === AppRouteName.SHARE && param instanceof ShareRouteParam) {
      SharePreviewPage({
        initialMode: param.mode,
        preferredSingleDate: param.localDate,
        onBack: () => this.closeDestination()
      })
    } else if (name === AppRouteName.SETTINGS) {
      SettingsPage({
        onBack: () => this.closeDestination(),
        onOpenPrivacy: (paperId: string) => this.openPrivacy(paperId),
        onOpenBackup: (paperId: string) => this.openBackup(paperId),
        onClearComplete: () => this.finishClear(),
        onFontChanged: (fontPresetId: FontPresetId) => this.applySelectedFont(fontPresetId),
        onBackgroundOpacityChanged: (backgroundOpacity: number) =>
          this.applySelectedBackgroundOpacity(backgroundOpacity)
      })
    } else if (name === AppRouteName.BACKUP && param instanceof BackupRouteParam) {
      BackupPage({
        paperId: param.paperId,
        onBack: () => this.closeDestination(),
        onImportComplete: () => this.refreshAfterImport()
      })
    } else if (name === AppRouteName.PRIVACY && param instanceof PrivacyRouteParam) {
      PrivacyPage({
        paperId: param.paperId,
        onBack: () => this.closeDestination(),
        onOpenOfficialPolicy: () => this.openOfficialPrivacyPolicy()
      })
    }
  }


  build() {
    Navigation(this.navPathStack) {
      Stack() {
        PaperBackdrop({ paperId: this.paperId })
        DiaryBackground({
          imageUri: this.viewModel.backgroundImageUri,
          paperId: this.paperId,
          imageOpacity: this.viewModel.displayedBackgroundOpacity
        })
        WidgetSnapshotCard()
          .position({ x: -600, y: -600 })

        if (this.viewModel.uiState === TodayUiState.APP_INITIALIZING) {
          AppLoadingPanel()
        } else if (this.viewModel.uiState === TodayUiState.APP_STORAGE_ERROR) {
          AppErrorPanel({
            message: this.viewModel.errorMessage,
            onRetry: () => this.viewModel.load()
          })
        } else if (this.viewModel.isConfirmationVisible) {
          TodayConfirmation({
            dateText: this.viewModel.displayDate,
            draftType: this.viewModel.draftType,
            content: this.viewModel.draftContent,
            contentCount: this.viewModel.contentCount,
            note: this.viewModel.draftNote,
            fontId: this.viewModel.fontPresetId,
            paperId: this.paperId,
            isRevision: this.viewModel.isRevisionDraft,
            isBusy: this.viewModel.isBusy,
            errorMessage: this.viewModel.errorMessage,
            backgroundImageUri: this.viewModel.backgroundImageUri,
            onConfirm: () => this.viewModel.confirmPending(),
            onCancel: () => this.viewModel.errorMessage.length > 0 ?
              this.viewModel.returnFromError() : this.viewModel.cancelConfirmation()
          })
            .transition(TransitionEffect.OPACITY)
        } else {
          Column() {
            TodayHeader({
              dateText: this.viewModel.displayDate,
              weekdayText: this.viewModel.weekday,
              onScroll: () => this.openScroll(),
              onSettings: () => this.openSettings()
            })

            if (this.viewModel.isEditingState) {
              TodayEditor({
                content: this.viewModel.draftContent,
                note: this.viewModel.draftNote,
                fontId: this.viewModel.fontPresetId,
                contentCount: this.viewModel.contentCount,
                noteCount: this.viewModel.noteCount,
                recordCount: this.viewModel.recordCount,
                contentError: this.viewModel.contentError,
                noteError: this.viewModel.noteError,
                canConfirm: this.viewModel.canConfirmWord,
                isRevision: this.viewModel.isRevisionDraft,
                inspiration: this.viewModel.inspiration,
                backgroundImageUri: this.viewModel.backgroundImageUri,
                paperId: this.paperId,
                isPickingBackground: this.viewModel.isPickingBackground,
                backgroundError: this.pickerError.length > 0 ? this.pickerError : this.viewModel.backgroundError,
                onChooseBackground: () => this.chooseBackground(),
                onRemoveBackground: () => {
                  this.pickerError = '';
                  this.viewModel.removeBackgroundImage();
                },
                onContentChange: (value: string) => this.viewModel.setContent(value),
                onNoteChange: (value: string) => this.viewModel.setNote(value),
                onRefreshInspiration: () => this.viewModel.nextInspiration(),
                onConfirmWord: () => this.viewModel.showWordConfirmation(),
                onConfirmBlank: () => this.viewModel.showBlankConfirmation(),
                onCancelRevision: () => this.viewModel.cancelRevision()
              })
                .layoutWeight(1)
            } else if (this.viewModel.isRecordedState) {
              TodayRecordCard({
                dateText: this.viewModel.displayDate,
                recordType: this.viewModel.recordDisplayType,
                content: this.viewModel.recordDisplayContent,
                contentCount: this.viewModel.recordDisplayContentCount,
                note: this.viewModel.recordDisplayNote,
                fontId: this.viewModel.recordFontId,
                paperId: this.viewModel.recordPaperId,
                canRevise: this.viewModel.uiState === TodayUiState.TODAY_RECORDED_WORD_EDITABLE ||
                  this.viewModel.uiState === TodayUiState.TODAY_RECORDED_BLANK_EDITABLE,
                revisionDeadline: this.viewModel.revisionDeadlineLabel,
                finalLabel: this.viewModel.uiState === TodayUiState.TODAY_FINAL_REVISED ? '已经定稿' : '今日已定稿',
                recordCount: this.viewModel.recordCount,
                onRevise: () => this.viewModel.startRevision(),
                onShare: () => this.openSingleShare(this.viewModel.localDate)
              })
                .layoutWeight(1)
                .animation({ duration: 240, curve: Curve.EaseOut })
            }
          }
          .width('100%')
          .height('100%')
          .padding({
            top: $r('app.float.immersive_top_content_offset'),
            bottom: $r('app.float.immersive_bottom_content_offset'),
            left: $r('app.float.page_horizontal_margin'),
            right: $r('app.float.page_horizontal_margin')
          })
          .backgroundColor(this.viewModel.backgroundImageUri.length > 0 ? Color.Transparent :
            styleForPaper(this.paperId).light.background)

        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(styleForPaper(this.paperId).light.background)
    }
    .width('100%')
    .height('100%')
    .navDestination(this.routeBuilder)
    .hideTitleBar(true)
    .mode(NavigationMode.Stack)
    .backgroundColor(styleForPaper(this.paperId).light.background)
  }
}
