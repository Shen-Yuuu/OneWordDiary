export class RgbColor {
  readonly red: number;
  readonly green: number;
  readonly blue: number;

  constructor(red: number, green: number, blue: number) {
    this.red = red;
    this.green = green;
    this.blue = blue;
  }
}

export enum PixelByteOrder {
  RGBA = 'RGBA',
  BGRA = 'BGRA'
}

export class OpaquePixelComposer {
  static flatten(
    source: Uint8Array,
    width: number,
    height: number,
    stride: number,
    order: PixelByteOrder,
    premultiplied: boolean,
    background: RgbColor
  ): ArrayBuffer {
    if (width <= 0 || height <= 0 || stride < width * 4 || source.length < stride * height) {
      throw new Error('Invalid pixel buffer dimensions');
    }

    const outputBuffer = new ArrayBuffer(width * height * 4);
    const output = new Uint8Array(outputBuffer);
    for (let y = 0; y < height; y += 1) {
      for (let x = 0; x < width; x += 1) {
        const sourceOffset = y * stride + x * 4;
        const outputOffset = (y * width + x) * 4;
        const sourceRed = order === PixelByteOrder.RGBA ?
          source[sourceOffset] : source[sourceOffset + 2];
        const sourceGreen = source[sourceOffset + 1];
        const sourceBlue = order === PixelByteOrder.RGBA ?
          source[sourceOffset + 2] : source[sourceOffset];
        const alpha = source[sourceOffset + 3];

        output[outputOffset] = OpaquePixelComposer.blend(
          sourceRed,
          alpha,
          background.red,
          premultiplied
        );
        output[outputOffset + 1] = OpaquePixelComposer.blend(
          sourceGreen,
          alpha,
          background.green,
          premultiplied
        );
        output[outputOffset + 2] = OpaquePixelComposer.blend(
          sourceBlue,
          alpha,
          background.blue,
          premultiplied
        );
        output[outputOffset + 3] = 255;
      }
    }
    return outputBuffer;
  }

  private static blend(source: number, alpha: number, background: number, premultiplied: boolean): number {
    const transparentWeight = 255 - alpha;
    if (premultiplied) {
      return Math.min(255, Math.round(source + background * transparentWeight / 255));
    }
    return Math.round((source * alpha + background * transparentWeight) / 255);
  }
}
