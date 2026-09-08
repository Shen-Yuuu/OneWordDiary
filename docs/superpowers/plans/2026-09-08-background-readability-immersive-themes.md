# Background Readability, Immersive Bars, and Themes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use the native subagent workflow requested by the user. Each implementation worker uses gpt-5.6-terra / high. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Improve photo-background legibility, extend app backgrounds beneath system bars, and expand the diary from two to five coherent themes without breaking saved records, sharing, or backups.

**Architecture:** A centralized theme catalog resolves preset IDs and paper IDs into semantic colors, eliminating two-branch logic. `DiaryBackground` owns one shared layered-scrim recipe for every photo surface. `EntryAbility` owns best-effort transparent system-bar configuration, while the root page keeps controls inside safe areas.

**Tech Stack:** HarmonyOS 6.0.1 / API 21, ArkTS, ArkUI, Window API, resource qualifiers, Preferences, Hypium.

**Spec:** `docs/plans/2026-09-08-background-readability-immersive-themes-design.md`

## Global Constraints

- Keep the app locked to light mode.
- Add no permissions, dependencies, database migrations, version changes, or signing changes.
- Preserve existing `paper_ink` and `plain_ash` identifiers and their current visible colors.
- Add exactly `pine_mist`, `mist_blue`, and `apricot_paper` with paper IDs from the spec.
- Keep historical record `paperId` snapshots; current page chrome follows `currentPaperId`.
- Keep seven-day share behavior unchanged; single-day preview and export must use the same background layering.
- Window configuration failure must not block app startup.

---

### Task 1: Central Theme Catalog and Five-Theme Propagation

**Files:**
- Modify: `OneWord_dev/entry/src/main/ets/constants/StyleTokens.ets`
- Modify: `OneWord_dev/entry/src/main/resources/base/element/color.json`
- Modify: `OneWord_dev/entry/src/main/ets/components/common/PaperBackdrop.ets`
- Modify: `OneWord_dev/entry/src/main/ets/repository/SettingsRepository.ets`
- Modify: `OneWord_dev/entry/src/main/ets/viewmodel/SettingsViewModel.ets`
- Modify: `OneWord_dev/entry/src/main/ets/viewmodel/TodayViewModel.ets`
- Modify: `OneWord_dev/entry/src/main/ets/viewmodel/ShareViewModel.ets`
- Modify: `OneWord_dev/entry/src/main/ets/service/BackupCodec.ets`
- Modify: `OneWord_dev/entry/src/main/ets/pages/SettingsPage.ets`
- Modify theme-dependent page/component files found by `rg "plain_ash_dev|PLAIN_ASH" OneWord_dev/entry/src/main/ets`
- Test: `OneWord_dev/entry/src/test/SettingsViewModel.test.ets`
- Test: `OneWord_dev/entry/src/test/Backup.test.ets`
- Test: `OneWord_dev/entry/src/test/ThemeCatalog.test.ets`
- Modify: `OneWord_dev/entry/src/test/List.test.ets`

**Interfaces:**
- Produces: `STYLE_PRESETS: StyleTokens[]`
- Produces: `styleForPreset(id: StylePresetId): StyleTokens`
- Produces: `styleForPaper(paperId: string): StyleTokens`
- Produces: `isSupportedStylePreset(value: string): boolean`
- Produces: `paperIdForStyle(id: StylePresetId): string`
- Existing consumers retain `StylePresetId`, `StyleTokens`, `FontFamilies`, `PAPER_INK_STYLE`, and `PLAIN_ASH_STYLE` compatibility.

- [x] **Step 1: Add failing catalog and persistence tests**

Add assertions that all five preset IDs resolve to unique paper IDs, that an unknown preset falls back to paper ink, and that settings save/load accepts each new preset. Register `themeCatalogTest()` in `List.test.ets`.

```ts
expect(STYLE_PRESETS.length).assertEqual(5);
expect(styleForPreset(StylePresetId.PINE_MIST).paperId).assertEqual('pine_mist_dev');
expect(styleForPaper('mist_blue_dev').id).assertEqual(StylePresetId.MIST_BLUE);
expect(styleForPaper('unknown').id).assertEqual(StylePresetId.PAPER_INK);
```

- [x] **Step 2: Implement the catalog and semantic color accessors**

Extend the enum and define the three palettes. Keep all themes on `FontFamilies.SERIF`. Provide lookup functions using explicit `switch` statements compatible with ArkTS; callers must not duplicate theme IDs.

```ts
export enum StylePresetId {
  PAPER_INK = 'paper_ink',
  PLAIN_ASH = 'plain_ash',
  PINE_MIST = 'pine_mist',
  MIST_BLUE = 'mist_blue',
  APRICOT_PAPER = 'apricot_paper'
}

export function paperIdForStyle(id: StylePresetId): string {
  return styleForPreset(id).paperId;
}
```

Add base color resources for each paper, surface, text-secondary/accent/divider pair when a component requires a `ResourceColor`. Do not alter dark resources because runtime is locked to light mode.

- [x] **Step 3: Replace binary theme validation and mapping**

Use the catalog in `SettingsRepository`, `SettingsViewModel`, `TodayViewModel`, `ShareViewModel`, and `BackupCodec`. Backup record validation must accept only the catalog’s five `fontId/paperId` combinations and reject unknown paper IDs. Old values remain byte-for-byte compatible.

```ts
private toStylePresetId(value: string): StylePresetId {
  return stylePresetIdFromValue(value);
}
```

- [x] **Step 4: Render five responsive cards and propagate semantic colors**

Render setting cards from the catalog in a wrapping `Flex`, with 44vp minimum tap targets and selection accessibility text. Replace every page-level `paperId === 'plain_ash_dev' ? ... : ...` branch with a catalog helper or a focused component helper. Preserve historical content snapshots and seven-day card behavior.

