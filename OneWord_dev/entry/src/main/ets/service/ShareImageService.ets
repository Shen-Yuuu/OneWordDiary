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

    let file: fileIo.File | null = null;
    let pixelMap: image.PixelMap | null = null;
    const packer = image.createImagePacker();
    try {
      const filePath = `${context.cacheDir}/${fileName}`;
      this.currentFilePath = filePath;

      pixelMap = await uiContext.getComponentSnapshot().get(componentId, {
        scale: 3,
        waitUntilRenderFinished: true
      });

      file = fileIo.openSync(
        filePath,
        fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.TRUNC
      );

      await packer.packToFile(pixelMap, file.fd, {
        format: 'image/png',
        quality: 100
      });

      const imageUtd = utd.getUniformDataTypeByFilenameExtension('.png', utd.UniformDataType.IMAGE);
      const sharedData = new systemShare.SharedData({
        utd: imageUtd,
        uri: fileUri.getUriFromPath(filePath),
        title: '一字日记',
        description: '一天一字，一年成诗。'
      });
      const controller = new systemShare.ShareController(sharedData);
      await controller.show(context, {
        selectionMode: systemShare.SelectionMode.SINGLE,
        previewMode: systemShare.SharePreviewMode.DETAIL
      });
    } catch (error) {
      // 异常向上传递给分享预览页统一提示；此处仅保证资源释放
      throw error instanceof Error ? error : new Error(`分享图生成失败：${String(error)}`);
    } finally {
      if (file !== null) {
        try {
          fileIo.closeSync(file);
        } catch (error) {
          // 关闭失败忽略：临时文件随缓存目录清理
        }
      }
      await packer.release();
      if (pixelMap !== null) {
        await pixelMap.release();
      }
    }
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
