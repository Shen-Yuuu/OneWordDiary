# Share Note Link State Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the “展示备注” switch immediately update both single-day and seven-day share cards, including the component snapshot used for export.

**Architecture:** Keep `SharePreviewPage.@State showNote` as the sole source of truth and pass its V1 state wrapper to both child cards through `@Link`. Remove forced component recreation, resolve note text safely inside the single-day child, and preserve seven-day `ForEach` identity changes when the linked value changes.

**Tech Stack:** HarmonyOS ArkTS, ArkUI state management V1, Hypium, Hvigor

**Spec:** `docs/plans/2026-08-28-share-note-link-state-design.md`

## Global Constraints

- Do not change the solved share background or image export implementation.
- Do not log note contents; logs may include only mode, boolean state, item counts, and text lengths.
- `resolveShareNoteText` remains the only rule for real-note, empty-note, and missing-day display text.
- Preserve unrelated working-tree changes.

---

### Task 1: Connect both share cards directly to the page state

**Files:**
- Modify: `OneWord_dev/entry/src/main/ets/pages/SharePreviewPage.ets`
- Modify: `OneWord_dev/entry/src/main/ets/components/share/ShareSingleCard.ets`
- Modify: `OneWord_dev/entry/src/main/ets/components/share/ShareScrollCard.ets`
- Delete if still unreferenced: `OneWord_dev/entry/src/main/ets/model/ShareCardData.ets`
- Test: `OneWord_dev/entry/src/test/ShareViewModel.test.ets` (existing resolver coverage)

**Interfaces:**
- Consumes: `resolveShareNoteText(includeNote: boolean, kind: ShareDayKind, note: string | null | undefined): string`
- Produces: `ShareSingleCard.includeNote: @Link boolean`, `ShareScrollCard.includeNote: @Link boolean`
- Produces: parent bindings `includeNote: $showNote`

- [ ] **Step 1: Confirm the regression and safety coverage**

Inspect the current page and verify that it contains `refreshKey`, `.key(...)`, and ordinary note props. Inspect `ShareViewModel.test.ets` and verify it already asserts null/undefined fallback behavior:

```ets
expect(resolveShareNoteText(true, ShareDayKind.WORD, null)).assertEqual('这条记录没有备注');
expect(resolveShareNoteText(true, ShareDayKind.WORD, undefined)).assertEqual('这条记录没有备注');
```

Expected: source inspection confirms the UI binding regression while pure note resolution already has automated coverage.

- [ ] **Step 2: Replace forced recreation with a linked state binding**

In `SharePreviewPage.ets`, remove `refreshKey`, `singleNoteText`, the unused `RecordType`/`ShareDayKind`/`ShareCardData` imports, and `.key(...)`. Pass the state wrapper and raw note:

```ets
ShareSingleCard({
  includeNote: $showNote,
  localDate: this.viewModel.singleData.localDate,
  recordType: this.viewModel.singleData.recordType,
  content: this.viewModel.singleData.content,
  note: this.viewModel.singleData.note,
  fontId: this.viewModel.singleData.fontId,
  paperId: this.viewModel.singleData.paperId
})

ShareScrollCard({
  days: this.viewModel.sevenDays,
  includeNote: $showNote,
  fontId: this.viewModel.sevenFontId,
  paperId: this.viewModel.sevenPaperId
})
```

Keep one switch log without the note content:

```ets
console.info(`SharePreviewPage note toggle: mode=${this.selectedMode}, before=${this.showNote}, after=${isOn}`);
this.showNote = isOn;
```

- [ ] **Step 3: Make the single-day component derive text from the linked value**

Replace `@Prop noteText` with these properties and getters:

```ets
@Link includeNote: boolean;
@Prop note: string = '';

get visibleNote(): string {
  const kind = this.recordType === RecordType.WORD ? ShareDayKind.WORD : ShareDayKind.BLANK;
  return resolveShareNoteText(this.includeNote, kind, this.note);
}

get shouldShowNote(): boolean {
  return this.visibleNote.length > 0;
}
```

Render `Text(this.visibleNote)`. Add lifecycle/change diagnostics that print only `includeNote`, `note.length`, and `visibleNote.length`.

