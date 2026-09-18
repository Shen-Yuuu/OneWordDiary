import { scriptManager } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { DailyRecord, DiaryEntryInput, RecordType } from '../../../src/main/ets/model/DailyRecord';
import { DiaryError, DiaryErrorCode } from '../../../src/main/ets/model/DiaryError';
import {
  FontPresetId,
  fontPresetIdFromValue,
  isSelectableFontPreset
} from '../../../src/main/ets/constants/FontCatalog';
import {
  StylePresetId,
  isSupportedStylePreset,
  paperIdForStyle,
  styleForPreset,
  stylePresetIdFromValue
} from '../../../src/main/ets/constants/StyleTokens';
import { AppServiceContainer } from '../../../src/main/ets/service/AppServiceContainer';
import { SettingsRepository } from '../../../src/main/ets/repository/SettingsRepository';
import { AppLogger } from '../../../src/main/ets/utils/AppLogger';
import { syncWidgetFromRecord } from '../../../src/main/ets/utils/WidgetSync';
import { ThemeChrome } from '../../../src/main/ets/utils/ThemeChrome';

const SKILL_TAG: string = 'skill.diary';
const READY_POLL_INTERVAL_MS: number = 100;
const READY_POLL_MAX_TIMES: number = 50;

// 主题中文说法 → 预设 id（与 SKILL.md 声明保持一致）
const THEME_ALIASES: Record<string, string> = {
  '纸墨': 'paper_ink',
  '墨色': 'paper_ink',
  '素灰': 'plain_ash',
  '灰色': 'plain_ash',
  '松青': 'pine_mist',
  '青色': 'pine_mist',
  '雾蓝': 'mist_blue',
  '蓝色': 'mist_blue',
  '杏笺': 'apricot_paper',
  '杏色': 'apricot_paper',
  '瑰粉': 'rose_pink',
  '玫瑰粉': 'rose_pink',
  '粉色': 'rose_pink'
};

const THEME_NAMES: Record<string, string> = {
  'paper_ink': '纸墨',
  'plain_ash': '素灰',
  'pine_mist': '松青',
  'mist_blue': '雾蓝',
  'apricot_paper': '杏笺',
  'rose_pink': '瑰粉'
};

// 字体中文说法 → 预设 id（与 SKILL.md 声明保持一致）
const FONT_ALIASES: Record<string, string> = {
  '小楷': 'oneword_kai',
  '文楷': 'oneword_kai',
  '楷体': 'oneword_kai',
  '默认字体': 'oneword_kai',
  '默认': 'oneword_kai',
  '得意黑': 'smiley_sans_oblique',
  '得意黑楷体': 'smiley_sans_oblique',
  '悠然': 'slide_youran',
  '悠然小楷': 'slide_youran',
  '悠然小楷体': 'slide_youran',
  '明朝': 'mingchao',
  '明朝体': 'mingchao',
  '汇文明朝体': 'mingchao'
};

const FONT_NAMES: Record<string, string> = {
  'oneword_kai': '小楷（默认字体）',
  'smiley_sans_oblique': '得意黑楷体',
  'slide_youran': '悠然小楷体',
  'mingchao': '汇文明朝体'
};

function themeNameFor(id: string): string {
  const name = THEME_NAMES[id];
  return name !== undefined ? name : id;
}

function fontNameFor(id: string): string {
  const name = FONT_NAMES[id];
  return name !== undefined ? name : id;
}

function resolveThemeId(raw: string): StylePresetId | null {
  const value = raw.trim();
  if (value.length === 0) {
    return null;
  }
  if (isSupportedStylePreset(value)) {
    return stylePresetIdFromValue(value);
  }
  const aliased = THEME_ALIASES[value];
  if (aliased !== undefined && isSupportedStylePreset(aliased)) {
    return stylePresetIdFromValue(aliased);
  }
  return null;
}

function resolveFontId(raw: string): FontPresetId | null {
  const value = raw.trim();
  if (value.length === 0) {
    return null;
  }
  if (isSelectableFontPreset(value)) {
    return fontPresetIdFromValue(value);
  }
  const aliased = FONT_ALIASES[value];
  if (aliased !== undefined && isSelectableFontPreset(aliased)) {
    return fontPresetIdFromValue(aliased);
  }
  return null;
}

