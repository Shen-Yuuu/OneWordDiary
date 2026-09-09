# Background Rendering and Safe Area Repair Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use the native subagent workflow requested by the user. Each implementation worker uses gpt-5.6-terra / medium. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make photo-background strength reliably visible on real devices, remove the redundant editor thumbnail, and keep foreground controls outside system bars.

**Architecture:** `PaperBackdrop` remains the opaque theme underlay. `DiaryBackground` renders only the loaded image at one shared low opacity, avoiding empty overlay nodes. Window layout returns to system-safe content placement while background components alone retain system-safe-area expansion.

**Tech Stack:** HarmonyOS 6.0.1 / API 21, ArkTS, ArkUI, Window API, Hypium, Hvigor.

**Spec:** `docs/plans/2026-09-09-background-rendering-repair-design.md`

## Global Constraints

- Default `PHOTO_IMAGE_OPACITY` is exactly `0.16`; lower values make the photo fainter.
- Keep background ownership, persistence, backup, revision, and share readiness behavior unchanged.
- Add no permissions, dependencies, database migrations, version changes, or signing changes.
- Keep transparent status and navigation bars with dark system icons.
- Preserve `PaperBackdrop` and `DiaryBackground` top/bottom system safe-area expansion.
- Do not modify or delete `OneWord_dev/test-data/`.

---

### Task 1: Direct Image Opacity Rendering

**Files:**
- Modify: `OneWord_dev/entry/src/main/ets/components/common/DiaryBackground.ets`
- Modify: `OneWord_dev/entry/src/main/ets/components/share/ShareSingleCard.ets`

**Interfaces:**
- Produces: `PHOTO_IMAGE_OPACITY: number = 0.16`
- Preserves: `imageUri`, `paperId`, `reloadKey`, `onReady`, and `onFailed` component behavior.
- Removes: `scrimOpacity`, `fixedLightScrim`, and all paper-overlay color getters.

- [x] **Step 1: Replace overlay composition with direct image opacity**

Keep the existing `ForEach`, load-generation guard, decode callbacks, hidden-until-loaded behavior, hit testing, accessibility, and safe-area expansion. Apply `.opacity(PHOTO_IMAGE_OPACITY)` to `Image(source.uri)`. Remove both empty overlay rows and their color functions.

```ts
export const PHOTO_IMAGE_OPACITY: number = 0.16;

Image(source.uri)
  .width('100%')
  .height('100%')
  .objectFit(ImageFit.Cover)
  .opacity(PHOTO_IMAGE_OPACITY)
```

The outer loaded-state opacity remains separate: it switches the image layer between hidden and visible; it does not tune background strength.

- [x] **Step 2: Remove call-site opacity overrides**

Update `ShareSingleCard` to construct `DiaryBackground` using only image URI, paper ID, reload key, and callbacks. Search every call site and confirm no removed property remains.

```powershell
rg -n "scrimOpacity|fixedLightScrim|PHOTO_SCRIM_OPACITY|readingPaperColor" OneWord_dev/entry/src
```

Expected: no matches.

- [x] **Step 3: Compile the ArkTS module**

Run Debug `assembleHap`. Expected: `CompileArkTS`, `PackageHap`, `PackingCheck`, and `SignHap` succeed.

---

### Task 2: Editor Background Controls Without Thumbnail

**Files:**
- Modify: `OneWord_dev/entry/src/main/ets/components/diary/TodayEditor.ets`

**Interfaces:**
- Keeps: `backgroundImageUri`, `isPickingBackground`, `backgroundError`, `onChooseBackground`, and `onRemoveBackground`.
- Removes: the thumbnail-only `DiaryBackground` dependency and subtree.

- [x] **Step 1: Delete the thumbnail subtree and import**

Delete the conditional 76×52 `Stack` containing `DiaryBackground`. Remove the unused import. Keep the existing button labels and callbacks.

- [x] **Step 2: Strengthen the remaining controls**

Set both background action buttons to the existing `app.float.touch_target_min` height. Add `accessibilityText` values that resolve to “选择今日背景”, “更换今日背景”, and “移除今日背景” according to state. Keep picker loading and disabled behavior unchanged.

- [x] **Step 3: Verify no thumbnail renderer remains**

```powershell
rg -n "DiaryBackground|scrimOpacity: 0\.18|\.width\(76\)|\.height\(52\)" OneWord_dev/entry/src/main/ets/components/diary/TodayEditor.ets
```

Expected: no matches.

---

### Task 3: System-Safe Foreground Layout

**Files:**
- Modify: `OneWord_dev/entry/src/main/ets/entryability/EntryAbility.ets`

**Interfaces:**
- Keeps: `configureImmersiveWindow(windowStage: window.WindowStage): Promise<void>`.
- Changes: full-screen content layout from enabled to disabled.

- [x] **Step 1: Restore automatic system-bar avoidance**

Use `await mainWindow.setWindowLayoutFullScreen(false)`. Keep transparent system bar colors, dark icon configuration, logging, and best-effort error handling unchanged.

- [x] **Step 2: Confirm only backgrounds expand into system areas**

Search for `expandSafeArea`. Expected production matches are the background implementations; page foreground columns must not expand.

- [x] **Step 3: Compile with API 21 declarations**

Run Debug `assembleHap` and confirm no API error is introduced.

---

### Task 4: Integration and Acceptance

**Files:**
- Create: `docs/testing/2026-09-09-background-rendering-repair-acceptance.md`
- Modify: this plan's checkboxes as work completes.

- [x] **Step 1: Run the complete Hypium suite**

Run the configured module tests and inspect `OneWord_dev/entry/.test/default/intermediates/test/coverage_data/test_result.txt` for actual failure and error counts.

- [x] **Step 2: Run the final signed Debug build**

Run `assembleHap`, then record the signed HAP absolute path, byte size, modification time, and SHA-256 in the acceptance document.

- [x] **Step 3: Check scope and source integrity**

Run `git diff --check`, scan changed text for U+FFFD, confirm `OneWord_dev/test-data/` is untouched, and confirm no permission, dependency, version, signing, or database-version changes.

- [x] **Step 4: Record device verification requirements**

Document the required 0.05/0.16 visual comparison and status-bar/navigation checks. If no device is connected, keep them explicitly pending.
