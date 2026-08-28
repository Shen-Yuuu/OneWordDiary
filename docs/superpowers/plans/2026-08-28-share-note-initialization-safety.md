# Share Note Initialization Safety Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prevent the single-day share page from crashing during initial render while preserving reactive note visibility.

**Architecture:** Use one-way ArkUI props for read-only note visibility, derive layout from a boolean rather than a possibly unstable string, and make the pure note resolver total for nullish runtime input. Keep the opaque image surface and direct PNG export unchanged.

**Tech Stack:** HarmonyOS ArkTS, ArkUI state management, Hypium, Hvigor

**Spec:** `docs/plans/2026-08-28-share-note-initialization-safety-design.md`

## Global Constraints

- Do not modify persistence, schema, snapshot, or share-sheet logic.
- Keep opaque SVG card backgrounds.
- Do not reintroduce `renderRevision` or forced remounting.
- `resolveShareNoteText` must return a string for string, null, and undefined note input.

---

### Task 1: Null-safe note resolver

**Files:**
- Modify: `OneWord_dev/entry/src/main/ets/model/ShareModel.ets:18-22`
- Test: `OneWord_dev/entry/src/test/ShareViewModel.test.ets:102-110`

**Interfaces:**
- Consumes: `includeNote: boolean`, `kind: ShareDayKind`, `note: string | null | undefined`.
- Produces: `resolveShareNoteText(...): string` with no nullish return path.

- [ ] **Step 1: Add failing nullish-input assertions**

```ets
expect(resolveShareNoteText(true, ShareDayKind.WORD, null))
  .assertEqual('这条记录没有备注');
expect(resolveShareNoteText(true, ShareDayKind.WORD, undefined))
  .assertEqual('这条记录没有备注');
```

- [ ] **Step 2: Run the unit tests and confirm the new calls fail type checking or execution**

```powershell
$env:DEVECO_SDK_HOME='D:\local\DevEcoStudio\sdk'
& 'D:\local\DevEcoStudio\tools\hvigor\bin\hvigorw.bat' test --mode module -p module=entry@default -p product=default --no-daemon
```

Expected: the existing string-only signature rejects nullish input or the resolver fails the new assertion.

- [ ] **Step 3: Make the resolver total**

```ets
export function resolveShareNoteText(
  includeNote: boolean,
  kind: ShareDayKind,
  note: string | null | undefined
): string {
  if (!includeNote || kind === ShareDayKind.MISSING) {
    return '';
  }
  return note === null || note === undefined || note.length === 0 ?
    '这条记录没有备注' : note;
}
```

- [ ] **Step 4: Run tests and require `BUILD SUCCESSFUL`**

Use the command from Step 2.

### Task 2: Safe one-way note visibility

**Files:**
- Modify: `OneWord_dev/entry/src/main/ets/components/share/ShareSingleCard.ets:8-145`
- Modify: `OneWord_dev/entry/src/main/ets/components/share/ShareScrollCard.ets:11`
- Modify: `OneWord_dev/entry/src/main/ets/pages/SharePreviewPage.ets:103-121`

**Interfaces:**
- Consumes: parent `@State showNote: boolean`.
- Produces: child `@Prop includeNote: boolean = false` and `ShareSingleCard.shouldShowNote: boolean`.

- [ ] **Step 1: Replace read-only links with initialized props**

In both card components use:

```ets
@Prop includeNote: boolean = false;
```

- [ ] **Step 2: Pass concrete state values from the page**

Use `includeNote: this.showNote` for both `ShareSingleCard` and `ShareScrollCard`.

- [ ] **Step 3: Remove initial-render string dereferences from layout decisions**

Add to `ShareSingleCard`:

```ets
get shouldShowNote(): boolean {
  return this.includeNote === true;
}
```

Replace both height conditions and the note-area `if` condition with `this.shouldShowNote`. Keep `Text(this.visibleNote)` inside that guarded branch.

- [ ] **Step 4: Run the full unit-test task**

Use the Task 1 Step 2 command and require `BUILD SUCCESSFUL`.

- [ ] **Step 5: Build the debug HAP**

```powershell
$env:DEVECO_SDK_HOME='D:\local\DevEcoStudio\sdk'
& 'D:\local\DevEcoStudio\tools\hvigor\bin\hvigorw.bat' assembleHap --mode module -p module=entry@default -p product=default -p buildMode=debug --no-daemon
```

Expected: `BUILD SUCCESSFUL` and a refreshed `entry-default-unsigned.hap`.

### Task 3: Regression checks and commit

**Files:**
- Verify: `OneWord_dev/entry/src/main/ets/service/ShareImageService.ets`
- Verify: `OneWord_dev/entry/build/default/outputs/default/entry-default-unsigned.hap`

**Interfaces:**
- Consumes: the corrected card subtree.
- Produces: a device-installable debug HAP.

- [ ] **Step 1: Verify unsafe and obsolete paths are absent**

```powershell
rg -n "@Link includeNote|visibleNote\.length|renderRevision|createPixelMap|readPixels|writeBuffer" OneWord_dev/entry/src/main/ets
```

Expected: no card-state or PixelMap post-processing matches; direct snapshot packing remains.

- [ ] **Step 2: Commit the implementation**

```powershell
git add OneWord_dev/entry/src/main/ets/model/ShareModel.ets OneWord_dev/entry/src/test/ShareViewModel.test.ets OneWord_dev/entry/src/main/ets/components/share/ShareSingleCard.ets OneWord_dev/entry/src/main/ets/components/share/ShareScrollCard.ets OneWord_dev/entry/src/main/ets/pages/SharePreviewPage.ets
git commit -m "fix: make share note initialization safe"
```

- [ ] **Step 3: Device acceptance**

Install the new HAP. Enter single-day share with notes initially off, toggle notes on and off, switch to seven-day share, export both modes, and confirm there is no crash, notes update, and PNG backgrounds remain opaque.