export default class DiarySkill {
  public async recordTodayDiary(
    info: scriptManager.ArkTSScriptInfo,
    ...argv: string[]
  ): Promise<void> {
    const content: string = argv.length > 0 ? argv[0].trim() : '';
    const remarkRaw: string = argv.length > 1 ? argv[1].trim() : '';
    const themeRaw: string = argv.length > 2 ? argv[2].trim() : '';
    const fontRaw: string = argv.length > 3 ? argv[3].trim() : '';

    if (content.length === 0) {
      await this.reportFailure(
        info,
        'ERR_INVALID_PARAMS',
        'content is empty',
        '请告诉我想记下的一至四个字'
      );
      return;
    }

    const themeId: StylePresetId | null = resolveThemeId(themeRaw);
    if (themeRaw.trim().length > 0 && themeId === null) {
      await this.reportFailure(
        info,
        'ERR_INVALID_PARAMS',
        `unsupported theme: ${themeRaw}`,
        `暂不支持主题「${themeRaw}」，可选：纸墨、素灰、松青、雾蓝、杏笺、瑰粉`
      );
      return;
    }
    const fontId: FontPresetId | null = resolveFontId(fontRaw);
    if (fontRaw.trim().length > 0 && fontId === null) {
      await this.reportFailure(
        info,
        'ERR_INVALID_PARAMS',
        `unsupported font: ${fontRaw}`,
        `暂不支持字体「${fontRaw}」，可选：小楷、得意黑、悠然小楷、汇文明朝体`
      );
      return;
    }

    if (!(await this.waitServicesReady())) {
      await this.reportFailure(
        info,
        'ERR_NOT_READY',
        'app services not ready',
        '应用还没有准备好，请稍后再试一次'
      );
      return;
    }

    AppLogger.info(`${SKILL_TAG} record_invoked content_len=${content.length} theme=${themeId === null ? '-' : themeId} font=${fontId === null ? '-' : fontId}`);

    try {
      const settingsRepository = AppServiceContainer.getSettingsRepository();
      const current = await settingsRepository.load();
      const stylePresetId: StylePresetId = themeId !== null ? themeId : current.stylePresetId;
      const fontPresetId: FontPresetId = fontId !== null ? fontId : current.fontPresetId;
      const style = styleForPreset(stylePresetId);
      const input: DiaryEntryInput = {
        recordType: RecordType.WORD,
        content: content,
        note: remarkRaw.length === 0 ? null : remarkRaw,
        fontId: fontPresetId,
        paperId: style.paperId,
        backgroundImageId: null,
        backgroundOpacity: 0.1
      };
      const saved: DailyRecord = await AppServiceContainer.getDiaryService().submit(input);
      const settingsSaved = await this.saveRequestedStyle(settingsRepository, themeId, fontId);
      await this.syncWidgetQuietly(saved);
      this.notifyRecordChanged();

      const data: Record<string, Object> = {
        'date': saved.localDate,
        'content': saved.content === null ? '' : saved.content,
        'note': saved.note === null ? '' : saved.note,
        'theme': stylePresetId,
        'themeName': themeNameFor(stylePresetId),
        'font': fontPresetId,
        'fontName': fontNameFor(fontPresetId),
        'settingsSaved': settingsSaved
      };
      const payload: Record<string, Object> = {
        'type': 'result',
        'status': 'success',
        'data': data
      };
      AppLogger.info(`${SKILL_TAG} record_success date=${saved.localDate}`);
      await this.report(info, { code: 0, result: payload });
    } catch (error) {
      await this.reportDiaryError(info, error);
    }
  }

