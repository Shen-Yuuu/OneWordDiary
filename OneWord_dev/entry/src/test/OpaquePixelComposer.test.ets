import { describe, expect, it } from '@ohos/hypium';
import {
  OpaquePixelComposer,
  PixelByteOrder,
  RgbColor
} from '../main/ets/utils/OpaquePixelComposer';

function outputBytes(source: number[], order: PixelByteOrder, premultiplied: boolean, background: RgbColor,
  width: number = 1, height: number = 1, stride: number = 4): Uint8Array {
  const input = new Uint8Array(source);
  return new Uint8Array(OpaquePixelComposer.flatten(
    input,
    width,
    height,
    stride,
    order,
    premultiplied,
    background
  ));
}

export default function opaquePixelComposerTest(): void {
  describe('OpaquePixelComposer', () => {
    it('fillsTransparentPixelWithBackgroundAndOpaqueAlpha', 0, () => {
      const output = outputBytes(
        [200, 100, 50, 0],
        PixelByteOrder.RGBA,
        false,
        new RgbColor(253, 248, 247)
      );
      expect(Array.from(output).join(',')).assertEqual('253,248,247,255');
    });

    it('preservesOpaquePixelAndConvertsBgraToRgba', 0, () => {
      const output = outputBytes(
        [30, 20, 10, 255],
        PixelByteOrder.BGRA,
        false,
        new RgbColor(253, 248, 247)
      );
      expect(Array.from(output).join(',')).assertEqual('10,20,30,255');
    });

    it('blendsPremultipliedPixelAndSkipsRowPadding', 0, () => {
      const output = outputBytes(
        [64, 0, 0, 128, 99, 99, 99, 99],
        PixelByteOrder.RGBA,
        true,
        new RgbColor(200, 100, 50),
        1,
        1,
        8
      );
      expect(Array.from(output).join(',')).assertEqual('164,50,25,255');
    });
  });
}
