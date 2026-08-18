---
name: OneWord Diary
colors:
  surface: '#fdf8f7'
  surface-dim: '#ddd9d8'
  surface-bright: '#fdf8f7'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f7f3f1'
  surface-container: '#f1edec'
  surface-container-high: '#ebe7e6'
  surface-container-highest: '#e6e2e0'
  on-surface: '#1c1b1b'
  on-surface-variant: '#4a463f'
  inverse-surface: '#31302f'
  inverse-on-surface: '#f4f0ee'
  outline: '#7b776e'
  outline-variant: '#ccc6bc'
  surface-tint: '#615e59'
  primary: '#13110e'
  on-primary: '#ffffff'
  primary-container: '#282622'
  on-primary-container: '#918d87'
  inverse-primary: '#cbc6bf'
  secondary: '#635e55'
  on-secondary: '#ffffff'
  secondary-container: '#eae1d6'
  on-secondary-container: '#69645b'
  tertiary: '#2c0200'
  on-tertiary: '#ffffff'
  tertiary-container: '#49140a'
  on-tertiary-container: '#c87867'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#e7e2db'
  primary-fixed-dim: '#cbc6bf'
  on-primary-fixed: '#1d1b18'
  on-primary-fixed-variant: '#494642'
  secondary-fixed: '#eae1d6'
  secondary-fixed-dim: '#cdc5bb'
  on-secondary-fixed: '#1f1b14'
  on-secondary-fixed-variant: '#4b463e'
  tertiary-fixed: '#ffdad3'
  tertiary-fixed-dim: '#ffb4a5'
  on-tertiary-fixed: '#3b0903'
  on-tertiary-fixed-variant: '#733427'
  background: '#fdf8f7'
  on-background: '#1c1b1b'
  surface-variant: '#e6e2e0'
typography:
  display-word:
    fontFamily: Noto Serif SC
    fontSize: 48px
    fontWeight: '500'
    lineHeight: 64px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Noto Serif SC
    fontSize: 24px
    fontWeight: '500'
    lineHeight: 32px
    letterSpacing: 0em
  headline-lg-mobile:
    fontFamily: Noto Serif SC
    fontSize: 22px
    fontWeight: '500'
    lineHeight: 30px
  body-md:
    fontFamily: Noto Sans SC
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 28px
    letterSpacing: 0.01em
  label-caps:
    fontFamily: Noto Sans SC
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.1em
  date-numeral:
    fontFamily: Noto Sans SC
    fontSize: 14px
    fontWeight: '300'
    lineHeight: 20px
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  margin-horizontal: 24px
  gutter: 16px
  section-gap: 40px
---

## Brand & Style
The design system is rooted in the philosophy of "Modern Oriental White Space," merging the serene atmosphere of a contemporary art museum with the tactile intimacy of high-end stationery. It is a quiet, meditative environment that honors the user's daily reflection through restraint and poetic clarity.

The aesthetic is characterized by an expansive use of "negative space" as a functional element rather than a void. It avoids the clutter of traditional ornamentation, opting instead for a minimal editorial approach where typography and proportion serve as the primary visual interest. The emotional response is one of calm, privacy, and timelessness.

## Colors
This palette mimics the interplay of ink and paper. The background is a warm, unbleached paper white that reduces eye strain and provides a sense of physical presence.

- **Primary (Ink Grey):** Used for main headings and the "One Word" of the day. It provides a grounded, authoritative contrast.
- **Secondary (Taupe Grey):** Used for meta-data, dates, and secondary instructions to maintain a clear hierarchy without visual noise.
- **Accent (Vermilion):** Inspired by traditional seal paste, this color is used with extreme restraint—only for meaningful indicators like a "saved" status or a subtle decorative seal-inspired mark.
- **Dividers:** Use the ultra-light warm grey for thin, 1px lines to separate sections without breaking the flow of the "Word Scroll."

## Typography
The typography system relies on the contrast between a literary Serif and a functional Sans-serif.

- **The Daily Word:** Should always be rendered in Noto Serif SC with tight tracking to emphasize the character's form.
- **Body Text:** Use Noto Sans SC for longer reflections to ensure readability.
- **Editorial Numbers:** Numbers and dates should utilize wider letter spacing to evoke a modern, clean, and organized aesthetic.
- **Vertical Orientation:** For the "Word Scroll," specific entries may be laid out vertically (right-to-left), maintaining the Serif font for the central character.

## Layout & Spacing
The layout follows an 8px modular grid. A generous 24px horizontal margin is mandatory for all screens to create the "museum frame" effect.

- **Word Scroll (文字长卷):** A continuous vertical flow with no bottom navigation bar. Interaction is driven by gestures and clear, top-aligned or floating contextual actions.
- **Alignment:** Use a mix of centered alignments for display moments and asymmetrical left-aligned layouts for diary entries.
- **Adaptation:** On larger displays, the content width remains constrained (max-width 600px) to preserve the intimate reading experience, centered on the screen with expanded margins.

## Elevation & Depth
This design system avoids traditional shadows to maintain a "flat paper" aesthetic. Depth is achieved through layering and subtle tonal shifts:

- **Surface Levels:** Use tonal stacking rather than shadows. The primary background is the lowest level.
- **Paper Lift:** If an element must appear elevated (like a floating action button for a new entry), use a very soft, low-opacity (#282622 at 5%) blur with a significant spread to simulate a light paper curl rather than a digital shadow.
- **Grain Texture:** A 2-4% nearly invisible paper grain overlay is applied to the entire UI to give the digital surface a tactile, organic quality.

## Shapes
Shapes are soft yet structured. Corners use a 12px default radius (rounded-lg) for most containers, providing a modern feel that isn't overly "bubbly."

- **Seals:** Small accent indicators or "stamps" use a 2px radius for a more rigid, hand-carved stone appearance.
- **Inputs:** Text fields and selection areas should have subtle, rounded corners to contrast with the sharp verticality of the Serif typography.

## Components
- **Buttons:** Primary buttons are solid Deep Ink Grey with white text. Secondary buttons are ghost-style with a 1px border of `divider_color_hex`.
- **The "Seal" Indicator:** A small, square Vermilion box (approx 24x24px) containing a single character or icon, used to mark favorited or "completed" days.
- **Linear Icons:** Icons must use a thin stroke weight (1px to 1.5px) and avoid filled states unless active.
- **Input Fields:** Minimalist under-lines rather than boxes are preferred for a "writing on a page" feel.
- **Diary Cards:** Cards in the scroll do not have borders; they are separated by generous white space and the occasional subtle divider line.
- **Date Header:** A floating or sticky header that uses wide-tracked sans-serif numerals, keeping the user oriented within the long vertical scroll.
