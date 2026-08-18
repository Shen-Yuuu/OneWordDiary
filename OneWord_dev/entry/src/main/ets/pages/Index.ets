import { AppErrorPanel, AppLoadingPanel } from '../components/common/AppStatusPanel';
import { TodayConfirmation } from '../components/diary/TodayConfirmation';
import { TodayEditor } from '../components/diary/TodayEditor';
import { TodayHeader } from '../components/diary/TodayHeader';
import { TodayRecordCard } from '../components/diary/TodayRecordCard';
import { AppRouteName, DetailRouteParam, ScrollRouteParam } from '../model/AppRoute';
import { RecordType } from '../model/DailyRecord';
import { TodayUiState } from '../model/TodayUiState';
import { DetailPage } from './DetailPage';
import { ScrollPage } from './ScrollPage';
import { AppServiceContainer } from '../service/AppServiceContainer';
import { SystemCompletionFeedback } from '../service/CompletionFeedback';
import { DiaryTextRules } from '../service/DiaryTextRules';
import { SystemClock } from '../utils/Clock';
import { SystemLocalTimeResolver } from '../utils/LocalTimeResolver';
import { TodayViewModel } from '../viewmodel/TodayViewModel';

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

  get recordType(): RecordType {
    return this.viewModel.record === null ? RecordType.WORD : this.viewModel.record.recordType;
  }

  get recordContent(): string {
    return this.viewModel.record === null || this.viewModel.record.content === null ? '' :
      this.viewModel.record.content;
  }


  get recordCanRevise(): boolean {
    return this.viewModel.uiState === TodayUiState.TODAY_RECORDED_WORD_EDITABLE ||
      this.viewModel.uiState === TodayUiState.TODAY_RECORDED_BLANK_EDITABLE;
  }

  get finalLabel(): string {
    return this.viewModel.uiState === TodayUiState.TODAY_FINAL_REVISED ? '已经定稿' : '今日已定稿';
  }

  aboutToAppear(): void {
    this.viewModel.load();
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
    if (this.viewModel.noteExpanded) {
      this.viewModel.toggleNote();
      return true;
    }
    return false;
  }

  private openScroll(): void {
    this.navPathStack.pushPath({
      name: AppRouteName.SCROLL,
      param: new ScrollRouteParam()
    });
  }

  private openDetail(localDate: string): void {
    this.navPathStack.pushPath({
      name: AppRouteName.DETAIL,
      param: new DetailRouteParam(localDate)
    });
  }

  private closeDestination(): void {
    this.navPathStack.pop();
  }

  @Builder
  private routeBuilder(name: string, param: Object) {
    if (name === AppRouteName.SCROLL) {
      ScrollPage({
        onBack: () => this.closeDestination(),
        onOpenDetail: (localDate: string) => this.openDetail(localDate),
        onShareSevenDays: () => this.showComingSoon('最近七日分享将在节点 5 开放')
      })
    } else if (name === AppRouteName.DETAIL && param instanceof DetailRouteParam) {
      DetailPage({
        localDate: param.localDate,
        onBack: () => this.closeDestination(),
        onShare: () => this.showComingSoon('单日分享将在节点 5 开放')
      })
    }
  }

  private showComingSoon(message: string): void {
    this.getUIContext().getPromptAction().showToast({
      message: message,
      duration: 1800
    });
  }

  build() {
    Navigation(this.navPathStack) {
      Stack() {
        if (this.viewModel.uiState === TodayUiState.APP_INITIALIZING) {
          AppLoadingPanel()
        } else if (this.viewModel.uiState === TodayUiState.APP_STORAGE_ERROR) {
          AppErrorPanel({
            message: this.viewModel.errorMessage,
            onRetry: () => this.viewModel.load()
          })
        } else {
          Column() {
            TodayHeader({
              dateText: this.viewModel.displayDate,
              weekdayText: this.viewModel.weekday,
              onScroll: () => this.openScroll(),
              onSettings: () => this.showComingSoon('设置将在节点 4 开放')
            })

            if (this.viewModel.isEditingState) {
              Scroll() {
                TodayEditor({
                  content: this.viewModel.draftContent,
                  note: this.viewModel.draftNote,
                  contentCount: this.viewModel.contentCount,
                  noteCount: this.viewModel.noteCount,
                  recordCount: this.viewModel.recordCount,
                  contentError: this.viewModel.contentError,
                  noteError: this.viewModel.noteError,
                  noteExpanded: this.viewModel.noteExpanded,
                  canConfirm: this.viewModel.canConfirmWord,
                  isRevision: this.viewModel.isRevisionDraft,
                  inspiration: this.viewModel.inspiration,
                  onContentChange: (value: string) => this.viewModel.setContent(value),
                  onNoteChange: (value: string) => this.viewModel.setNote(value),
                  onToggleNote: () => this.viewModel.toggleNote(),
                  onRefreshInspiration: () => this.viewModel.nextInspiration(),
                  onConfirmWord: () => this.viewModel.showWordConfirmation(),
                  onConfirmBlank: () => this.viewModel.showBlankConfirmation(),
                  onCancelRevision: () => this.viewModel.cancelRevision()
                })
                  .padding({ top: 4, bottom: 32 })
              }
              .layoutWeight(1)
              .scrollBar(BarState.Off)
              .edgeEffect(EdgeEffect.Spring)
            } else if (this.viewModel.isRecordedState) {
              TodayRecordCard({
                dateText: this.viewModel.displayDate,
                recordType: this.recordType,
                content: this.recordContent,
                canRevise: this.recordCanRevise,
                revisionDeadline: this.viewModel.revisionDeadlineLabel,
                finalLabel: this.finalLabel,
                recordCount: this.viewModel.recordCount,
                onRevise: () => this.viewModel.startRevision(),
                onShare: () => this.showComingSoon('分享预览将在节点 5 开放')
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
          .backgroundColor($r('app.color.app_background'))

          if (this.viewModel.isConfirmationVisible) {
            TodayConfirmation({
              dateText: this.viewModel.displayDate,
              draftType: this.viewModel.draftType,
              content: this.viewModel.draftContent,
              note: this.viewModel.draftNote,
              isRevision: this.viewModel.isRevisionDraft,
              isBusy: this.viewModel.isBusy,
              errorMessage: this.viewModel.errorMessage,
              onConfirm: () => this.viewModel.confirmPending(),
              onCancel: () => this.viewModel.errorMessage.length > 0 ?
                this.viewModel.returnFromError() : this.viewModel.cancelConfirmation()
            })
              .transition(TransitionEffect.OPACITY)
          }
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.app_background'))
    }
    .width('100%')
    .height('100%')
    .navDestination(this.routeBuilder)
    .hideTitleBar(true)
    .mode(NavigationMode.Stack)
    .backgroundColor($r('app.color.app_background'))
  }
}
