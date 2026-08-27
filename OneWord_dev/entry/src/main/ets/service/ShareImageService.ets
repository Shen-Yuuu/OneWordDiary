import { common } from '@kit.AbilityKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { fileIo, fileUri } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';
import { systemShare } from '@kit.ShareKit';
import { OpaquePixelComposer, PixelByteOrder, RgbColor } from '../utils/OpaquePixelComposer';

export const SHARE_CARD_COMPONENT_ID: string = 'oneword_share_card';

export class ShareImageService {
  private currentFilePath: string = '';

  async shareCard(
    uiContext: UIContext,
    context: common.UIAbilityContext,
    componentId: string,
    fileName: string,
    background: RgbColor
  ): Promise<void> {
    this.cleanup();
    const snapshotPixelMap = await uiContext.getComponentSnapshot().get(componentId, {
      scale: 3,
      waitUntilRenderFinished: true
    });
    const filePath = `${context.cacheDir}/${fileName}`;
    this.currentFilePath = filePath;
    try {
      const opaquePixelMap = await this.createOpaquePixelMap(snapshotPixelMap, background);
      try {
        const file = fileIo.openSync(
          filePath,
          fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.TRUNC
        );
        try {
          const packer = image.createImagePacker();
          try {
            await packer.packToFile(opaquePixelMap, file.fd, {
              format: 'image/png',
              quality: 100
            });
          } finally {
            await packer.release();
          }
        } finally {
          fileIo.closeSync(file);
        }
      } finally {
        await opaquePixelMap.release();
      }
    } finally {
      await snapshotPixelMap.release();
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

  private async createOpaquePixelMap(source: image.PixelMap, background: RgbColor): Promise<image.PixelMap> {
    const imageInfo = await source.getImageInfo();
    let byteOrder: PixelByteOrder;
    if (imageInfo.pixelFormat === image.PixelMapFormat.RGBA_8888) {
      byteOrder = PixelByteOrder.RGBA;
    } else if (imageInfo.pixelFormat === image.PixelMapFormat.BGRA_8888) {
      byteOrder = PixelByteOrder.BGRA;
    } else {
      throw new Error('Unsupported snapshot pixel format');
    }

    const sourceStride = imageInfo.stride > 0 ? imageInfo.stride : imageInfo.size.width * 4;
    const sourceBuffer = new ArrayBuffer(sourceStride * imageInfo.size.height);
    await source.readPixelsToBuffer(sourceBuffer);
    const opaqueBuffer = OpaquePixelComposer.flatten(
      new Uint8Array(sourceBuffer),
      imageInfo.size.width,
      imageInfo.size.height,
      sourceStride,
      byteOrder,
      imageInfo.alphaType === image.AlphaType.PREMUL,
      background
    );
    return image.createPixelMap(opaqueBuffer, {
      size: imageInfo.size,
      srcPixelFormat: image.PixelMapFormat.RGBA_8888,
      pixelFormat: image.PixelMapFormat.RGBA_8888,
      alphaType: image.AlphaType.OPAQUE,
      editable: false
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