  public async applyDiaryStyle(
    info: scriptManager.ArkTSScriptInfo,
    ...argv: string[]
  ): Promise<void> {
    const themeRaw: string = argv.length > 0 ? argv[0].trim() : '';
    const fontRaw: string = argv.length > 1 ? argv[1].trim() : '';

    if (themeRaw.length === 0 && fontRaw.length === 0) {
      await this.reportFailure(
        info,
        'ERR_INVALID_PARAMS',
        'theme and font are both empty',
        '请告诉我想使用的主题或字体'
      );
      return;
    }

    const themeId: StylePresetId | null = resolveThemeId(themeRaw);
    if (themeRaw.length > 0 && themeId === null) {
      await this.reportFailure(
        info,
        'ERR_INVALID_PARAMS',
        `unsupported theme: ${themeRaw}`,
        `暂不支持主题「${themeRaw}」，可选：纸墨、素灰、松青、雾蓝、杏笺、瑰粉`
      );
      return;
    }
    const fontId: FontPresetId | null = resolveFontId(fontRaw);
    if (fontRaw.length > 0 && fontId === null) {
      await this.reportFailure(
        info,
        'ERR_INVALID_PARAMS',
        `unsupported font: ${fontRaw}`,
        `暂不支持字体「${fontRaw}」，可选：小楷、得意黑、悠然小楷、汇文明朝体`
      );
      return;
    }

    if (!(await this.waitServicesReady())) {
      await this.reportFailure(
        info,
        'ERR_NOT_READY',
        'app services not ready',
        '应用还没有准备好，请稍后再试一次'
      );
      return;
    }

    AppLogger.info(`${SKILL_TAG} style_invoked theme=${themeId === null ? '-' : themeId} font=${fontId === null ? '-' : fontId}`);

    try {
      const settingsRepository = AppServiceContainer.getSettingsRepository();
      const current = await settingsRepository.load();
      if (themeId !== null) {
        await settingsRepository.saveStylePresetId(themeId);
        this.syncPaperQuietly(themeId);
      }
      if (fontId !== null) {
        await settingsRepository.saveFontPresetId(fontId);
        this.syncFontQuietly(fontId);
      }
      this.notifyStyleChanged();

      const data: Record<string, Object> = {
        'theme': themeId !== null ? themeId : current.stylePresetId,
        'themeName': themeNameFor(themeId !== null ? themeId : current.stylePresetId),
        'font': fontId !== null ? fontId : current.fontPresetId,
        'fontName': fontNameFor(fontId !== null ? fontId : current.fontPresetId)
      };
      const payload: Record<string, Object> = {
        'type': 'result',
        'status': 'success',
        'data': data
      };
      AppLogger.info(`${SKILL_TAG} style_success`);
      await this.report(info, { code: 0, result: payload });
    } catch (error) {
      const err = error as BusinessError;
      AppLogger.error(`${SKILL_TAG} style_failed code=${err.code}`);
      try {
        const persisted = await AppServiceContainer.getSettingsRepository().load();
        this.syncAppearance(persisted.stylePresetId, persisted.fontPresetId);
        this.notifyStyleChanged();
      } catch (refreshError) {
        AppLogger.warn(`${SKILL_TAG} style_refresh_failed`);
      }
      await this.reportFailure(
        info,
        'ERR_INTERNAL',
        `save style failed: ${err.message}`,
        '设置样式失败了，请稍后再试'
      );
    }
  }

  private async waitServicesReady(): Promise<boolean> {
    for (let i = 0; i < READY_POLL_MAX_TIMES; i++) {
      if (AppServiceContainer.isReady()) {
        return true;
      }
      await new Promise<void>((resolve) => {
        setTimeout(resolve, READY_POLL_INTERVAL_MS);
      });
    }
    return AppServiceContainer.isReady();
  }

  private async saveRequestedStyle(settingsRepository: SettingsRepository,
    themeId: StylePresetId | null, fontId: FontPresetId | null): Promise<boolean> {
    let saved = true;
    if (themeId !== null) {
      try {
        await settingsRepository.saveStylePresetId(themeId);
      } catch (error) {
        saved = false;
        AppLogger.warn(`${SKILL_TAG} theme_default_save_failed`);
      }
      if (saved) {
        this.syncPaperQuietly(themeId);
      }
    }
    if (fontId !== null) {
      try {
        await settingsRepository.saveFontPresetId(fontId);
        this.syncFontQuietly(fontId);
      } catch (error) {
        saved = false;
        AppLogger.warn(`${SKILL_TAG} font_default_save_failed`);
      }
    }
    return saved;
  }

  private syncAppearance(themeId: StylePresetId, fontId: FontPresetId): void {
    this.syncPaperQuietly(themeId);
    this.syncFontQuietly(fontId);
  }

