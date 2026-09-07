import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { fileIo, fileUri } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';
import {
  BackgroundImageBackupData,
  BackgroundImageBackupStore,
  BackgroundImageError,
  BackgroundImageErrorCode,
  isValidBackgroundImageId
} from '../model/BackgroundImage';

export class BackgroundImageService implements BackgroundImageBackupStore {
  static readonly DIRECTORY_NAME: string = 'diary-backgrounds';
  static readonly MAX_SOURCE_BYTES: number = 20 * 1024 * 1024;
  static readonly MAX_OUTPUT_BYTES: number = 5 * 1024 * 1024;
  static readonly MAX_PIXEL_COUNT: number = 80 * 1024 * 1024;
  static readonly MAX_LONG_EDGE: number = 2048;

  private readonly directoryPath: string;
  private generation: number = 0;

  constructor(context: common.UIAbilityContext) {
    this.directoryPath = `${context.filesDir}/${BackgroundImageService.DIRECTORY_NAME}`;
  }

  async importFromUri(uri: string): Promise<string> {
    const importGeneration = this.generation;
    if (uri.length === 0) {
      throw new BackgroundImageError(BackgroundImageErrorCode.INVALID_IMAGE, '没有选择图片');
    }
    let sourceFile: fileIo.File | null = null;
    let source: image.ImageSource | null = null;
    let pixelMap: image.PixelMap | null = null;
    let packer: image.ImagePacker | null = null;
    let outputId: string = '';
    try {
      const sourceStat = fileIo.statSync(uri);
      if (sourceStat.size <= 0) {
        throw this.invalidImage();
      }
      if (sourceStat.size > BackgroundImageService.MAX_SOURCE_BYTES) {
        throw new BackgroundImageError(BackgroundImageErrorCode.SOURCE_TOO_LARGE, '图片文件不能超过 20 MiB');
      }
      sourceFile = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
      source = image.createImageSource(sourceFile.fd);
      const frameCount = await source.getFrameCount();
      if (frameCount !== 1) {
        throw new BackgroundImageError(BackgroundImageErrorCode.ANIMATED_IMAGE,
          '暂不支持动态图片，请选择静态图片');
      }
      const info = await source.getImageInfo(0);
      this.validateDimensions(info.size.width, info.size.height);
      const desiredSize = this.scaledSize(info.size.width, info.size.height);
      const orientation = await this.readOrientation(source);
      pixelMap = await source.createPixelMap({
        index: 0,
        desiredSize: desiredSize,
        desiredPixelFormat: image.PixelMapFormat.RGBA_8888,
        editable: true
      });
      await this.applyOrientation(pixelMap, orientation);
      const preserveAlpha = info.alphaType !== image.AlphaType.OPAQUE;
      const mimeType = preserveAlpha ? 'image/png' : 'image/jpeg';
      const extension = preserveAlpha ? 'png' : 'jpg';
      packer = image.createImagePacker();
      const normalized = await packer.packToData(pixelMap, {
        format: mimeType,
        quality: preserveAlpha ? 100 : 88
      });
      if (normalized.byteLength <= 0 || normalized.byteLength > BackgroundImageService.MAX_OUTPUT_BYTES) {
        throw new BackgroundImageError(BackgroundImageErrorCode.OUTPUT_TOO_LARGE,
          '处理后的图片不能超过 5 MiB，请选择更小的图片');
      }
      outputId = this.newId(extension);
      this.assertCurrentGeneration(importGeneration);
      this.writeOwnedFile(outputId, normalized);
      return outputId;
    } catch (error) {
      if (outputId.length > 0) {
        this.remove(outputId);
      }
      if (error instanceof BackgroundImageError) {
        throw error;
      }
      throw this.invalidImage();
    } finally {
      if (packer !== null) {
        try {
          packer.release();
        } catch (error) {
        }
      }
      if (pixelMap !== null) {
        try {
          await pixelMap.release();
        } catch (error) {
        }
      }
      if (source !== null) {
        try {
          await source.release();
        } catch (error) {
        }
      }
      if (sourceFile !== null) {
        try {
          fileIo.closeSync(sourceFile);
        } catch (error) {
        }
      }
    }
  }

  resolveUri(id: string | null | undefined): string {
    if (!isValidBackgroundImageId(id)) {
      return '';
    }
    const path = this.pathFor(id as string);
    try {
      return fileIo.accessSync(path) ? fileUri.getUriFromPath(path) : '';
    } catch (error) {
      return '';
    }
  }

  remove(id: string): void {
    if (!isValidBackgroundImageId(id)) {
      return;
    }
    const path = this.pathFor(id);
    try {
      if (fileIo.accessSync(path)) {
        fileIo.unlinkSync(path);
      }
    } catch (error) {
    }
  }

  clearAll(): void {
    this.generation++;
    if (!fileIo.accessSync(this.directoryPath)) {
      return;
    }
    fileIo.listFileSync(this.directoryPath).forEach((name: string) => {
      fileIo.unlinkSync(`${this.directoryPath}/${name}`);
    });
  }

