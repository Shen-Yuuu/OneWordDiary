# Scroll Date Alignment and Seven-Day Note Response Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Align hollow-node dates with vermilion-node dates and make the seven-day share note toggle visibly update every recorded day.

**Architecture:** Keep the existing `ScrollRecordNode` and `ShareScrollCard` component boundaries. Centralize the seven-day note visibility rule in the share model so node construction and height calculation cannot diverge, then remove the hollow-date-only text padding that causes the visual offset.

**Tech Stack:** HarmonyOS NEXT, ArkTS, ArkUI V1 state management, Hypium, Hvigor.

**Spec:** `docs/plans/2026-08-27-scroll-date-note-response-design.md`

## Global Constraints

- Phone-only HarmonyOS 1.0 scope remains unchanged.
- Do not add dependencies, permissions, persistence, network access, or diary-data mutations.
- Missing dates never render a note area.
- An enabled note toggle renders the real note or `这条记录没有备注` for every recorded date.
- Build and local tests must pass before emulator verification.

---

### Task 1: Centralize Seven-Day Note Visibility

**Files:**
- Modify: `OneWord_dev/entry/src/main/ets/model/ShareModel.ets`
- Modify: `OneWord_dev/entry/src/test/ShareViewModel.test.ets`

**Interfaces:**
- Consumes: `ShareDayKind` and the share page's `includeNote: boolean` state.
- Produces: `shouldShowShareDayNote(includeNote: boolean, kind: ShareDayKind): boolean`.

- [ ] **Step 1: Write the failing rule test**

Import `shouldShowShareDayNote` in `ShareViewModel.test.ets` and add:

```typescript
it('showsNoteAreaForRecordedDaysOnlyWhenEnabled', 0, () => {
  expect(shouldShowShareDayNote(true, ShareDayKind.WORD)).assertTrue();
  expect(shouldShowShareDayNote(true, ShareDayKind.BLANK)).assertTrue();
  expect(shouldShowShareDayNote(true, ShareDayKind.MISSING)).assertFalse();
  expect(shouldShowShareDayNote(false, ShareDayKind.WORD)).assertFalse();
});
```

- [ ] **Step 2: Run tests and verify the missing export fails**

Run from `OneWord_dev`:

```powershell
& 'D:\local\DevEcoStudio\tools\hvigor\bin\hvigorw.bat' test --mode module -p module=entry@default -p product=default -p buildMode=debug --no-daemon
```

Expected: FAIL because `shouldShowShareDayNote` is not exported.

- [ ] **Step 3: Implement the shared rule**

Append to `ShareModel.ets`:

```typescript
export function shouldShowShareDayNote(includeNote: boolean, kind: ShareDayKind): boolean {
  return includeNote && kind !== ShareDayKind.MISSING;
}
```

- [ ] **Step 4: Run tests and verify the rule passes**

Run the same Hvigor test command. Expected: all local tests PASS.

### Task 2: Apply the Rule and Align Date Labels

**Files:**
- Modify: `OneWord_dev/entry/src/main/ets/components/share/ShareScrollCard.ets`
- Modify: `OneWord_dev/entry/src/main/ets/components/scroll/ScrollRecordNode.ets`

**Interfaces:**
- Consumes: `shouldShowShareDayNote(includeNote, item.kind)`.
- Produces: matching `ScrollDisplayItem.showNote` and `timelineHeight` decisions; common visible date boundary for solid, blank, and missing nodes.

- [ ] **Step 1: Use the shared note rule for node construction**

Import the helper and replace the note decision in `displayItem`:

```typescript
const showNote = shouldShowShareDayNote(this.includeNote, item.kind);
const note = showNote ? item.note : '';
```

Pass `showNote` to `ScrollDisplayItem` instead of `note.length > 0`. This lets `ScrollRecordNode.visibleNote` render the real note or its existing fallback copy.

- [ ] **Step 2: Use the same rule for card height**

Replace the height condition with:

```typescript
height += ScrollLayoutMetrics.totalHeight(
  item.kind === ShareDayKind.MISSING,
  shouldShowShareDayNote(this.includeNote, item.kind),
  item.showMonthHeader
);
```

- [ ] **Step 3: Remove hollow-date-only padding**

In both `blankContent()` and `missingContent()`, keep the same font size, color and letter spacing but remove:

```typescript
.backgroundColor(this.paperColor)
.padding({ left: 8, right: 8 })
```

The outer content column already provides identical `12vp` left/right padding.

- [ ] **Step 4: Compile the Debug HAP**

Run from `OneWord_dev`:

```powershell
$env:DEVECO_SDK_HOME='D:\local\DevEcoStudio\sdk'
& 'D:\local\DevEcoStudio\tools\hvigor\bin\hvigorw.bat' assembleHap --mode module -p module=entry@default -p product=default -p buildMode=debug --no-daemon
```

Expected: `BUILD SUCCESSFUL` with the debug HAP generated.

### Task 3: Version and Runtime Verification

**Files:**
- Modify: `OneWord_dev/AppScope/app.json5`

**Interfaces:**
- Consumes: completed ArkTS fixes and generated Debug HAP.
- Produces: application version `1.0.7` / `1000007` and runtime evidence for both fixes.

- [ ] **Step 1: Bump the patch version**

Set:

```json5
"versionCode": 1000007,
"versionName": "1.0.7",
```

- [ ] **Step 2: Re-run local tests and Debug build**

Run the Task 1 test command and Task 2 build command. Expected: both PASS.

- [ ] **Step 3: Install and launch on Local Emulator**

Use `hdc install -r` for `entry-default-unsigned.hap`, then launch `com.oneword.diary/EntryAbility`.

- [ ] **Step 4: Verify date alignment**

Open `文字长卷` and compare a left-side vermilion node with a hollow node. Their date text must share the same visible right boundary relative to the central axis.

- [ ] **Step 5: Verify note response**

Open `分享预览` → `最近七日`, enable `展示备注`, and confirm:

- the switch and status copy change immediately;
- recorded days show their real note or `这条记录没有备注`;
- missing days remain compact without a note area;
- disabling the switch removes all note areas and returns the card to compact heights.

- [ ] **Step 6: Commit the implementation**

```powershell
git add OneWord_dev/entry/src/main/ets/model/ShareModel.ets OneWord_dev/entry/src/main/ets/components/share/ShareScrollCard.ets OneWord_dev/entry/src/main/ets/components/scroll/ScrollRecordNode.ets OneWord_dev/entry/src/test/ShareViewModel.test.ets OneWord_dev/AppScope/app.json5 docs/superpowers/plans/2026-08-27-scroll-date-note-response.md
git commit -m "fix: align scroll dates and reveal seven-day notes"
```