- [x] **Step 5: Run focused tests and scan for binary branches**

Run the configured Hypium suite and verify the new theme tests pass. Then run:

```powershell
rg -n "paperId === 'plain_ash_dev'|StylePresetId\.PLAIN_ASH \?" OneWord_dev/entry/src/main/ets
```

Expected: no theme-selection binary branch remains outside catalog compatibility code.

---

### Task 2: Shared Layered Background Readability

**Files:**
- Modify: `OneWord_dev/entry/src/main/ets/components/common/DiaryBackground.ets`
- Test: `OneWord_dev/entry/src/test/DiaryBackgroundDomain.test.ets`

**Interfaces:**
- Consumes: `styleForPaper(paperId: string): StyleTokens` from Task 1.
- Produces: unchanged `DiaryBackground` public properties and callbacks.
- Produces: centralized `PHOTO_SCRIM_OPACITY = 0.74` and reading-focus gradient values used by home, confirmation, detail, and single-day share automatically.

- [x] **Step 1: Add a focused token test**

Test that the shared default is 0.74 and that every supported `paperId` resolves to a valid overlay color. Keep rendering callbacks and `reloadKey` behavior unchanged.

- [x] **Step 2: Implement the layered paper wash**

Keep the image as the bottom layer using `ImageFit.Cover`. Place a uniform theme paper-color row at opacity 0.74 over it, followed by a noninteractive center-weighted gradient layer. The gradient should add no more than 0.12 opacity at the reading center and fade toward the page edges.

```ts
Row()
  .linearGradient({
    angle: 90,
    colors: [
      [transparentPaper, 0.0],
      [readingPaper, 0.5],
      [transparentPaper, 1.0]
    ]
  })
```

Use fixed light theme hex colors for `fixedLightScrim` so component snapshots do not depend on resource resolution. Keep the entire image stack invisible until decode completion; missing and failed images continue to reveal the original `PaperBackdrop`.

- [x] **Step 3: Verify every photo surface inherits the default**

Inspect all `DiaryBackground` call sites. Remove local `scrimOpacity: 0.68` overrides so the shared 0.74 default applies. `ShareSingleCard` must keep `fixedLightScrim: true`; seven-day sharing must not acquire `DiaryBackground`.

- [x] **Step 4: Run background and share tests**

Run the complete Hypium suite because this shared component affects the home flow and share readiness behavior. Confirm no test changes weaken the existing load-generation or timeout assertions.

---

### Task 3: Transparent System Bars and Edge-to-Edge Background

**Files:**
- Modify: `OneWord_dev/entry/src/main/ets/entryability/EntryAbility.ets`
- Modify: `OneWord_dev/entry/src/main/ets/pages/Index.ets` only if API behavior requires a background-only safe-area expansion
- Test: compile-time validation through Debug HAP build
- Document: `docs/testing/2026-09-08-background-theme-immersive-acceptance.md`

**Interfaces:**
- Produces: `configureImmersiveWindow(windowStage: window.WindowStage): Promise<void>`
- Keeps `initializeAndLoad()` startup behavior and font registration ordering intact.

- [x] **Step 1: Verify the local API signatures**

Use the installed API 21 declarations to confirm the supported calls for edge-to-edge layout, transparent status/navigation bars, and system icon brightness. Record exact signatures in the acceptance document; avoid deprecated calls when an API 21 replacement exists.

- [x] **Step 2: Implement best-effort window configuration**

After content loads, obtain the main window and apply edge-to-edge layout plus transparent status and navigation colors. Select dark status/navigation icons because the app is locked to a light paper wash. Catch `BusinessError`, log `window.immersive_failed code=<code>`, and continue startup.

```ts
private async configureImmersiveWindow(windowStage: window.WindowStage): Promise<void> {
  try {
    const mainWindow: window.Window = await windowStage.getMainWindow();
    // Use the exact API 21 calls verified in Step 1.
    AppLogger.info('window.immersive_ready');
  } catch (error) {
    const businessError = error as BusinessError;
    AppLogger.error(`window.immersive_failed code=${businessError.code}`);
  }
}
```

- [x] **Step 3: Preserve safe content placement**

Verify the root background fills the window while interactive content remains within system safe areas. If full-window layout moves controls under the status/navigation regions, apply `expandSafeArea` only to `PaperBackdrop` and `DiaryBackground` layers rather than the entire interactive column.

- [x] **Step 4: Build and document device limits**

Run Debug `assembleHap`. If no connected device exists, mark status-bar icon contrast, gesture-bar transparency, cutout layout, and three-button navigation as pending device checks.

---

### Task 4: Lead Integration and Acceptance

**Files:**
- Modify: `docs/testing/2026-09-08-background-theme-immersive-acceptance.md`
- Modify: this plan’s checkboxes as work completes

- [x] **Step 1: Review cross-task consistency**

Confirm the catalog is the only theme source, all five IDs round-trip through settings and backup, `DiaryBackground` uses the same layers in single-day sharing, and system-bar setup cannot block initialization.

- [x] **Step 2: Run full tests and final signed build**

Run Hypium and inspect `test_result.txt` for actual failure/error counts; hvigor exit code alone is insufficient. Then run Debug `assembleHap` and record the signed HAP path and size.

- [x] **Step 3: Check scope and text integrity**

Run `git diff --check`, scan changed `.ets/.json/.md` for U+FFFD, and confirm no changes to permissions, dependencies, app version, database version, or signing configuration.

- [x] **Step 4: Record remaining device acceptance**

Document which visual and system-UI checks were performed on a connected device. If no device is connected, do not claim full visual acceptance; provide a concrete checklist for background legibility, five themes, system bars, sharing, and legacy records.