- [ ] **Step 4: Make the seven-day component observe the same linked value**

Change the declaration to:

```ets
@Link includeNote: boolean;
```

Retain the existing key generator so each record node is recreated from a fresh `ScrollDisplayItem` when the switch changes:

```ets
(item: ShareDayItem): string =>
  `${item.localDate}-${this.includeNote ? 'notes-on' : 'notes-off'}`
```

Add one aggregate diagnostic method/log that reports `includeNote`, `days.length`, and the number of non-missing days; never print `item.note`.

- [ ] **Step 5: Remove the abandoned model only if it has no references**

Run:

```powershell
rg -n "ShareCardData" OneWord_dev/entry/src/main/ets
```

Expected: only `ShareCardData.ets` itself remains. Delete that untracked file. If another real consumer exists, keep the file and remove only the unused page import.

- [ ] **Step 6: Run the existing unit tests**

Run from `OneWord_dev`:

```powershell
$env:DEVECO_SDK_HOME='D:\local\DevEcoStudio\sdk'
& 'D:\local\DevEcoStudio\tools\hvigor\bin\hvigorw.bat' test --mode module -p module=entry@default -p product=default --no-daemon
```

Expected: Hypium share note resolution tests pass. If the Windows test-report process remains alive after reporting task success, terminate only that task process and record the limitation.

- [ ] **Step 7: Compile the application**

Run from `OneWord_dev`:

```powershell
$env:DEVECO_SDK_HOME='D:\local\DevEcoStudio\sdk'
& 'D:\local\DevEcoStudio\tools\hvigor\bin\hvigorw.bat' assembleHap --mode module -p module=entry@default -p product=default -p buildMode=debug --no-daemon
```

Expected: `BUILD SUCCESSFUL` and `entry/build/default/outputs/default/entry-default-unsigned.hap` is produced.

- [ ] **Step 8: Review the scoped diff**

Run:

```powershell
git diff --check
git diff -- OneWord_dev/entry/src/main/ets/pages/SharePreviewPage.ets OneWord_dev/entry/src/main/ets/components/share/ShareSingleCard.ets OneWord_dev/entry/src/main/ets/components/share/ShareScrollCard.ets
```

Expected: no whitespace errors; no background/image-service changes; no note body in logs; no `refreshKey` or `.key(...)` remains.

- [ ] **Step 9: Commit only the scoped implementation**

```powershell
git add -- OneWord_dev/entry/src/main/ets/pages/SharePreviewPage.ets OneWord_dev/entry/src/main/ets/components/share/ShareSingleCard.ets OneWord_dev/entry/src/main/ets/components/share/ShareScrollCard.ets
git commit -m "fix: link share note visibility state"
```

If the untracked `ShareCardData.ets` was deleted before ever being tracked, it requires no staging. Do not stage `ShareImageService.ets`, background assets, `OneWord_dev/docs`, or `imge`.

### Task 2: Device acceptance for preview and exported snapshot

**Files:**
- Verify artifact: `OneWord_dev/entry/build/default/outputs/default/entry-default-unsigned.hap`
- No source modifications expected

**Interfaces:**
- Consumes: the linked `showNote` state implemented in Task 1
- Produces: device evidence that screen preview and component snapshot share the same note visibility

- [ ] **Step 1: Verify single-day preview**

Open a word record that has a note, enter single-day sharing, and toggle “展示备注” on and off.

Expected: the note appears below the main word when on and disappears when off; the app does not crash; the log reports matching before/after values and nonzero display length.

- [ ] **Step 2: Verify single-day empty-note fallback**

Open a recorded day whose note is empty and turn the switch on.

Expected: `这条记录没有备注` appears; missing/undefined data never causes a `.length` exception.

- [ ] **Step 3: Verify seven-day preview**

Switch to “最近七日” and toggle notes on and off.

Expected: recorded days show their note or fallback when on; missing days show no note; timeline and card height adjust without black frames, color parsing errors, or jank caused by component recreation.

- [ ] **Step 4: Verify export parity**

With notes on, export one single-day image and one seven-day image.

Expected: both exported images contain the same note text shown in the preview; the previously solved opaque background remains unchanged.

