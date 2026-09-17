import { common } from '@kit.AbilityKit';
import { media } from '@kit.MediaKit';
import { audio } from '@kit.AudioKit';
import { AppLogger } from '../utils/AppLogger';

/**
 * 落字时刻的轻音效（SoundPool 低时延短音频）。
 * 加载或播放失败时静默降级（静音设备/资源缺失），不影响落字流程。
 */
export class InkDropSound {
  private static readonly RAWFILE_PATH: string = 'sounds/ink_drop.wav';
  private static readonly PLAY_VOLUME: number = 0.55;
  private static instance: InkDropSound | null = null;

  private soundPool: media.SoundPool | null = null;
  private soundId: number = -1;
  private loadStarted: boolean = false;

  static preload(context: common.Context): void {
    InkDropSound.get().load(context);
  }

  static play(): void {
    InkDropSound.get().playInternal();
  }

  private static get(): InkDropSound {
    if (InkDropSound.instance === null) {
      InkDropSound.instance = new InkDropSound();
    }
    return InkDropSound.instance;
  }

  private async load(context: common.Context): Promise<void> {
    if (this.soundPool !== null || this.loadStarted) {
      return;
    }
    this.loadStarted = true;
    try {
      const rendererInfo: audio.AudioRendererInfo = {
        usage: audio.StreamUsage.STREAM_USAGE_MUSIC,
        rendererFlags: 1
      };
      const pool: media.SoundPool = await media.createSoundPool(1, rendererInfo);
      const descriptor = context.resourceManager.getRawFdSync(InkDropSound.RAWFILE_PATH);
      this.soundId = await pool.load(descriptor.fd, descriptor.offset, descriptor.length);
      this.soundPool = pool;
      AppLogger.info('sound.ink_drop_loaded id=' + this.soundId);
    } catch (error) {
      this.loadStarted = false;
      AppLogger.warn('sound.ink_drop_load_failed');
    }
  }

  private playInternal(): void {
    const pool = this.soundPool;
    if (pool === null || this.soundId < 0) {
      return;
    }
    const params: media.PlayParameters = {
      loop: 0,
      rate: 1,
      leftVolume: InkDropSound.PLAY_VOLUME,
      rightVolume: InkDropSound.PLAY_VOLUME,
      priority: 0
    };
    pool.play(this.soundId, params, () => {
    });
  }
}
