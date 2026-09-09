# 玫瑰粉第六主题 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a sixth “玫瑰粉” diary theme that works across settings, diary views, sharing, and backup style restoration.

**Architecture:** Extend the existing `StyleTokens` catalog with one enum value, one palette, and the corresponding preset/paper parsing branches. Existing consumers already resolve colors through `styleForPreset`, `styleForPaper`, and `allStylePresets`, so pages remain unchanged except for label/sample mappings in `SettingsPage`. Update catalog/settings/backup tests to lock the six-theme contract.

**Tech Stack:** HarmonyOS ArkTS/ArkUI, Hypium, Hvigor.

**Spec:** `docs/plans/2026-09-09-vine-purple-theme-design.md`

## Global Constraints

- Preserve all existing theme identifiers and visible colors.
- Add exactly one theme: `rose_pink` with paper ID `rose_pink_dev`.
- Use the palette from the design spec: light `#F8E8EC/#FFF7F8/#3D2930/#80636A/#B15F76/#E8CDD4`; dark `#2A1C22/#35232B/#F9EAF0/#D2B4BF/#D889A1/#513641`.
- Unknown theme/paper values must retain the existing fallback to `PAPER_INK`.
- Do not add permissions, dependencies, database migrations, or background-image backup fields.

---

### Task 1: Extend the theme catalog

**Files:**
- Modify: `OneWord_dev/entry/src/main/ets/constants/StyleTokens.ets`
- Test: `OneWord_dev/entry/src/test/ThemeCatalog.test.ets`

**Interfaces:**
- Produces `StylePresetId.ROSE_PINK`, `ROSE_PINK_STYLE`, and parser support for `rose_pink` / `rose_pink_dev`.

- [ ] **Step 1: Update the catalog contract test**

Change the expected catalog size from 5 to 6 and assert that `styleForPreset(StylePresetId.ROSE_PINK).paperId` is `rose_pink_dev`; keep the existing uniqueness and unknown-fallback assertions.

- [ ] **Step 2: Run the focused test compilation**

Run from `OneWord_dev`:

```powershell
$env:DEVECO_SDK_HOME='D:\local\DevEcoStudio\sdk'
& 'D:\local\DevEcoStudio\tools\hvigor\bin\hvigorw.bat' test --mode module -p module=entry@default -p product=default -p buildMode=debug --no-daemon
```

Expected before implementation: the updated six-theme assertion fails if the runtime reaches Hypium; ArkTS compilation must still complete.

- [ ] **Step 3: Add the enum and palette**

Add the enum value and a `ROSE_PINK_STYLE` object using the exact design palette. Add it to `STYLE_PRESETS` and `allStylePresets()`. Add switch cases to `styleForPreset`, `styleForPaper`, `isSupportedPaperId`, `isSupportedStylePreset`, and `stylePresetIdFromValue`.

- [ ] **Step 4: Re-run static checks**

Run:

```powershell
rg -n "ROSE_PINK|rose_pink" OneWord_dev/entry/src/main/ets/constants/StyleTokens.ets
git diff --check
```

Expected: every catalog/parser location contains the new identifier and no whitespace errors are reported.

- [ ] **Step 5: Commit the catalog change**

```powershell
git add OneWord_dev/entry/src/main/ets/constants/StyleTokens.ets OneWord_dev/entry/src/test/ThemeCatalog.test.ets
git commit -m "feat: add vine purple diary theme"
```

### Task 2: Update settings labels and style persistence coverage

**Files:**
- Modify: `OneWord_dev/entry/src/main/ets/pages/SettingsPage.ets`
- Test: `OneWord_dev/entry/src/test/SettingsViewModel.test.ets`

**Interfaces:**
- Consumes `StylePresetId.ROSE_PINK` from Task 1.
- Produces the display label `玫瑰粉` and sample character `玫`; settings continue to iterate `allStylePresets()`.

- [ ] **Step 1: Add new-style cases to the settings label helpers**

In `styleLabel` return `玫瑰粉` for `ROSE_PINK`; in `styleSample` return `玫` for `ROSE_PINK`. Do not add a separate UI list or page-level color branch.

- [ ] **Step 2: Extend settings persistence coverage**

Add `StylePresetId.ROSE_PINK` to the existing style iteration in `SettingsViewModel.test.ets`, then assert selection saves and reloads the new enum value through the current repository path.

- [ ] **Step 3: Run the settings/catalog checks**

Run the project test command above. Expected: ArkTS test compilation succeeds; if RichPreviewer cannot start, record the environmental error and inspect the generated test result rather than changing production code.

- [ ] **Step 4: Commit settings integration**

```powershell
git add OneWord_dev/entry/src/main/ets/pages/SettingsPage.ets OneWord_dev/entry/src/test/SettingsViewModel.test.ets
git commit -m "feat: expose vine purple theme in settings"
```

### Task 3: Verify backup compatibility and application build

**Files:**
- Test: `OneWord_dev/entry/src/test/Backup.test.ets`
- Modify: `docs/plans/2026-09-09-vine-purple-theme-design.md` only if implementation notes need correction.

**Interfaces:**
- Consumes the new supported style parser from Task 1.
- Produces proof that v1 backup encode/decode accepts `StylePresetId.ROSE_PINK` and restores it without any background image data.

- [ ] **Step 1: Add the backup round-trip assertion**

Encode a valid record with `StylePresetId.ROSE_PINK`, decode it, and assert `decoded.stylePresetId === StylePresetId.ROSE_PINK`; also assert the encoded JSON does not contain `background_image`.

- [ ] **Step 2: Run the complete ArkTS build**

Run:

```powershell
$env:DEVECO_SDK_HOME='D:\local\DevEcoStudio\sdk'
& 'D:\local\DevEcoStudio\tools\hvigor\bin\hvigorw.bat' assembleHap --mode module -p module=entry@default -p product=default -p buildMode=debug --no-daemon
```

Expected: `BUILD SUCCESSFUL`, with only the repository's existing “Function may throw exceptions” warnings.

- [ ] **Step 3: Perform final static acceptance**

Run:

```powershell
rg -n "STYLE_PRESETS.length|ROSE_PINK|rose_pink_dev|background_image" OneWord_dev/entry/src/main/ets OneWord_dev/entry/src/test
git diff --check
git status --short
```

Expected: the six-theme references are present, backup tests still assert no image field, and the working tree is clean after commits.

- [ ] **Step 4: Commit the verification test**

```powershell
git add OneWord_dev/entry/src/test/Backup.test.ets
git commit -m "test: cover vine purple backup restoration"
```