  async readForBackup(id: string): Promise<BackgroundImageBackupData> {
    if (!isValidBackgroundImageId(id)) {
      throw new BackgroundImageError(BackgroundImageErrorCode.INVALID_IMAGE,
        '日记背景图片标识无效，无法完整备份');
    }
    try {
      const path = this.pathFor(id);
      const stat = fileIo.statSync(path);
      if (stat.size <= 0 || stat.size > BackgroundImageService.MAX_OUTPUT_BYTES) {
        throw this.missingBackupImage();
      }
      const bytes = this.readBytes(path, stat.size);
      const data: BackgroundImageBackupData = {
        mimeType: id.endsWith('.png') ? 'image/png' : 'image/jpeg',
        byteLength: bytes.byteLength,
        dataBase64: BackgroundImageService.encodeBase64(bytes)
      };
      await this.validateBackupBytes(bytes, data);
      return data;
    } catch (error) {
      if (error instanceof BackgroundImageError) {
        throw error;
      }
      throw this.missingBackupImage();
    }
  }

  async importFromBackup(data: BackgroundImageBackupData): Promise<string> {
    const importGeneration = this.generation;
    let outputId = '';
    try {
      this.validateEncodedLength(data);
      const bytes = new util.Base64Helper().decodeSync(data.dataBase64, util.Type.BASIC);
      await this.validateBackupBytes(bytes, data);
      outputId = this.newId(data.mimeType === 'image/png' ? 'png' : 'jpg');
      this.assertCurrentGeneration(importGeneration);
      this.writeOwnedFile(outputId, bytes.buffer as ArrayBuffer);
      return outputId;
    } catch (error) {
      if (outputId.length > 0) {
        this.remove(outputId);
      }
      if (error instanceof BackgroundImageError) {
        throw error;
      }
      throw this.invalidBackupImage();
    }
  }

  removeMany(ids: string[]): void {
    ids.forEach((id: string) => this.remove(id));
  }

  cleanupOrphans(referencedIds: Set<string>): void {
    if (!fileIo.accessSync(this.directoryPath)) {
      return;
    }
    fileIo.listFileSync(this.directoryPath).forEach((name: string) => {
      if (isValidBackgroundImageId(name) && !referencedIds.has(name)) {
        this.remove(name);
      }
    });
  }

  static encodeBase64(bytes: Uint8Array): string {
    return new util.Base64Helper().encodeToStringSync(bytes, util.Type.BASIC);
  }

  static decodeBase64(value: string): Uint8Array {
    return new util.Base64Helper().decodeSync(value, util.Type.BASIC);
  }
  private validateEncodedLength(data: BackgroundImageBackupData): void {
    if (data.mimeType !== 'image/jpeg' && data.mimeType !== 'image/png') {
      throw this.invalidBackupImage();
    }
    if (data.byteLength <= 0 || data.byteLength > BackgroundImageService.MAX_OUTPUT_BYTES ||
      data.dataBase64.length === 0 || data.dataBase64.length % 4 !== 0 ||
      data.dataBase64.length > Math.ceil(BackgroundImageService.MAX_OUTPUT_BYTES / 3) * 4 ||
      !/^[A-Za-z0-9+/]*={0,2}$/.test(data.dataBase64)) {
      throw this.invalidBackupImage();
    }
    const padding = data.dataBase64.endsWith('==') ? 2 : data.dataBase64.endsWith('=') ? 1 : 0;
    if (data.dataBase64.length / 4 * 3 - padding !== data.byteLength) {
      throw this.invalidBackupImage();
    }
  }

  private async validateBackupBytes(bytes: Uint8Array, data: BackgroundImageBackupData): Promise<void> {
    if (bytes.byteLength !== data.byteLength || !this.magicMatches(bytes, data.mimeType)) {
      throw this.invalidBackupImage();
    }
    let source: image.ImageSource | null = null;
    let decoded: image.PixelMap | null = null;
    try {
      source = image.createImageSource(bytes.buffer as ArrayBuffer);
      if (await source.getFrameCount() !== 1) {
        throw new BackgroundImageError(BackgroundImageErrorCode.ANIMATED_IMAGE,
          '备份包含暂不支持的动态背景图片');
      }
      const info = await source.getImageInfo(0);
      this.validateDimensions(info.size.width, info.size.height);
      if (Math.max(info.size.width, info.size.height) > BackgroundImageService.MAX_LONG_EDGE) {
        throw this.invalidBackupImage();
      }
      decoded = await source.createPixelMap({ index: 0, desiredSize: { width: 1, height: 1 } });
    } finally {
      if (decoded !== null) {
        try {
          await decoded.release();
        } catch (error) {
        }
      }
      if (source !== null) {
        try {
          await source.release();
        } catch (error) {
        }
      }
    }
  }

