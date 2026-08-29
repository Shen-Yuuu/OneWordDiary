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
    console.info(`ShareImageService shareCard: start, componentId=${componentId}, fileName=${fileName}`);

    this.cleanup();

    console.info(`ShareImageService shareCard: getting component snapshot for id=${componentId}`);
    const pixelMap = await uiContext.getComponentSnapshot().get(componentId, {
      scale: 3,
      waitUntilRenderFinished: true
    });

    console.info('ShareImageService shareCard: component snapshot obtained successfully');

    const filePath = `${context.cacheDir}/${fileName}`;
    this.currentFilePath = filePath;
    console.info(`ShareImageService shareCard: opening file at ${filePath}`);

    const file = fileIo.openSync(
      filePath,
      fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.TRUNC
    );

    const packer = image.createImagePacker();
    try {
      console.info('ShareImageService shareCard: packing image to file');
      await packer.packToFile(pixelMap, file.fd, {
        format: 'image/png',
        quality: 100
      });
      console.info('ShareImageService shareCard: image packed successfully');
    } finally {
      fileIo.closeSync(file);
      await packer.release();
      await pixelMap.release();
      console.info('ShareImageService shareCard: resources released');
    }
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
