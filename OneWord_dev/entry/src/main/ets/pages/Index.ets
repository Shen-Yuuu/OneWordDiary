import { common, Want } from '@kit.AbilityKit';
import { AppErrorPanel, AppLoadingPanel } from '../components/common/AppStatusPanel';
import { PaperBackdrop } from '../components/common/PaperBackdrop';
import { PrivacyConsentGate } from '../components/privacy/PrivacyConsentGate';
import { TodayConfirmation } from '../components/diary/TodayConfirmation';
import { TodayEditor } from '../components/diary/TodayEditor';
import { TodayHeader } from '../components/diary/TodayHeader';
import { TodayRecordCard } from '../components/diary/TodayRecordCard';
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
import { PRIVACY_POLICY_URL, PRIVACY_POLICY_VERSION } from '../model/PrivacyPolicy';
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
import { PrivacyConsentViewModel } from '../viewmodel/PrivacyConsentViewModel';

@Entry
@Component
struct Index {
  private navPathStack: NavPathStack = new NavPathStack();

  @State private viewModel: TodayViewModel = new TodayViewModel(
    AppServiceContainer.getDiaryService(),
    AppServiceContainer.getSettingsRepository(),
    new SystemClock(),
    new SystemLocalTimeResolver(),
    new DiaryTextRules(),
    new SystemCompletionFeedback()
  );
  @State private privacyConsentViewModel: PrivacyConsentViewModel = new PrivacyConsentViewModel(
    AppServiceContainer.getSettingsRepository(),
    PRIVACY_POLICY_VERSION
  );

  @StorageProp('currentPaperId') paperId: string = 'warm_paper_dev';

  aboutToAppear(): void {
    this.viewModel.load();
    this.privacyConsentViewModel.load();
  }

  onPageShow(): void {
    if (this.viewModel.uiState !== TodayUiState.APP_INITIALIZING) {
      this.viewModel.load();
    }
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

  private openScroll(): void {
    this.navPathStack.pushPath({
      name: AppRouteName.SCROLL,
      param: new ScrollRouteParam()
    }, false);
  }

  private openDetail(localDate: string): void {
    this.navPathStack.pushPath({
      name: AppRouteName.DETAIL,
      param: new DetailRouteParam(localDate)
    }, false);
  }

  private openSingleShare(localDate: string): void {
    this.navPathStack.pushPath({
      name: AppRouteName.SHARE,
      param: new ShareRouteParam(DiaryShareMode.SINGLE, localDate)
    }, false);
  }

  private openSevenDayShare(): void {
    this.navPathStack.pushPath({
      name: AppRouteName.SHARE,
      param: new ShareRouteParam(DiaryShareMode.SEVEN_DAYS)
    }, false);
  }

  private openSettings(): void {
    this.navPathStack.pushPath({
      name: AppRouteName.SETTINGS,
      param: new SettingsRouteParam()
    }, false);
  }

  private openBackup(paperId: string): void {
    this.navPathStack.pushPath({
      name: AppRouteName.BACKUP,
      param: new BackupRouteParam(paperId)
    }, false);
  }

  private openPrivacy(paperId: string): void {
    this.navPathStack.pushPath({
      name: AppRouteName.PRIVACY,
      param: new PrivacyRouteParam(paperId)
    }, false);
  }

  private finishClear(): void {
    this.navPathStack.clear();
    this.viewModel.load();
  }

  private closeDestination(): void {
    this.navPathStack.pop();
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

  private async declinePrivacyPolicy(): Promise<void> {
    const abilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
    if (abilityContext === undefined) {
      AppLogger.error('privacy_policy.exit_failed context_unavailable');
      return;
    }
    try {
      await abilityContext.terminateSelf();
    } catch (error) {
      AppLogger.error('privacy_policy.exit_failed');
    }
  }
  @Builder
  private routeBuilder(name: string, param: Object) {
    if (name === AppRouteName.SCROLL) {
      ScrollPage({
        onBack: () => this.closeDestination(),
        onOpenDetail: (localDate: string) => this.openDetail(localDate),
        onShareSevenDays: () => this.openSevenDayShare()
      })
    } else if (name === AppRouteName.DETAIL && param instanceof DetailRouteParam) {
      DetailPage({
        localDate: param.localDate,
        onBack: () => this.closeDestination(),
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
        onClearComplete: () => this.finishClear()
      })
    } else if (name === AppRouteName.BACKUP && param instanceof BackupRouteParam) {
      BackupPage({
        paperId: param.paperId,
        onBack: () => this.closeDestination()
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
        if (this.privacyConsentViewModel.needsConsent) {
          PrivacyConsentGate({
            isLoading: this.privacyConsentViewModel.isLoading,
            isSaving: this.privacyConsentViewModel.isSaving,
            errorMessage: this.privacyConsentViewModel.errorMessage,
            onViewFullPolicy: () => this.openOfficialPrivacyPolicy(),
            onDeclineAndExit: () => this.declinePrivacyPolicy(),
            onAcceptAndContinue: () => this.privacyConsentViewModel.accept()
          })
        } else {
        PaperBackdrop({ paperId: this.paperId })

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
            paperId: this.paperId,
            isRevision: this.viewModel.isRevisionDraft,
            isBusy: this.viewModel.isBusy,
            errorMessage: this.viewModel.errorMessage,
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
                contentCount: this.viewModel.contentCount,
                noteCount: this.viewModel.noteCount,
                recordCount: this.viewModel.recordCount,
                contentError: this.viewModel.contentError,
                noteError: this.viewModel.noteError,
                canConfirm: this.viewModel.canConfirmWord,
                isRevision: this.viewModel.isRevisionDraft,
                inspiration: this.viewModel.inspiration,
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
            left: $r('app.float.page_horizontal_margin'),
            right: $r('app.float.page_horizontal_margin')
          })
          .backgroundColor(this.paperId === 'plain_ash_dev' ? $r('app.color.paper_plain') : $r('app.color.paper_warm'))

        }
      }
        }
      .width('100%')
      .height('100%')
      .backgroundColor(this.paperId === 'plain_ash_dev' ? $r('app.color.paper_plain') : $r('app.color.paper_warm'))
    }
    .width('100%')
    .height('100%')
    .navDestination(this.routeBuilder)
    .hideTitleBar(true)
    .mode(NavigationMode.Stack)
    .backgroundColor(this.paperId === 'plain_ash_dev' ? $r('app.color.paper_plain') : $r('app.color.paper_warm'))
  }
}
