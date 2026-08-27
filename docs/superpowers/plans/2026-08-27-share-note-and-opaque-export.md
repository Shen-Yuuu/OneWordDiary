# Share Note and Opaque Export Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make notes render reliably in both share modes and export PNG files whose pixels are fully opaque over the active home-paper color.

**Architecture:** Replace boolean-driven note branches with a resolved display string shared by single-day and seven-day cards. Add a focused, pure pixel composer that flattens RGBA/BGRA snapshot bytes over a typed RGB fallback before Image Kit creates the PNG PixelMap.

**Tech Stack:** HarmonyOS NEXT, ArkTS, ArkUI V1 state management, Image Kit, Share Kit, Hypium, Hvigor.

**Spec:** `docs/plans/2026-08-27-share-note-and-opaque-export-design.md`

## Global Constraints

- Fix note display in both single-day and recent-seven-day share modes.
- Recorded days with note display the real note; recorded days without note display `这条记录没有备注`; missing days display no note area.
- Paper-ink exports flatten over `#FDF8F7`; plain-ash exports flatten over `#F7F7F5`.
- The encoded file remains PNG and every output pixel has alpha 255.
- Do not add dependencies, permissions, persistence, network access, or diary-data mutations.
- Keep the snapshot path compatible with a future background image rendered beneath share content.

---

### Task 1: Resolve Note Copy Before Rendering

**Files:**
- Modify: `OneWord_dev/entry/src/main/ets/model/ShareModel.ets`
- Modify: `OneWord_dev/entry/src/test/ShareViewModel.test.ets`

**Interfaces:**
- Consumes: `includeNote: boolean`, `kind: ShareDayKind`, and raw `note: string`.
- Produces: `resolveShareNoteText(includeNote: boolean, kind: ShareDayKind, note: string): string`.

- [ ] **Step 1: Write failing note-resolution tests**

Add assertions covering enabled real note, enabled fallback copy, disabled note, and missing day:

```typescript
expect(resolveShareNoteText(true, ShareDayKind.WORD, '晚风很好')).assertEqual('晚风很好');
expect(resolveShareNoteText(true, ShareDayKind.WORD, '')).assertEqual('这条记录没有备注');
expect(resolveShareNoteText(false, ShareDayKind.WORD, '晚风很好')).assertEqual('');
expect(resolveShareNoteText(true, ShareDayKind.MISSING, 'ignored')).assertEqual('');
```

- [ ] **Step 2: Run local tests and verify the new symbol fails**

Run from `OneWord_dev`:

```powershell
$env:DEVECO_SDK_HOME='D:\local\DevEcoStudio\sdk'
& 'D:\local\DevEcoStudio\tools\hvigor\bin\hvigorw.bat' test --mode module -p module=entry@default -p product=default -p buildMode=debug --no-daemon
```

Expected: compilation fails because `resolveShareNoteText` is not exported.

- [ ] **Step 3: Implement the resolver**

```typescript
export function resolveShareNoteText(includeNote: boolean, kind: ShareDayKind, note: string): string {
  if (!includeNote || kind === ShareDayKind.MISSING) {
    return '';
  }
  return note.length > 0 ? note : '这条记录没有备注';
}
```

- [ ] **Step 4: Run tests and verify they pass**

Run the Task 1 test command. Expected: `BUILD SUCCESSFUL`.

### Task 2: Drive Both Share Cards with Resolved Text

**Files:**
- Modify: `OneWord_dev/entry/src/main/ets/components/share/ShareSingleCard.ets`
- Modify: `OneWord_dev/entry/src/main/ets/components/share/ShareScrollCard.ets`
- Modify: `OneWord_dev/entry/src/main/ets/components/scroll/ScrollRecordNode.ets`
- Modify: `OneWord_dev/entry/src/main/ets/pages/ScrollPage.ets`
- Modify: `OneWord_dev/entry/src/main/ets/pages/SharePreviewPage.ets`

**Interfaces:**
- Consumes: `resolveShareNoteText(...)` from Task 1.
- Produces: `ShareSingleCard.displayNote: string` and `ScrollRecordNode.noteText: string`; an empty string means no note area.

- [ ] **Step 1: Remove boolean note ownership from the leaf components**

In `ShareSingleCard`, replace `note` and `showNote` props with:

```typescript
@Prop displayNote: string = '';
```

Use `this.displayNote.length > 0` for the compact content height and note branch, and render `Text(this.displayNote)` directly.

In `ScrollRecordNode`, remove `noteVisible` and add:

```typescript
get shouldShowNote(): boolean {
  return this.noteText.length > 0;
}
```

Use `shouldShowNote` for node height, total height, note branches, and accessibility text.

- [ ] **Step 2: Pass only final display text from callers**

In `ScrollPage` preserve long-scroll behavior:

```typescript
noteText: item.showNote ? item.note : '',
```