  private syncPaperQuietly(themeId: StylePresetId): void {
    try {
      AppStorage.setOrCreate('currentPaperId', paperIdForStyle(themeId));
      ThemeChrome.apply(AppServiceContainer.getAbilityContext(), paperIdForStyle(themeId));
    } catch (error) {
      AppLogger.warn(`${SKILL_TAG} paper_visual_sync_failed`);
    }
  }

  private syncFontQuietly(fontId: FontPresetId): void {
    try {
      AppStorage.setOrCreate('currentFontId', fontId);
    } catch (error) {
      AppLogger.warn(`${SKILL_TAG} font_visual_sync_failed`);
    }
  }

  private notifyRecordChanged(): void {
    try {
      AppStorage.setOrCreate<number>('diarySkillRecordRevision',
        (AppStorage.get<number>('diarySkillRecordRevision') ?? 0) + 1);
    } catch (error) {
      AppLogger.warn(`${SKILL_TAG} record_refresh_failed`);
    }
  }

  private notifyStyleChanged(): void {
    try {
      AppStorage.setOrCreate<number>('diarySkillStyleRevision',
        (AppStorage.get<number>('diarySkillStyleRevision') ?? 0) + 1);
    } catch (error) {
      AppLogger.warn(`${SKILL_TAG} style_refresh_failed`);
    }
  }

  private async syncWidgetQuietly(record: DailyRecord): Promise<void> {
    try {
      await syncWidgetFromRecord(AppServiceContainer.getAbilityContext(), record);
    } catch (error) {
      // 卡片同步失败不阻断日记记录结果上报
      AppLogger.warn(`${SKILL_TAG} widget_sync_failed`);
    }
  }

  private async reportDiaryError(info: scriptManager.ArkTSScriptInfo, error: Object): Promise<void> {
    if (error instanceof DiaryError) {
      switch (error.code) {
        case DiaryErrorCode.ALREADY_RECORDED:
          await this.reportFailure(
            info,
            'ERR_ALREADY_RECORDED',
            error.message,
            '今天已经留下记录了，打开一字日记可以查看或修订'
          );
          return;
        case DiaryErrorCode.CONTENT_REQUIRED:
          await this.reportFailure(
            info,
            'ERR_INVALID_PARAMS',
            error.message,
            '请告诉我想记下的一至四个字'
          );
          return;
        case DiaryErrorCode.CONTENT_TOO_LONG:
          await this.reportFailure(
            info,
            'ERR_INVALID_PARAMS',
            error.message,
            '日记最多四个字，可以再精炼一些吗'
          );
          return;
        case DiaryErrorCode.CONTENT_HAS_LINE_BREAK:
        case DiaryErrorCode.NOTE_HAS_LINE_BREAK:
          await this.reportFailure(
            info,
            'ERR_INVALID_PARAMS',
            error.message,
            '日记和备注只能是单行文字'
          );
          return;
        case DiaryErrorCode.NOTE_TOO_LONG:
          await this.reportFailure(
            info,
            'ERR_INVALID_PARAMS',
            error.message,
            '备注最多三十个字'
          );
          return;
        case DiaryErrorCode.STYLE_REQUIRED:
        default:
          break;
      }
    }
    const err = error as BusinessError;
    AppLogger.error(`${SKILL_TAG} record_failed code=${err.code} message=${err.message}`);
    await this.reportFailure(
      info,
      'ERR_INTERNAL',
      `record failed: ${err.message}`,
      '记录日记失败了，请稍后再试'
    );
  }

  private async reportFailure(
    info: scriptManager.ArkTSScriptInfo,
    errCode: string,
    errMsg: string,
    suggestion: string
  ): Promise<void> {
    const payload: Record<string, Object> = {
      'type': 'result',
      'status': 'failed',
      'errCode': errCode,
      'errMsg': errMsg,
      'suggestion': suggestion
    };
    await this.report(info, { code: -1, result: payload });
  }

  private async report(info: scriptManager.ArkTSScriptInfo, result: scriptManager.ExecuteResult): Promise<void> {
    try {
      await scriptManager.completeArkTSScriptInApp(info.context, info.requestCode, result);
    } catch (e) {
      const err = e as BusinessError;
      AppLogger.error(`${SKILL_TAG} report_failed code=${err.code} message=${err.message}`);
    }
  }
}
