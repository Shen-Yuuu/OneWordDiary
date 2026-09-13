import { UIContext } from '@kit.ArkUI';
import { formBindingData, formProvider } from '@kit.FormKit';
import { common } from '@kit.AbilityKit';
import { fileIo } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';
import { preferences } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DailyRecord } from '../model/DailyRecord';
import { styleForPaper } from '../constants/StyleTokens';
import { fontFamilyForId } from '../constants/FontCatalog';

const TAG: string = 'WidgetSync';
const WIDGET_IMAGE_FILE: string = 'widget_card.png';
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
  const imagePath: string = context.filesDir + '/' + WIDGET_IMAGE_FILE;
  let hasImage: boolean = false;
  try {
    hasImage = fileIo.accessSync(imagePath);
  } catch (error) {
    hasImage = false;
  }
  if (hasImage) {
    try {
      await pushWidgetImageFile(context, imagePath, [formId]);
      return;
    } catch (error) {
      hilog.warn(0, TAG, `push widget image failed, fallback to text: ${(error as Error).message}`);
    }
  }
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
 * 把卡片快照同步到 AppStorage：隐藏的 WidgetSnapshotCard 监听这些键，
 * 防抖后用真字体把同款卡片渲染成位图推送给桌面。
 */
function publishWidgetSnapshot(payload: WidgetCardPayload): void {
  AppStorage.setOrCreate<string>('widgetCardContent', payload.content);
  AppStorage.setOrCreate<string>('widgetCardDate', payload.date);
  AppStorage.setOrCreate<string>('widgetCardPaperColor', payload.paperColor);
  AppStorage.setOrCreate<string>('widgetCardInkColor', payload.inkColor);
  AppStorage.setOrCreate<string>('widgetCardAccentColor', payload.accentColor);
  AppStorage.setOrCreate<string>('widgetCardFontFamily', payload.fontFamily);
  AppStorage.setOrCreate<number>('widgetCardRev', (AppStorage.get<number>('widgetCardRev') ?? 0) + 1);
}

/**
 * 以记录快照刷新桌面卡片：内容/日期来自记录，墨色/印泥/字体来自记录的主题快照。
 * record 为 null（当日未写或已清空）时回退默认占位。
 */
export async function syncWidgetFromRecord(context: common.Context, record: DailyRecord | null): Promise<void> {
  if (record === null) {
    const fallback: WidgetCardPayload = defaultWidgetPayload();
    publishWidgetSnapshot(fallback);
    await pushWidgetToAll(context, fallback);
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
  publishWidgetSnapshot(payload);
  await saveWidgetPayload(context, payload);
  await pushWidgetToAll(context, payload);
}

/**
 * 将隐藏的卡片快照组件渲染为位图，写入文件后以 formImages（fd）推送到所有已添加的卡片。
 * 位图文件持久化在 filesDir，卡片添加时也能直接展示上一次的位图。
 */
export async function snapshotAndPushWidget(context: common.UIAbilityContext,
  uiContext: UIContext, componentId: string): Promise<void> {
  const pixelMap: image.PixelMap = await uiContext.getComponentSnapshot().get(componentId, {
    scale: 2,
    waitUntilRenderFinished: true
  });

  const filePath = context.filesDir + '/' + WIDGET_IMAGE_FILE;
  const file: fileIo.File = fileIo.openSync(
    filePath,
    fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.TRUNC
  );
  const packer: image.ImagePacker = image.createImagePacker();
  try {
    const imagePackerOpts: image.PackingOption = { format: 'image/png', quality: 100 };
    await packer.packToFile(pixelMap, file.fd, imagePackerOpts);
    const info: image.ImageInfo = await pixelMap.getImageInfo();
    hilog.info(0, TAG, `widget snapshot packed: ${filePath} ${info.size.width}x${info.size.height}`);
  } finally {
    await packer.release();
    fileIo.closeSync(file);
  }

  await pushWidgetImageFileToAll(context, filePath);
}

async function pushWidgetImageFileToAll(context: common.Context, filePath: string): Promise<void> {
  const ids: string[] = await readWidgetFormIds(context);
  if (ids.length === 0) {
    return;
  }
  await pushWidgetImageFile(context, filePath, ids);
}

async function pushWidgetImageFile(context: common.Context, filePath: string, formIds: string[]): Promise<void> {
  const file: fileIo.File = fileIo.openSync(filePath, fileIo.OpenMode.READ_ONLY);
  try {
    // 官方约束：卡片 Image 以入参是否变化决定刷新，imgName 每次推送必须不同
    const imgKey: string = 'img' + Date.now().toString();
    const formImages: Record<string, number> = {};
    formImages[imgKey] = file.fd;
    for (const formId of formIds) {
      const binding: formBindingData.FormBindingData = formBindingData.createFormBindingData({
        'imgSrc': imgKey,
        'formImages': formImages
      });
      await formProvider.updateForm(formId, binding);
    }
  } finally {
    fileIo.closeSync(file);
  }
}
