# Seven-Day Share Notes and Stable Export Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show notes reliably in the seven-day share card and export shareable PNG files with the homepage paper color as an opaque visual background.

**Architecture:** Make `ScrollDisplayItem` the only note-presentation state consumed by `ScrollRecordNode`. Paint the paper color inside each captured card before taking the component snapshot, then restore the proven direct PixelMap-to-PNG packing path instead of rebuilding pixels in memory.

**Tech Stack:** HarmonyOS NEXT, ArkTS, ArkUI, ImageKit, ShareKit, Hypium, Hvigor

**Spec:** `docs/plans/2026-08-27-share-seven-day-note-stable-export-design.md`

## Global Constraints

- Keep PNG as the exported image format.
- Paper-and-ink background is exactly `#FDF8F7`.
- Plain-ash background is exactly `#F7F7F5`.
- Missing dates never render a note area.
- Do not introduce dynamic ArkTS types or new dependencies.

---

### Task 1: Make the timeline item the only note-rendering state

**Files:**
- Modify: `OneWord_dev/entry/src/main/ets/components/scroll/ScrollRecordNode.ets`
- Modify: `OneWord_dev/entry/src/main/ets/components/share/ShareScrollCard.ets`
- Modify: `OneWord_dev/entry/src/main/ets/pages/ScrollPage.ets`
- Test: `OneWord_dev/entry/src/test/ShareViewModel.test.ets`

**Interfaces:**
- Consumes: `ScrollDisplayItem.note: string`, `ScrollDisplayItem.showNote: boolean`, and `resolveShareNoteText(includeNote, kind, note): string`.
- Produces: `ScrollRecordNode({ item, isInteractive, onOpen })` with no independent note property.

- [ ] **Step 1: Strengthen the existing note-presentation regression test**

Add the assertion below to `resolvesVisibleNoteCopyBeforeRendering` so whitespace-free real notes remain the exact text carried into the display item:

```typescript
const visibleNote = resolveShareNoteText(true, ShareDayKind.WORD, '晚风很好');
expect(visibleNote.length > 0).assertTrue();
expect(visibleNote).assertEqual('晚风很好');
```

- [ ] **Step 2: Run the share test suite before the UI change**

Run:

```powershell
./hvigorw.bat test --mode module -p module=entry@default -p product=default
```

Expected: the current data-level tests pass; this establishes that the defect is in ArkUI state consumption rather than RDB loading or note resolution.

- [ ] **Step 3: Remove the duplicate note property from `ScrollRecordNode`**

Replace the node's note accessors with the immutable item state:

```typescript
get visibleNote(): string {
  return this.item.note;
}

get shouldShowNote(): boolean {
  return this.item.showNote && this.item.note.length > 0;
}
```

Delete `@Prop noteText`. In both call sites, stop passing `noteText`; `ShareScrollCard.displayItem()` already creates a `ScrollDisplayItem` with the final text and visibility.

- [ ] **Step 4: Make seven-day node identity follow the render revision**

Use this key in `ShareScrollCard`:

```typescript
(item: ShareDayItem): string => `${item.localDate}-${this.includeNote ? 'notes-on' : 'notes-off'}-${this.revision}`
```

This ensures toggling the switch recreates nodes whose immutable `ScrollDisplayItem` has changed.

- [ ] **Step 5: Run the share tests and compile the module**

Run the test command from Step 2, then:

```powershell
./hvigorw.bat assembleHap --mode module -p module=entry@default -p product=default -p buildMode=debug --no-daemon
```

Expected: tests pass and `BUILD SUCCESSFUL` is printed.

- [ ] **Step 6: Commit the timeline fix**

```powershell
git add OneWord_dev/entry/src/main/ets/components/scroll/ScrollRecordNode.ets OneWord_dev/entry/src/main/ets/components/share/ShareScrollCard.ets OneWord_dev/entry/src/main/ets/pages/ScrollPage.ets OneWord_dev/entry/src/test/ShareViewModel.test.ets
git commit -m "fix: render seven-day share notes from item state"
```

### Task 2: Paint the snapshot background and restore direct PNG packing

**Files:**
- Modify: `OneWord_dev/entry/src/main/ets/components/share/ShareSingleCard.ets`
- Modify: `OneWord_dev/entry/src/main/ets/components/share/ShareScrollCard.ets`
- Modify: `OneWord_dev/entry/src/main/ets/pages/SharePreviewPage.ets`
- Modify: `OneWord_dev/entry/src/main/ets/service/ShareImageService.ets`
- Modify: `OneWord_dev/entry/src/test/List.test.ets`
- Delete: `OneWord_dev/entry/src/main/ets/utils/OpaquePixelComposer.ets`
- Delete: `OneWord_dev/entry/src/test/OpaquePixelComposer.test.ets`

