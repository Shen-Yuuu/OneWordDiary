# Per-Day Diary Font Selection Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a settings-level default font and persist a font snapshot per diary record so every diary surface renders the font chosen for that day.

**Architecture:** A central font catalog owns stable IDs and ArkUI family resolution. Settings persist the next-entry default independently from themes, while the existing `DailyRecord.fontId` remains the historical snapshot used by detail, scroll, and share rendering.

**Tech Stack:** HarmonyOS NEXT, ArkTS, ArkUI, Preferences, RDB, Hypium, Hvigor

**Spec:** `docs/plans/2026-09-12-per-day-font-selection-design.md`

## Global Constraints

- Font selection is independent from theme selection.
- User fonts apply only to diary content, notes, and font previews.
- Existing records using `system_serif_dev` or `system_sans_dev` remain readable.
- Backup format remains text-only v1 and never embeds font or background binaries.
- Unknown or unavailable fonts fall back to `oneword_wenkai, serif`.

---

### Task 1: Font Catalog and Bundled Registration

**Files:**
- Create: `OneWord_dev/entry/src/main/ets/constants/FontCatalog.ets`
- Modify: `OneWord_dev/entry/src/main/ets/entryability/EntryAbility.ets`
- Test: `OneWord_dev/entry/src/test/FontCatalog.test.ets`
- Modify: `OneWord_dev/entry/src/test/List.test.ets`

**Interfaces:**
- Produces: `FontPresetId`, `FontOption`, `allFontOptions()`, `fontFamilyForId(string)`, `fontPresetIdFromValue(string)`, `isSupportedFontId(string)`.
- Produces: registered family names for the five supplied font files.

- [ ] **Step 1:** Add catalog tests that assert six selectable options, stable IDs, legacy ID support, and unknown-ID fallback.
- [ ] **Step 2:** Run the ArkTS unit-test compile and confirm the missing catalog fails.
- [ ] **Step 3:** Implement the catalog with switch-based resolution and legacy mappings.
- [ ] **Step 4:** Register all supplied rawfile fonts after `loadContent`, verifying each resource before registration and preserving the existing fallback behavior.
- [ ] **Step 5:** Run catalog tests and commit the catalog, registrations, tests, and supplied font assets.

### Task 2: Persist the Default Font Setting

**Files:**
- Modify: `OneWord_dev/entry/src/main/ets/model/Settings.ets`
- Modify: `OneWord_dev/entry/src/main/ets/repository/SettingsRepository.ets`
- Modify: `OneWord_dev/entry/src/main/ets/viewmodel/SettingsViewModel.ets`
- Modify: `OneWord_dev/entry/src/test/SettingsViewModel.test.ets`

**Interfaces:**
- Consumes: `FontPresetId.DEFAULT`, `fontPresetIdFromValue`, `isSupportedFontId`.
- Produces: `AppSettings.fontPresetId`, `SettingsRepository.saveFontPresetId(FontPresetId)`, `SettingsViewModel.selectFont(FontPresetId)`, AppStorage key `currentFontId`.

- [ ] **Step 1:** Extend repository and view-model fakes with font persistence, then test load, selection, save rollback, and reset behavior.
- [ ] **Step 2:** Run the focused test compile and confirm the new interfaces fail.
- [ ] **Step 3:** Add `font_preset_id` Preferences persistence with validation and default fallback.
- [ ] **Step 4:** Add optimistic selection, rollback on failure, and AppStorage synchronization in `SettingsViewModel`.
- [ ] **Step 5:** Run settings tests and commit the persistence slice.

### Task 3: Settings Font Picker

**Files:**
- Modify: `OneWord_dev/entry/src/main/ets/pages/SettingsPage.ets`

**Interfaces:**
- Consumes: `allFontOptions()`, `fontFamilyForId()`, `SettingsViewModel.selectFont()`.

- [ ] **Step 1:** Add a compact “字体” section after theme selection with six selectable preview rows/cards.
- [ ] **Step 2:** Render each preview using its own registered family and show selection using the active theme accent and border.
- [ ] **Step 3:** Confirm the existing page scroll and bottom safe-area spacing still expose every settings action.
- [ ] **Step 4:** Run ArkTS compilation and commit the settings UI.

