import { common } from '@kit.AbilityKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { fileIo, fileUri } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';
import { systemShare } from '@kit.ShareKit';

export const SHARE_CARD_COMPONENT_ID: string = 'oneword_share_card';

export class ShareImageService {
  private currentFilePath: string = '';

  async shareCard(
    uiContext: UIContext,
    context: common.UIAbilityContext,
    componentId: string,
    fileName: string
  ): Promise<void> {
    this.cleanup();
    const pixelMap = await uiContext.getComponentSnapshot().get(componentId, {
      scale: 3,
      waitUntilRenderFinished: true
    });
    const thumbnailPixelMap = await uiContext.getComponentSnapshot().get(componentId, {
      scale: 0.5,
      waitUntilRenderFinished: true
    });
    const filePath = `${context.cacheDir}/${fileName}`;
    this.currentFilePath = filePath;
    const file = fileIo.openSync(
      filePath,
      fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.TRUNC
    );
    const packer = image.createImagePacker();
    const thumbnailPacker = image.createImagePacker();
    let thumbnail: Uint8Array = new Uint8Array();
    try {
      await packer.packToFile(pixelMap, file.fd, {
        format: 'image/png',
        quality: 100
      });
      const thumbnailBuffer = await thumbnailPacker.packToData(thumbnailPixelMap, {
        format: 'image/jpeg',
        quality: 45
      });
      thumbnail = new Uint8Array(thumbnailBuffer);
    } finally {
      fileIo.closeSync(file);
      await packer.release();
      await thumbnailPacker.release();
      await pixelMap.release();
      await thumbnailPixelMap.release();
    }
    const imageUtd = utd.getUniformDataTypeByFilenameExtension('.png', utd.UniformDataType.IMAGE);
    const sharedData = new systemShare.SharedData({
      utd: imageUtd,
      uri: fileUri.getUriFromPath(filePath),
      title: '一字日记',
      description: '一天一字，一年成诗。',
      thumbnail: thumbnail
    });
    const controller = new systemShare.ShareController(sharedData);
    await controller.show(context, {
      selectionMode: systemShare.SelectionMode.SINGLE,
      previewMode: systemShare.SharePreviewMode.DETAIL
    });
  }

  cleanup(): void {
    if (this.currentFilePath.length === 0) {
      return;
    }
    try {
      if (fileIo.accessSync(this.currentFilePath)) {
        fileIo.unlinkSync(this.currentFilePath);
      }
    } catch (error) {
    }
    this.currentFilePath = '';
  }
}
