# Share Card Rendering Recovery Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore opaque single-day and seven-day share cards and make note visibility update both preview and exported PNG.

**Architecture:** Render paper color as an opaque image-content layer inside each share card instead of relying on shape/modifier backgrounds. Bind the page's `showNote` state directly into each card with `@Link`, resolve note copy inside the card, and remove the revision-driven remount workaround.

**Tech Stack:** HarmonyOS ArkTS, ArkUI declarative components, SVG media resources, Hypium, Hvigor

**Spec:** `docs/plans/2026-08-28-share-card-rendering-recovery-design.md`

## Global Constraints

- Preserve PNG output and existing share dimensions.
- Do not modify diary persistence, schema, or stored records.
- Do not add full-resolution PixelMap allocation or pixel rewriting.
- Use paper colors `#FDF8F7` for `warm_paper_dev` and `#F7F7F5` for `plain_ash_dev`.
- Keep `waitUntilRenderFinished: true` for component snapshots.

---

### Task 1: Opaque share-card media surfaces

**Files:**
- Create: `OneWord_dev/entry/src/main/resources/base/media/share_bg_warm.svg`
- Create: `OneWord_dev/entry/src/main/resources/base/media/share_bg_plain.svg`
- Modify: `OneWord_dev/entry/src/main/ets/components/share/ShareSingleCard.ets`
- Modify: `OneWord_dev/entry/src/main/ets/components/share/ShareScrollCard.ets`

**Interfaces:**
- Consumes: existing `paperId: string` and exact card dimensions.
- Produces: `paperBackground: Resource`, selecting `app.media.share_bg_warm` or `app.media.share_bg_plain`.

- [ ] **Step 1: Confirm the current regression source**

Run:

```powershell
rg -n "Rect\(|\.fill\(|backgroundColor" OneWord_dev/entry/src/main/ets/components/share/ShareSingleCard.ets OneWord_dev/entry/src/main/ets/components/share/ShareScrollCard.ets
```

Expected: both cards contain a full-card `Rect(...).fill(...)` background.

- [ ] **Step 2: Add fully opaque paper resources**

Create `share_bg_warm.svg`:

```xml
<svg xmlns="http://www.w3.org/2000/svg" width="1" height="1" viewBox="0 0 1 1">
  <rect width="1" height="1" fill="#FDF8F7"/>
</svg>
```

Create `share_bg_plain.svg` with the same geometry and `fill="#F7F7F5"`.

- [ ] **Step 3: Replace shape backgrounds with image content**

In each card, add:

```ets
get paperBackground(): Resource {
  return this.paperId === 'plain_ash_dev' ?
    $r('app.media.share_bg_plain') : $r('app.media.share_bg_warm');
}
```

Replace the full-card `Rect` with:

```ets
Image(this.paperBackground)
  .width(286)
  .height(cardHeight)
  .objectFit(ImageFit.Fill)
```

Use `440` for `ShareSingleCard` and `this.cardHeight` for `ShareScrollCard`.

- [ ] **Step 4: Build the resource and component changes**

Run:

```powershell
$env:DEVECO_SDK_HOME='D:\local\DevEcoStudio\sdk'
& 'D:\local\DevEcoStudio\tools\hvigor\bin\hvigorw.bat' assembleHap --mode module -p module=entry@default -p product=default -p buildMode=debug --no-daemon
```

Expected: `BUILD SUCCESSFUL` and `entry-default-unsigned.hap` is produced.

- [ ] **Step 5: Commit the opaque surface**

```powershell
git add OneWord_dev/entry/src/main/resources/base/media/share_bg_warm.svg OneWord_dev/entry/src/main/resources/base/media/share_bg_plain.svg OneWord_dev/entry/src/main/ets/components/share/ShareSingleCard.ets OneWord_dev/entry/src/main/ets/components/share/ShareScrollCard.ets
git commit -m "fix: render opaque share card surfaces"
```

### Task 2: Direct note-state binding

**Files:**
- Modify: `OneWord_dev/entry/src/main/ets/pages/SharePreviewPage.ets`
- Modify: `OneWord_dev/entry/src/main/ets/components/share/ShareSingleCard.ets`
- Modify: `OneWord_dev/entry/src/main/ets/components/share/ShareScrollCard.ets`
- Test: `OneWord_dev/entry/src/test/ShareViewModel.test.ets`

**Interfaces:**
- Consumes: `@State showNote: boolean` in `SharePreviewPage`, raw single note string, and `ShareDayItem.note`.
- Produces: `@Link includeNote: boolean` in both cards and `visibleNote: string` in `ShareSingleCard`.

