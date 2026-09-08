// 注册于 EntryAbility（@ohos.font.registerFont）；逗号链保证缺字时回退系统衬线。
// 用 class 静态成员而非 export const：后者跨模块活绑定在 struct 生成代码中真机复现为 undefined
export class FontFamilies {
  static readonly SERIF: string = 'oneword_wenkai, serif';
  static readonly SERIF_HEAVY: string = 'oneword_wenkai_medium, serif';
  private constructor() {
  }
}

export enum StylePresetId {
  PAPER_INK = 'paper_ink',
  PLAIN_ASH = 'plain_ash',
  PINE_MIST = 'pine_mist',
  MIST_BLUE = 'mist_blue',
  APRICOT_PAPER = 'apricot_paper'
}

export interface StylePalette {
  background: string;
  surface: string;
  textPrimary: string;
  textSecondary: string;
  accent: string;
  divider: string;
}

export interface StyleTokens {
  id: StylePresetId;
  fontId: string;
  paperId: string;
  fontFamily: string;
  light: StylePalette;
  dark: StylePalette;
}

export const PAPER_INK_STYLE: StyleTokens = {
  id: StylePresetId.PAPER_INK,
  fontId: 'system_serif_dev',
  paperId: 'warm_paper_dev',
  fontFamily: FontFamilies.SERIF,
  light: {
    background: '#FDF8F7',
    surface: '#FFFCFB',
    textPrimary: '#282622',
    textSecondary: '#797672',
    accent: '#A65C4D',
    divider: '#E8E1DE'
  },
  dark: {
    background: '#191715',
    surface: '#211F1C',
    textPrimary: '#F2ECE8',
    textSecondary: '#B8B0AB',
    accent: '#C87867',
    divider: '#3A3632'
  }
};

export const PLAIN_ASH_STYLE: StyleTokens = {
  id: StylePresetId.PLAIN_ASH,
  fontId: 'system_sans_dev',
  paperId: 'plain_ash_dev',
  fontFamily: FontFamilies.SERIF,
  light: {
    background: '#EFEFEA',
    surface: '#FFFFFF',
    textPrimary: '#242424',
    textSecondary: '#737373',
    accent: '#606060',
    divider: '#E2E2DE'
  },
  dark: {
    background: '#171717',
    surface: '#202020',
    textPrimary: '#F1F1EF',
    textSecondary: '#B8B8B5',
    accent: '#A4A4A0',
    divider: '#393937'
  }
};

export const PINE_MIST_STYLE: StyleTokens = {
  id: StylePresetId.PINE_MIST, fontId: 'system_serif_dev', paperId: 'pine_mist_dev', fontFamily: FontFamilies.SERIF,
  light: { background: '#EAF1EC', surface: '#F7FBF8', textPrimary: '#29342F', textSecondary: '#607168', accent: '#4F7464', divider: '#D5E1D9' },
  dark: { background: '#17201B', surface: '#202A24', textPrimary: '#EAF1EC', textSecondary: '#B5C6BC', accent: '#8AB39E', divider: '#35463D' }
};

export const MIST_BLUE_STYLE: StyleTokens = {
  id: StylePresetId.MIST_BLUE, fontId: 'system_serif_dev', paperId: 'mist_blue_dev', fontFamily: FontFamilies.SERIF,
  light: { background: '#EAF0F6', surface: '#F7FAFD', textPrimary: '#29333E', textSecondary: '#607080', accent: '#58718C', divider: '#D4DFE9' },
  dark: { background: '#17202A', surface: '#202A35', textPrimary: '#EAF0F6', textSecondary: '#B7C7D7', accent: '#91ABC6', divider: '#354657' }
};

export const APRICOT_PAPER_STYLE: StyleTokens = {
  id: StylePresetId.APRICOT_PAPER, fontId: 'system_serif_dev', paperId: 'apricot_paper_dev', fontFamily: FontFamilies.SERIF,
  light: { background: '#F7EFE2', surface: '#FDF9F2', textPrimary: '#3D3127', textSecondary: '#776558', accent: '#A76D46', divider: '#E7D9C7' },
  dark: { background: '#282019', surface: '#33291F', textPrimary: '#F7EFE2', textSecondary: '#D7C4B2', accent: '#D3A37C', divider: '#574535' }
};

export const STYLE_PRESETS: StyleTokens[] = [PAPER_INK_STYLE, PLAIN_ASH_STYLE, PINE_MIST_STYLE, MIST_BLUE_STYLE, APRICOT_PAPER_STYLE];

// ArkUI struct generated code has shown unstable cross-module live bindings for
// imported constants on some devices. Components call this function instead of
// reading STYLE_PRESETS directly; tests can still inspect the exported catalog.
export function allStylePresets(): StyleTokens[] {
  return [PAPER_INK_STYLE, PLAIN_ASH_STYLE, PINE_MIST_STYLE, MIST_BLUE_STYLE, APRICOT_PAPER_STYLE];
}

export function styleForPreset(id: StylePresetId): StyleTokens {
  switch (id) {
    case StylePresetId.PLAIN_ASH: return PLAIN_ASH_STYLE;
    case StylePresetId.PINE_MIST: return PINE_MIST_STYLE;
    case StylePresetId.MIST_BLUE: return MIST_BLUE_STYLE;
    case StylePresetId.APRICOT_PAPER: return APRICOT_PAPER_STYLE;
    case StylePresetId.PAPER_INK:
    default: return PAPER_INK_STYLE;
  }
}

export function styleForPaper(paperId: string): StyleTokens {
  switch (paperId) {
    case 'plain_ash_dev': return PLAIN_ASH_STYLE;
    case 'pine_mist_dev': return PINE_MIST_STYLE;
    case 'mist_blue_dev': return MIST_BLUE_STYLE;
    case 'apricot_paper_dev': return APRICOT_PAPER_STYLE;
    case 'warm_paper_dev':
    default: return PAPER_INK_STYLE;
  }
}

export function isSupportedPaperId(value: string): boolean {
  switch (value) {
    case 'warm_paper_dev':
    case 'plain_ash_dev':
    case 'pine_mist_dev':
    case 'mist_blue_dev':
    case 'apricot_paper_dev':
      return true;
    default:
      return false;
  }
}

export function isSupportedStylePreset(value: string): boolean {
  switch (value) {
    case StylePresetId.PAPER_INK:
    case StylePresetId.PLAIN_ASH:
    case StylePresetId.PINE_MIST:
    case StylePresetId.MIST_BLUE:
    case StylePresetId.APRICOT_PAPER:
      return true;
    default: return false;
  }
}

export function stylePresetIdFromValue(value: string): StylePresetId {
  switch (value) {
    case StylePresetId.PLAIN_ASH: return StylePresetId.PLAIN_ASH;
    case StylePresetId.PINE_MIST: return StylePresetId.PINE_MIST;
    case StylePresetId.MIST_BLUE: return StylePresetId.MIST_BLUE;
    case StylePresetId.APRICOT_PAPER: return StylePresetId.APRICOT_PAPER;
    case StylePresetId.PAPER_INK:
    default: return StylePresetId.PAPER_INK;
  }
}

export function paperIdForStyle(id: StylePresetId): string {
  return styleForPreset(id).paperId;
}