### Task 4: Capture Font on Today Submission and Revision

**Files:**
- Modify: `OneWord_dev/entry/src/main/ets/viewmodel/TodayViewModel.ets`
- Modify: `OneWord_dev/entry/src/main/ets/components/diary/TodayEditor.ets`
- Modify: `OneWord_dev/entry/src/main/ets/components/diary/TodayConfirmation.ets`
- Modify: `OneWord_dev/entry/src/main/ets/pages/Index.ets`
- Modify: `OneWord_dev/entry/src/test/TodayViewModel.test.ets`

**Interfaces:**
- Consumes: `AppSettings.fontPresetId`, `fontFamilyForId()`.
- Produces: `TodayViewModel.fontPresetId`; `createInput()` writes it into `DiaryEntryInput.fontId`.

- [ ] **Step 1:** Add tests for first-run default, selected-font submission, unchanged historical records, and revision capturing the current font.
- [ ] **Step 2:** Run focused tests and confirm they fail against theme-derived font behavior.
- [ ] **Step 3:** Load the selected font independently from settings and use it in submitted inputs.
- [ ] **Step 4:** Pass the resolved family to the editor and confirmation so content and note preview match the stored value.
- [ ] **Step 5:** Run Today tests and commit the capture/render slice.

### Task 5: Historical Rendering Across Detail, Scroll, and Share

**Files:**
- Modify: `OneWord_dev/entry/src/main/ets/components/common/DiaryHeroContent.ets`
- Modify: `OneWord_dev/entry/src/main/ets/components/scroll/ScrollRecordNode.ets`
- Modify: `OneWord_dev/entry/src/main/ets/components/share/ShareSingleCard.ets`
- Modify: `OneWord_dev/entry/src/main/ets/components/share/ShareScrollCard.ets`
- Modify: `OneWord_dev/entry/src/main/ets/model/ShareModel.ets`
- Modify: `OneWord_dev/entry/src/main/ets/viewmodel/ShareViewModel.ets`
- Test: `OneWord_dev/entry/src/test/ScrollDetail.test.ets`
- Test: `OneWord_dev/entry/src/test/ShareViewModel.test.ets`

**Interfaces:**
- Consumes: per-record `fontId` and `fontFamilyForId()`.
- Produces: seven-day share items that retain each source record's `fontId`.

- [ ] **Step 1:** Add tests proving two records with different font IDs keep different resolved families in scroll/detail/share data.
- [ ] **Step 2:** Run focused tests and confirm current hard-coded/global family behavior fails.
- [ ] **Step 3:** Replace hard-coded diary content families with catalog resolution in hero, scroll, and single-share components.
- [ ] **Step 4:** Carry each record's font ID into seven-day share items and resolve the family per row.
- [ ] **Step 5:** Run detail, scroll, and share tests and commit historical rendering.

### Task 6: Backup Validation Compatibility

**Files:**
- Modify: `OneWord_dev/entry/src/main/ets/service/BackupCodec.ets`
- Modify: `OneWord_dev/entry/src/test/Backup.test.ets`

**Interfaces:**
- Consumes: `isSupportedFontId(string)`, `isSupportedPaperId(string)`.
- Preserves: text-only backup format version 1.

- [ ] **Step 1:** Add round-trip tests for every new font ID and rejection of an unknown font ID.
- [ ] **Step 2:** Change validation to accept any supported font independently from any supported paper while rejecting unknown values.
- [ ] **Step 3:** Verify serialized text contains font IDs but no font paths, binary content, or background references.
- [ ] **Step 4:** Run backup tests and commit backup compatibility.

### Task 7: Full Verification and Acceptance Record

**Files:**
- Create: `docs/testing/2026-09-12-per-day-font-selection-acceptance.md`

**Interfaces:**
- Consumes: the complete feature and its focused tests.

- [ ] **Step 1:** Run all ArkTS unit tests and record the result.
- [ ] **Step 2:** Run signed HAP and APP builds and require `BUILD SUCCESSFUL`.
- [ ] **Step 3:** Run `git diff --check` and inspect the final diff for unrelated generated artifacts.
- [ ] **Step 4:** Record automated evidence plus the required six-scenario true-device checklist in the acceptance document.
- [ ] **Step 5:** Commit final verification documentation.