- [ ] **Step 1: Run the focused note-data tests before UI changes**

Run:

```powershell
$env:DEVECO_SDK_HOME='D:\local\DevEcoStudio\sdk'
& 'D:\local\DevEcoStudio\tools\hvigor\bin\hvigorw.bat' test --mode module -p module=entry@default -p product=default --no-daemon
```

Expected: the `showsNoteAreaForRecordedDaysOnlyWhenEnabled`, `resolvesVisibleNoteCopyBeforeRendering`, and historical-note mapping assertions pass. If the test runner remains alive after reporting the unit-test task complete, stop it and record that runner issue separately from assertion results.

- [ ] **Step 2: Bind single-day note visibility directly**

Replace `displayNote` with raw `note` and a link:

```ets
@Link includeNote: boolean;
@Prop note: string = '';

get visibleNote(): string {
  const kind = this.recordType === RecordType.WORD ? ShareDayKind.WORD : ShareDayKind.BLANK;
  return resolveShareNoteText(this.includeNote, kind, this.note);
}
```

Use `visibleNote` for height decisions and note text.

- [ ] **Step 3: Bind seven-day note visibility directly**

Change `ShareScrollCard.includeNote` from `@Prop` to:

```ets
@Link includeNote: boolean;
```

Keep the node key suffix `${this.includeNote ? 'notes-on' : 'notes-off'}` so node height and note text are reconstructed together.

- [ ] **Step 4: Remove revision-based remounting from the page**

Delete `renderRevision`, its increments, the single-element `ForEach`, and the duplicated true/false builder branches. Pass the link and raw note once:

```ets
ShareSingleCard({
  includeNote: $showNote,
  note: this.viewModel.singleData.note
})

ShareScrollCard({
  includeNote: $showNote
})
```

Keep the switch handler limited to `this.showNote = isOn`.

- [ ] **Step 5: Run tests and build**

Run the Hypium command from Step 1, then the `assembleHap` command from Task 1 Step 4.

Expected: note-data assertions pass and the HAP build reports `BUILD SUCCESSFUL`.

- [ ] **Step 6: Commit reactive note rendering**

```powershell
git add OneWord_dev/entry/src/main/ets/pages/SharePreviewPage.ets OneWord_dev/entry/src/main/ets/components/share/ShareSingleCard.ets OneWord_dev/entry/src/main/ets/components/share/ShareScrollCard.ets
git commit -m "fix: bind share note visibility directly"
```

### Task 3: Final static and device acceptance

**Files:**
- Verify: `OneWord_dev/entry/src/main/ets/service/ShareImageService.ets`
- Verify: `OneWord_dev/entry/build/default/outputs/default/entry-default-unsigned.hap`

**Interfaces:**
- Consumes: `SHARE_CARD_COMPONENT_ID` and the rendered card subtree.
- Produces: an opaque PNG shared through the existing system share controller.

- [ ] **Step 1: Verify the export path remains direct and bounded**

Run:

```powershell
rg -n "getComponentSnapshot|waitUntilRenderFinished|packToFile|createPixelMap|readPixels|writeBuffer" OneWord_dev/entry/src/main/ets/service/ShareImageService.ets
```

Expected: one component snapshot is packed directly to PNG; no second PixelMap or pixel-buffer rewrite exists.

- [ ] **Step 2: Verify obsolete redraw and shape paths are absent**

Run:

```powershell
rg -n "renderRevision|Rect\(|\.fill\(" OneWord_dev/entry/src/main/ets/pages/SharePreviewPage.ets OneWord_dev/entry/src/main/ets/components/share/ShareSingleCard.ets OneWord_dev/entry/src/main/ets/components/share/ShareScrollCard.ets
```

Expected: no matches.

- [ ] **Step 3: Check the worktree and final build artifact**

Run:

```powershell
git status --short
Get-Item OneWord_dev/entry/build/default/outputs/default/entry-default-unsigned.hap | Select-Object FullName,Length,LastWriteTime
```

Expected: only intentional plan bookkeeping is present and the HAP has a fresh timestamp.

- [ ] **Step 4: Perform device acceptance**

Install the debug HAP and verify: single-day preview is paper-colored; seven-day preview is paper-colored; switching notes changes card layout/text immediately; exported single-day and seven-day PNGs preserve the same note state; external image viewers show an opaque warm/plain background rather than transparency or black.