**Interfaces:**
- Consumes: the captured ArkUI component identified by `SHARE_CARD_COMPONENT_ID`.
- Produces: `shareCard(uiContext, context, componentId, fileName): Promise<void>` and a directly packed PNG whose card bounds are fully painted.

- [ ] **Step 1: Paint a complete paper layer in each share card**

Use homepage paper colors in both card components:

```typescript
get paperColor(): string {
  return this.paperId === 'plain_ash_dev' ? '#F7F7F5' : '#FDF8F7';
}
```

Wrap each existing content `Column` in a fixed-size `Stack` and put an unrounded shape beneath it:

```typescript
Stack() {
  Rect({ width: 286, height: this.cardHeight })
    .fill(this.paperColor)

  Column() {
    // Existing card content remains unchanged.
  }
  .width(286)
  .height(this.cardHeight)
}
.width(286)
.height(this.cardHeight)
```

For `ShareSingleCard`, use height `440`; for `ShareScrollCard`, use `this.cardHeight`. Apply the border to the outer `Stack`, and do not round or clip the background layer.

- [ ] **Step 2: Restore the direct image export service**

Change the method signature back to:

```typescript
async shareCard(
  uiContext: UIContext,
  context: common.UIAbilityContext,
  componentId: string,
  fileName: string
): Promise<void>
```

Pack the snapshot directly:

```typescript
const pixelMap = await uiContext.getComponentSnapshot().get(componentId, {
  scale: 3,
  waitUntilRenderFinished: true
});
const file = fileIo.openSync(
  filePath,
  fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.TRUNC
);
const packer = image.createImagePacker();
try {
  await packer.packToFile(pixelMap, file.fd, {
    format: 'image/png',
    quality: 100
  });
} finally {
  fileIo.closeSync(file);
  await packer.release();
  await pixelMap.release();
}
```

Remove `createOpaquePixelMap`, its imports, the `background` argument, and the `shareBackgroundColor` getter/import from `SharePreviewPage`.

- [ ] **Step 3: Remove obsolete pixel-composer code and test registration**

Delete `OpaquePixelComposer.ets` and `OpaquePixelComposer.test.ets`. Remove these two lines from `List.test.ets`:

```typescript
import opaquePixelComposerTest from './OpaquePixelComposer.test';
opaquePixelComposerTest();
```

- [ ] **Step 4: Run static checks**

Run:

```powershell
git diff --check
rg -n "OpaquePixelComposer|RgbColor|createOpaquePixelMap|noteText" OneWord_dev/entry/src
```

Expected: `git diff --check` prints nothing; the search finds no obsolete production references.

- [ ] **Step 5: Run tests and build Debug HAP**

Run:

```powershell
./hvigorw.bat test --mode module -p module=entry@default -p product=default
./hvigorw.bat assembleHap --mode module -p module=entry@default -p product=default -p buildMode=debug --no-daemon
```

Expected: all tests pass and the build prints `BUILD SUCCESSFUL`.

- [ ] **Step 6: Commit the stable export fix**

```powershell
git add OneWord_dev/entry/src/main/ets/components/share/ShareSingleCard.ets OneWord_dev/entry/src/main/ets/components/share/ShareScrollCard.ets OneWord_dev/entry/src/main/ets/pages/SharePreviewPage.ets OneWord_dev/entry/src/main/ets/service/ShareImageService.ets OneWord_dev/entry/src/main/ets/utils/OpaquePixelComposer.ets OneWord_dev/entry/src/test/List.test.ets OneWord_dev/entry/src/test/OpaquePixelComposer.test.ets
git commit -m "fix: export share cards with painted backgrounds"
```

### Task 3: Final regression verification

**Files:**
- Verify: `OneWord_dev/entry/build/default/outputs/default/entry-default-signed.hap`

**Interfaces:**
- Consumes: completed Tasks 1 and 2.
- Produces: a build artifact and a clean repository state suitable for device verification.

- [ ] **Step 1: Verify repository state and artifact**

Run:

```powershell
git status --short
Get-ChildItem -LiteralPath 'OneWord_dev/entry/build/default/outputs/default' -Filter '*.hap'
```

Expected: no uncommitted source changes remain after commits, and at least one Debug HAP is listed.

- [ ] **Step 2: Perform the device acceptance flow**

On a device or emulator:

1. Open 分享预览 and select 最近七日.
2. Turn 展示备注 on, verify real notes and no-note placeholders appear, and verify missing dates remain compact.
3. Turn 展示备注 off and on again, verifying the card and 卷尾 reflow each time.
4. Share both single-day and seven-day cards in paper-and-ink and plain-ash styles.
5. Verify the system share sheet opens and each PNG has the expected solid homepage paper color, including all four corners.

- [ ] **Step 3: Record any device-only failure with the exact system log**

If the system share sheet still fails, capture the exact ImageKit or ShareKit error code from DevEco Studio Log and keep the working direct-pack implementation unchanged until that platform-specific error is identified.