In `ShareScrollCard`, resolve once per item and use the resolved value for `ScrollDisplayItem`, `ScrollRecordNode.noteText`, timeline height, and the `ForEach` key.

In `SharePreviewPage`, map the single record type to `ShareDayKind.WORD` or `ShareDayKind.BLANK`, then pass either the resolved text in the enabled branch or `''` in the disabled branch.

- [ ] **Step 3: Compile the UI changes**

```powershell
$env:DEVECO_SDK_HOME='D:\local\DevEcoStudio\sdk'
& 'D:\local\DevEcoStudio\tools\hvigor\bin\hvigorw.bat' assembleHap --mode module -p module=entry@default -p product=default -p buildMode=debug --no-daemon
```

Expected: `BUILD SUCCESSFUL`.

### Task 3: Flatten Snapshot Pixels over the Home Paper Color

**Files:**
- Create: `OneWord_dev/entry/src/main/ets/utils/OpaquePixelComposer.ets`
- Create: `OneWord_dev/entry/src/test/OpaquePixelComposer.test.ets`
- Modify: `OneWord_dev/entry/src/test/List.test.ets`
- Modify: `OneWord_dev/entry/src/main/ets/service/ShareImageService.ets`
- Modify: `OneWord_dev/entry/src/main/ets/pages/SharePreviewPage.ets`
- Modify: `OneWord_dev/AppScope/app.json5`

**Interfaces:**
- Produces: `RgbColor`, `PixelByteOrder`, and `OpaquePixelComposer.flatten(source, width, height, stride, order, premultiplied, background): ArrayBuffer`.
- Consumes: the component snapshot PixelMap plus paper-ink RGB `(253, 248, 247)` or plain-ash RGB `(247, 247, 245)`.

- [ ] **Step 1: Write failing pure pixel tests**

Test that a transparent RGBA pixel becomes the fallback color, an opaque pixel is preserved, a half-alpha pixel is blended, BGRA channels are reordered to RGBA, row padding is skipped, and every output alpha byte equals 255.

Register the new suite in `List.test.ets`.

- [ ] **Step 2: Run tests and verify the composer is missing**

Run the Task 1 test command. Expected: compilation fails because `OpaquePixelComposer` is not implemented.

- [ ] **Step 3: Implement the pure composer**

Use an explicit loop over `height`, `width`, source `stride`, and four-byte pixels. For non-premultiplied input:

```typescript
Math.round((sourceChannel * alpha + backgroundChannel * (255 - alpha)) / 255)
```

For premultiplied input:

```typescript
Math.min(255, Math.round(sourceChannel + backgroundChannel * (255 - alpha) / 255))
```

Always write RGBA output with alpha 255.

- [ ] **Step 4: Integrate with Image Kit**

In `ShareImageService.shareCard`, accept `background: RgbColor`, read `ImageInfo`, read `stride * height` bytes, flatten RGBA_8888 or BGRA_8888, and create an opaque RGBA_8888 PixelMap:

```typescript
const opaquePixelMap = await image.createPixelMap(opaqueBytes, {
  size: imageInfo.size,
  srcPixelFormat: image.PixelMapFormat.RGBA_8888,
  pixelFormat: image.PixelMapFormat.RGBA_8888,
  alphaType: image.AlphaType.OPAQUE,
  editable: false
});
```

Encode only `opaquePixelMap`, and release both PixelMaps in `finally` blocks.

In `SharePreviewPage`, pass the active home-paper RGB to `shareCard`.

- [ ] **Step 5: Bump the patch version**

Set:

```json5
"versionCode": 1000009,
"versionName": "1.0.9",
```

- [ ] **Step 6: Run full tests and final Debug build**

Run the Task 1 test command and Task 2 build command. Expected: both report `BUILD SUCCESSFUL`.

- [ ] **Step 7: Check and commit**

Run `git diff --check`, review the diff, and commit only the files listed in this plan with:

```powershell
git commit -m "fix: show share notes and export opaque pngs"
```

### Task 4: Local Emulator Verification

**Files:**
- Verify: `OneWord_dev/entry/build/default/outputs/default/entry-default-unsigned.hap`

**Interfaces:**
- Consumes: version 1.0.9 Debug HAP.
- Produces: visual confirmation without mutating diary data.

- [ ] **Step 1: Install and launch on Local Emulator**

Use DevEco Studio Run with `Local Emulator` or install the built HAP with `hdc install -r` when the emulator is connected.

- [ ] **Step 2: Verify notes**

Toggle `展示备注` in both modes. Confirm real notes or fallback copy appear, disappear when disabled, and seven-day nodes remain aligned.

- [ ] **Step 3: Verify exported alpha**

Share both modes to an image-capable target. Confirm the unopened preview and opened image both show the active home-paper background. A future custom background rendered inside the card remains visible because flattening only resolves remaining transparency.
