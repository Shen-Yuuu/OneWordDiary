# Remove Share Note Feature Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove all note controls and note rendering from single-day and seven-day sharing while preserving diary note data elsewhere.

**Architecture:** The preview page will stop owning note visibility state. Both card components will stop accepting note-visibility inputs and will construct their existing layouts with no note region. The share-only resolver helpers and tests will be removed once no code references them.

**Tech Stack:** HarmonyOS ArkTS, ArkUI, Hypium, Hvigor

**Spec:** `docs/plans/2026-08-28-remove-share-note-feature-design.md`

## Global Constraints

- Do not modify `DailyRecord.note`, editor, detail, or other non-share note behavior.
- Do not modify the solved background or `ShareImageService` export path.
- Both share modes must always omit note text and the empty-note fallback copy.
- Preserve unrelated uncommitted working-tree changes.

---

### Task 1: Remove the preview control and card-level note rendering

**Files:**
- Modify: `OneWord_dev/entry/src/main/ets/pages/SharePreviewPage.ets`
- Modify: `OneWord_dev/entry/src/main/ets/components/share/ShareSingleCard.ets`
- Modify: `OneWord_dev/entry/src/main/ets/components/share/ShareScrollCard.ets`

**Interfaces:**
- Removes: `SharePreviewPage.showNote: boolean`
- Removes: `ShareSingleCard.includeNote`, `ShareSingleCard.note`
- Removes: `ShareScrollCard.includeNote`

- [ ] **Step 1: Remove page state and visible control**

Delete the state declaration, the `Row` containing `Text('展示备注')` and `Toggle`, and the status text under the share card. Remove the two `includeNote: $showNote` arguments and the `showNote` value in share diagnostics.

The resulting card construction has no note-specific parameter:

```ets
ShareSingleCard({
  localDate: this.viewModel.singleData.localDate,
  recordType: this.viewModel.singleData.recordType,
  content: this.viewModel.singleData.content,
  fontId: this.viewModel.singleData.fontId,
  paperId: this.viewModel.singleData.paperId
})
```

- [ ] **Step 2: Remove single-day card note logic**

Delete the `includeNote` and `note` properties, `visibleNote`, `rawNoteLength`, `shouldShowNote`, note diagnostics, and the conditional note `Column`.

Restore the main content region to a fixed height:

```ets
.height(292)
```

for both the word and blank branches.

- [ ] **Step 3: Remove seven-day card note logic**

Delete `@Link includeNote` and its diagnostics. In `displayItem`, construct each `ScrollDisplayItem` with the existing default note arguments omitted, so `note === ''` and `showNote === false`.

Calculate timeline height without note state:

```ets
height += ScrollLayoutMetrics.totalHeight(
  item.kind === ShareDayKind.MISSING,
  false,
  item.showMonthHeader
);
```

Use a stable date-only `ForEach` key:

```ets
(item: ShareDayItem): string => item.localDate
```

- [ ] **Step 4: Review scope**

Run:

```powershell
rg -n "showNote|includeNote|展示备注|分享图已展示备注|分享图不展示备注|visibleNote|rawNoteLength" OneWord_dev/entry/src/main/ets
```

Expected: no results in the share preview or share card components.

### Task 2: Remove share-only helpers and validate

**Files:**
- Modify: `OneWord_dev/entry/src/main/ets/model/ShareModel.ets`
- Modify: `OneWord_dev/entry/src/test/ShareViewModel.test.ets`

**Interfaces:**
- Removes: `shouldShowShareDayNote(includeNote: boolean, kind: ShareDayKind): boolean`
- Removes: `resolveShareNoteText(includeNote: boolean, kind: ShareDayKind, note: string | null | undefined): string`

- [ ] **Step 1: Remove obsolete model helpers**

Delete both helper functions from `ShareModel.ets`; retain `ShareDayKind`, `ShareSingleData.note`, and `ShareDayItem.note` because they remain part of diary/share data loading.

- [ ] **Step 2: Remove only helper-specific tests and imports**

In `ShareViewModel.test.ets`, remove `resolveShareNoteText` and `shouldShowShareDayNote` imports and delete the tests named `showsNoteAreaForRecordedDaysOnlyWhenEnabled` and `resolvesVisibleNoteCopyBeforeRendering`. Keep tests proving historical note data is loaded into `singleData` and `sevenDays`.

- [ ] **Step 3: Compile and run tests**

Run:

```powershell
$env:DEVECO_SDK_HOME='D:\local\DevEcoStudio\sdk'
& 'D:\local\DevEcoStudio\tools\hvigor\bin\hvigorw.bat' test --mode module -p module=entry@default -p product=default --no-daemon
& 'D:\local\DevEcoStudio\tools\hvigor\bin\hvigorw.bat' assembleHap --mode module -p module=entry@default -p product=default -p buildMode=debug --no-daemon
```

Expected: no ArkTS reference errors; HAP packaging succeeds. If the existing Windows test runner stops at `Windows_NT` without a report, record that runner limitation after the test compilation step finishes.

- [ ] **Step 4: Commit scoped implementation**

```powershell
git add -- OneWord_dev/entry/src/main/ets/pages/SharePreviewPage.ets OneWord_dev/entry/src/main/ets/components/share/ShareSingleCard.ets OneWord_dev/entry/src/main/ets/components/share/ShareScrollCard.ets OneWord_dev/entry/src/main/ets/model/ShareModel.ets OneWord_dev/entry/src/test/ShareViewModel.test.ets
git commit -m "refactor: remove share note feature"
```

Do not stage unrelated `ShareImageService.ets`, `OneWord_dev/docs`, `imge`, or the untracked `ShareCardData.ets`.

