import { formBindingData, formProvider } from '@kit.FormKit';
import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DailyRecord } from '../model/DailyRecord';
import { styleForPaper } from '../constants/StyleTokens';
import { fontFamilyForId } from '../constants/FontCatalog';

const TAG: string = 'WidgetSync';
const PREFS_NAME: string = 'word_card_storage';
const KEY_WIDGET_PAYLOAD: string = 'widget_payload';
const KEY_WIDGET_FORM_IDS: string = 'widget_form_ids';

export interface WidgetCardPayload {
  content: string;
  date: string;
  paperColor: string;
  inkColor: string;
  accentColor: string;
  fontFamily: string;
}

export function defaultWidgetPayload(): WidgetCardPayload {
  return {
    content: '',
    date: '',
    paperColor: '#FDF8F7',
    inkColor: '#282622',
    accentColor: '#A65C4D',
    fontFamily: 'oneword_wenkai, serif'
  };
}

async function getStore(context: common.Context): Promise<preferences.Preferences> {
  return preferences.getPreferences(context, { name: PREFS_NAME });
}

export async function readWidgetPayload(context: common.Context): Promise<WidgetCardPayload> {
  try {
    const store = await getStore(context);
    const raw: string = (await store.get(KEY_WIDGET_PAYLOAD, '')) as string;
    if (raw.length === 0) {
      return defaultWidgetPayload();
    }
    return JSON.parse(raw) as WidgetCardPayload;
  } catch (error) {
    hilog.warn(0, TAG, `readWidgetPayload failed: ${(error as Error).message}`);
    return defaultWidgetPayload();
  }
}

export async function saveWidgetPayload(context: common.Context, payload: WidgetCardPayload): Promise<void> {
  const store = await getStore(context);
  await store.put(KEY_WIDGET_PAYLOAD, JSON.stringify(payload));
  await store.flush();
}

export async function readWidgetFormIds(context: common.Context): Promise<string[]> {
  try {
    const store = await getStore(context);
    const raw: string = (await store.get(KEY_WIDGET_FORM_IDS, '')) as string;
    if (raw.length === 0) {
      return [];
    }
    return raw.split(',');
  } catch (error) {
    hilog.warn(0, TAG, `readWidgetFormIds failed: ${(error as Error).message}`);
    return [];
  }
}

export async function addWidgetFormId(context: common.Context, formId: string): Promise<void> {
  const ids = await readWidgetFormIds(context);
  if (ids.includes(formId)) {
    return;
  }
  ids.push(formId);
  const store = await getStore(context);
  await store.put(KEY_WIDGET_FORM_IDS, ids.join(','));
  await store.flush();
}

export async function removeWidgetFormId(context: common.Context, formId: string): Promise<void> {
  const ids = await readWidgetFormIds(context);
  const next = ids.filter((id: string) => id !== formId);
  const store = await getStore(context);
  await store.put(KEY_WIDGET_FORM_IDS, next.join(','));
  await store.flush();
}

export function widgetBindingData(payload: WidgetCardPayload): formBindingData.FormBindingData {
  return formBindingData.createFormBindingData({
    content: payload.content,
    date: payload.date,
    paperColor: payload.paperColor,
    inkColor: payload.inkColor,
    accentColor: payload.accentColor,
    fontFamily: payload.fontFamily
  });
}

export async function pushWidgetToForm(context: common.Context, formId: string): Promise<void> {
  const payload = await readWidgetPayload(context);
  try {
    await formProvider.updateForm(formId, widgetBindingData(payload));
  } catch (error) {
    hilog.warn(0, TAG, `pushWidgetToForm failed: ${(error as Error).message}`);
  }
}

export async function pushWidgetToAll(context: common.Context, payload: WidgetCardPayload): Promise<void> {
  const ids = await readWidgetFormIds(context);
  for (const id of ids) {
    await pushWidgetToForm(context, id);
  }
}

/**
 * 以记录快照刷新桌面卡片：内容/日期来自记录，墨色/印泥/字体来自记录的主题快照。
 * record 为 null（当日未写或已清空）时回退默认占位。
 */
export async function syncWidgetFromRecord(context: common.Context, record: DailyRecord | null): Promise<void> {
  if (record === null) {
    await pushWidgetToAll(context, defaultWidgetPayload());
    return;
  }
  const payload: WidgetCardPayload = {
    content: record.content === null ? '' : record.content,
    date: record.localDate.split('-').join('.'),
    paperColor: styleForPaper(record.paperId).light.background,
    inkColor: styleForPaper(record.paperId).light.textPrimary,
    accentColor: styleForPaper(record.paperId).light.accent,
    fontFamily: fontFamilyForId(record.fontId)
  };
  await saveWidgetPayload(context, payload);
  await pushWidgetToAll(context, payload);
}
