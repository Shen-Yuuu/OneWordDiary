# Immersive Foreground Top Offset Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use the native subagent workflow requested by the user. Each worker uses gpt-5.6-terra / medium. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore full-screen foreground layout while manually moving only top page content below the status bar.

**Architecture:** One shared float resource controls the manual 32vp offset. Full-screen window configuration remains global; each foreground page column consumes the resource while background stacks remain unpadded.

**Tech Stack:** HarmonyOS 6.0.1 / API 21, ArkTS, ArkUI, Window API, Hvigor, Hypium.

**Spec:** `docs/plans/2026-09-09-immersive-top-offset-design.md`

## Global Constraints

- Use `app.float.immersive_top_content_offset` with default `32vp`.
- Restore `setWindowLayoutFullScreen(true)`.
- Do not use automatic safe-area avoidance or query avoid-area dimensions.
- Do not add padding to `PaperBackdrop`, `DiaryBackground`, or page root stacks.
- Do not modify background image opacity, diary data, sharing data, backup data, permissions, dependencies, versions, signing, or database version.

---

### Task 1: Shared Offset and Full-Screen Window

**Files:**
- Modify: `OneWord_dev/entry/src/main/resources/base/element/float.json`
- Modify: `OneWord_dev/entry/src/main/ets/entryability/EntryAbility.ets`

- [ ] Add `immersive_top_content_offset` with value `32vp`.
- [ ] Restore `await mainWindow.setWindowLayoutFullScreen(true)` while preserving transparent bar properties and error handling.
- [ ] Run `git diff --check` for both files.

### Task 2: Home and Confirmation Foreground Offset

**Files:**
- Modify: `OneWord_dev/entry/src/main/ets/pages/Index.ets`
- Modify: `OneWord_dev/entry/src/main/ets/components/diary/TodayConfirmation.ets`

- [ ] Add `top: $r('app.float.immersive_top_content_offset')` to the existing foreground-column padding objects.
- [ ] Keep loading/error panels, root stacks, PaperBackdrop, and DiaryBackground unchanged.
- [ ] Confirm both files contain the resource and no new numeric top padding.

### Task 3: Destination Foreground Offset

**Files:**
- Modify: `OneWord_dev/entry/src/main/ets/pages/DetailPage.ets`
- Modify: `OneWord_dev/entry/src/main/ets/pages/ScrollPage.ets`
- Modify: `OneWord_dev/entry/src/main/ets/pages/SettingsPage.ets`
- Modify: `OneWord_dev/entry/src/main/ets/pages/BackupPage.ets`
- Modify: `OneWord_dev/entry/src/main/ets/pages/PrivacyPage.ets`
- Modify: `OneWord_dev/entry/src/main/ets/pages/SharePreviewPage.ets`

- [ ] Add the shared top padding to each full-page foreground column, merging with existing left/right padding where present.
- [ ] Keep root stacks and backgrounds unpadded.
- [ ] Scan all six files for the resource and run `git diff --check`.

### Task 4: Integration and Acceptance

**Files:**
- Create: `docs/testing/2026-09-09-immersive-top-offset-acceptance.md`
- Modify: this plan's checkboxes.

- [ ] Run all Hypium tests and inspect the actual result summary.
- [ ] Build the final signed Debug HAP and record path, size, time, and SHA-256.
- [ ] Confirm scope, U+FFFD integrity, and no unrelated configuration changes.
- [ ] Record the connected-device status and manual top-offset visual checklist.
