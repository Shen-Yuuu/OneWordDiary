export enum FontPresetId {
  DEFAULT = 'oneword_kai',
  SMILEY_SANS = 'smiley_sans_oblique',
  DYMON_HANDWRITING = 'dymon_handwriting',
  SLIDE_YOURAN = 'slide_youran',
  MINGCHAO = 'mingchao',
  YUNFENG_FEIYUN = 'yunfeng_feiyun'
}

export interface FontOption {
  id: FontPresetId;
  displayName: string;
  sample: string;
  fontFamily: string;
}

const DEFAULT_FAMILY: string = 'oneword_wenkai, serif';
const SMILEY_SANS_FAMILY: string = 'oneword_smiley_sans, oneword_wenkai, serif';
const DYMON_HANDWRITING_FAMILY: string = 'oneword_dymon_handwriting, oneword_wenkai, serif';
const SLIDE_YOURAN_FAMILY: string = 'oneword_slide_youran, oneword_wenkai, serif';
const MINGCHAO_FAMILY: string = 'oneword_mingchao, oneword_wenkai, serif';
const YUNFENG_FEIYUN_FAMILY: string = 'oneword_yunfeng_feiyun, oneword_wenkai, serif';

export function allFontOptions(): FontOption[] {
  return [
    { id: FontPresetId.DEFAULT, displayName: '默认字体', sample: '一字', fontFamily: DEFAULT_FAMILY },
    { id: FontPresetId.SMILEY_SANS, displayName: '得意黑楷体', sample: '一字', fontFamily: SMILEY_SANS_FAMILY },
    { id: FontPresetId.DYMON_HANDWRITING, displayName: '呆萌手写体', sample: '一字', fontFamily: DYMON_HANDWRITING_FAMILY },
    { id: FontPresetId.SLIDE_YOURAN, displayName: '悠然小楷体', sample: '一字', fontFamily: SLIDE_YOURAN_FAMILY },
    { id: FontPresetId.MINGCHAO, displayName: '汇文明朝体', sample: '一字', fontFamily: MINGCHAO_FAMILY },
    { id: FontPresetId.YUNFENG_FEIYUN, displayName: '云峰飞云体', sample: '一字', fontFamily: YUNFENG_FEIYUN_FAMILY }
  ];
}

export function fontFamilyForId(fontId: string): string {
  switch (fontId) {
    case FontPresetId.SMILEY_SANS:
      return SMILEY_SANS_FAMILY;
    case FontPresetId.DYMON_HANDWRITING:
      return DYMON_HANDWRITING_FAMILY;
    case FontPresetId.SLIDE_YOURAN:
      return SLIDE_YOURAN_FAMILY;
    case FontPresetId.MINGCHAO:
      return MINGCHAO_FAMILY;
    case FontPresetId.YUNFENG_FEIYUN:
      return YUNFENG_FEIYUN_FAMILY;
    case FontPresetId.DEFAULT:
    case 'system_serif_dev':
    case 'system_sans_dev':
    default:
      return DEFAULT_FAMILY;
  }
}

export function isSupportedFontId(value: string): boolean {
  switch (value) {
    case FontPresetId.DEFAULT:
    case FontPresetId.SMILEY_SANS:
    case FontPresetId.DYMON_HANDWRITING:
    case FontPresetId.SLIDE_YOURAN:
    case FontPresetId.MINGCHAO:
    case FontPresetId.YUNFENG_FEIYUN:
    case 'system_serif_dev':
    case 'system_sans_dev':
      return true;
    default:
      return false;
  }
}

export function isSelectableFontPreset(value: string): boolean {
  switch (value) {
    case FontPresetId.DEFAULT:
    case FontPresetId.SMILEY_SANS:
    case FontPresetId.DYMON_HANDWRITING:
    case FontPresetId.SLIDE_YOURAN:
    case FontPresetId.MINGCHAO:
    case FontPresetId.YUNFENG_FEIYUN:
      return true;
    default:
      return false;
  }
}

export function fontPresetIdFromValue(value: string): FontPresetId {
  switch (value) {
    case FontPresetId.SMILEY_SANS:
      return FontPresetId.SMILEY_SANS;
    case FontPresetId.DYMON_HANDWRITING:
      return FontPresetId.DYMON_HANDWRITING;
    case FontPresetId.SLIDE_YOURAN:
      return FontPresetId.SLIDE_YOURAN;
    case FontPresetId.MINGCHAO:
      return FontPresetId.MINGCHAO;
    case FontPresetId.YUNFENG_FEIYUN:
      return FontPresetId.YUNFENG_FEIYUN;
    case FontPresetId.DEFAULT:
    default:
      return FontPresetId.DEFAULT;
  }
}
