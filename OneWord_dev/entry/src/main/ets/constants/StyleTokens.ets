export enum StylePresetId {
  PAPER_INK = 'paper_ink',
  PLAIN_ASH = 'plain_ash'
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
  fontFamily: 'serif',
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
  fontFamily: 'sans-serif',
  light: {
    background: '#F7F7F5',
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