  private magicMatches(bytes: Uint8Array, mimeType: string): boolean {
    if (mimeType === 'image/jpeg') {
      return bytes.length >= 3 && bytes[0] === 255 && bytes[1] === 216 && bytes[2] === 255;
    }
    return bytes.length >= 8 && bytes[0] === 137 && bytes[1] === 80 && bytes[2] === 78 &&
      bytes[3] === 71 && bytes[4] === 13 && bytes[5] === 10 && bytes[6] === 26 && bytes[7] === 10;
  }
  private async readOrientation(source: image.ImageSource): Promise<string> {
    try {
      return await source.getImageProperty(image.PropertyKey.ORIENTATION, { index: 0, defaultValue: '1' });
    } catch (error) {
      return '1';
    }
  }

  private async applyOrientation(pixelMap: image.PixelMap, orientation: string): Promise<void> {
    const value = orientation.toLowerCase();
    if (value === '2' || value === 'top-right') await pixelMap.flip(true, false);
    if (value === '3' || value === 'bottom-right') await pixelMap.rotate(180);
    if (value === '4' || value === 'bottom-left') await pixelMap.flip(false, true);
    if (value === '5' || value === 'left-top') {
      await pixelMap.rotate(90);
      await pixelMap.flip(true, false);
    }
    if (value === '6' || value === 'right-top') await pixelMap.rotate(90);
    if (value === '7' || value === 'right-bottom') {
      await pixelMap.rotate(90);
      await pixelMap.flip(false, true);
    }
    if (value === '8' || value === 'left-bottom') await pixelMap.rotate(270);
  }

  private validateDimensions(width: number, height: number): void {
    if (!Number.isSafeInteger(width) || !Number.isSafeInteger(height) || width <= 0 || height <= 0 ||
      width > BackgroundImageService.MAX_PIXEL_COUNT || height > BackgroundImageService.MAX_PIXEL_COUNT ||
      width * height > BackgroundImageService.MAX_PIXEL_COUNT) {
      throw new BackgroundImageError(BackgroundImageErrorCode.DIMENSIONS_TOO_LARGE,
        '图片尺寸过大，请选择不超过 8000 万像素的图片');
    }
  }

  private scaledSize(width: number, height: number): image.Size {
    const longEdge = Math.max(width, height);
    if (longEdge <= BackgroundImageService.MAX_LONG_EDGE) return { width: width, height: height };
    const scale = BackgroundImageService.MAX_LONG_EDGE / longEdge;
    return {
      width: Math.max(1, Math.round(width * scale)),
      height: Math.max(1, Math.round(height * scale))
    };
  }

  private newId(extension: string): string {
    for (let attempt = 0; attempt < 5; attempt++) {
      const id = `${util.generateRandomUUID(true).replace(/-/g, '').toLowerCase()}.${extension}`;
      if (!fileIo.accessSync(this.pathFor(id))) return id;
    }
    throw new BackgroundImageError(BackgroundImageErrorCode.STORAGE_FAILED, '暂时无法保存图片，请重试');
  }

  private pathFor(id: string): string {
    return `${this.directoryPath}/${id}`;
  }

  private ensureDirectory(): void {
    if (!fileIo.accessSync(this.directoryPath)) fileIo.mkdirSync(this.directoryPath, true);
  }


  private writeOwnedFile(id: string, data: ArrayBuffer): void {
    this.ensureDirectory();
    const file = fileIo.openSync(this.pathFor(id),
      fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.TRUNC);
    try {
      if (fileIo.writeSync(file.fd, data) !== data.byteLength) {
        throw new BackgroundImageError(BackgroundImageErrorCode.STORAGE_FAILED,
          '暂时无法完整保存图片，请重试');
      }
    } finally {
      fileIo.closeSync(file);
    }
  }

  private assertCurrentGeneration(importGeneration: number): void {
    if (importGeneration !== this.generation) {
      throw new BackgroundImageError(BackgroundImageErrorCode.STORAGE_FAILED,
        '图片导入已因数据清理而取消');
    }
  }

  private readBytes(path: string, size: number): Uint8Array {
    const file = fileIo.openSync(path, fileIo.OpenMode.READ_ONLY);
    try {
      const data = new ArrayBuffer(size);
      if (fileIo.readSync(file.fd, data) !== size) {
        throw this.missingBackupImage();
      }
      return new Uint8Array(data);
    } finally {
      fileIo.closeSync(file);
    }
  }

  private invalidImage(): BackgroundImageError {
    return new BackgroundImageError(BackgroundImageErrorCode.INVALID_IMAGE,
      '无法读取这张图片，请选择有效的静态图片');
  }

  private invalidBackupImage(): BackgroundImageError {
    return new BackgroundImageError(BackgroundImageErrorCode.INVALID_IMAGE, '备份中的背景图片数据无效');
  }

  private missingBackupImage(): BackgroundImageError {
    return new BackgroundImageError(BackgroundImageErrorCode.INVALID_IMAGE,
      '日记背景图片缺失或已损坏，无法完整备份');
  }
}
