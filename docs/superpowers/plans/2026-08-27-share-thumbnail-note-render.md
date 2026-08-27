# Share Thumbnail and Seven-Day Note Rendering Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce a usable system-share preview thumbnail and make seven-day notes render immediately when the toggle is enabled.

**Architecture:** Remove the custom low-resolution thumbnail and let Share Kit derive its preview from the valid PNG. Replace nested-object note reactivity with primitive ArkUI props, and use explicit conditional branches so the seven-day timeline subtree is recreated when note visibility changes.

**Tech Stack:** HarmonyOS NEXT, ArkTS, ArkUI V1 state management, Image Kit, Share Kit, Hypium, Hvigor.

**Spec:** `docs/plans/2026-08-27-share-thumbnail-note-render-design.md`

## Global Constraints

- Keep the shared file format as PNG.
- Do not add dependencies, permissions, persistence, network access, or diary-data mutations.
- Recorded days show the real note or `这条记录没有备注` when enabled.
- Missing days never show a note area.
- Local ArkTS tests and Debug HAP compilation must pass.

---

### Task 1: Drive Timeline Notes with Primitive Props

**Files:**
- Modify: `OneWord_dev/entry/src/main/ets/components/scroll/ScrollRecordNode.ets`
- Modify: `OneWord_dev/entry/src/main/ets/pages/ScrollPage.ets`
- Modify: `OneWord_dev/entry/src/main/ets/components/share/ShareScrollCard.ets`

**Interfaces:**
- Consumes: `ScrollDisplayItem.note`, `ScrollDisplayItem.showNote`, and `shouldShowShareDayNote(includeNote, kind)`.
- Produces: `ScrollRecordNode.noteVisible: boolean` and `ScrollRecordNode.noteText: string`.

- [ ] **Step 1: Confirm the current nested-field dependency**

Run:

```powershell
rg -n "item\.showNote|item\.note" OneWord_dev/entry/src/main/ets/components/scroll/ScrollRecordNode.ets
```

Expected: height, conditional rendering, visible copy, and accessibility all depend on fields nested inside the `item` prop.

- [ ] **Step 2: Add primitive note props**

Add to `ScrollRecordNode`:

```typescript
@Prop noteVisible: boolean = false;
@Prop noteText: string = '';
```

Use `noteVisible` in `nodeHeight`, `totalHeight`, both note conditionals, and accessibility copy. Resolve note copy with:

```typescript
get visibleNote(): string {
  return this.noteText.length > 0 ? this.noteText : '这条记录没有备注';
}
```

- [ ] **Step 3: Give note text deterministic geometry**

Extract a note builder used by word and blank records:

```typescript
@Builder
private noteContent(textAlign: TextAlign) {
  Text(this.visibleNote)
    .width(104)
    .height(28)
    .fontSize(10)
    .lineHeight(14)
    .fontFamily(this.recordFontFamily)
    .fontColor(this.secondaryColor)
    .maxLines(2)
    .textAlign(textAlign)
    .minFontScale(1)
    .maxFontScale(1)
}
```

- [ ] **Step 4: Pass the primitive props from both callers**

In `ScrollPage`, pass:

```typescript
noteVisible: item.showNote,
noteText: item.note,
```

In `ShareScrollCard`, pass:

```typescript
noteVisible: shouldShowShareDayNote(this.includeNote, item.kind),
noteText: item.note,
```

- [ ] **Step 5: Compile after the component API change**

Run from `OneWord_dev`:

```powershell
$env:DEVECO_SDK_HOME='D:\local\DevEcoStudio\sdk'
& 'D:\local\DevEcoStudio\tools\hvigor\bin\hvigorw.bat' assembleHap --mode module -p module=entry@default -p product=default -p buildMode=debug --no-daemon
```

Expected: `BUILD SUCCESSFUL`.

### Task 2: Force Seven-Day Branch Replacement

**Files:**
- Modify: `OneWord_dev/entry/src/main/ets/pages/SharePreviewPage.ets`
- Modify: `OneWord_dev/entry/src/main/ets/components/share/ShareScrollCard.ets`

**Interfaces:**
- Consumes: page state `showNote: boolean` and `renderRevision: number`.
- Produces: a newly created seven-day card subtree for each note visibility state.

- [ ] **Step 1: Split the seven-day render branch**

Replace the single seven-day component call with explicit branches:

```typescript
if (this.showNote) {
  ShareScrollCard({
    days: this.viewModel.sevenDays,
    includeNote: true,
    revision: this.renderRevision,
    fontId: this.viewModel.sevenFontId,
    paperId: this.viewModel.sevenPaperId
  })
} else {
  ShareScrollCard({
    days: this.viewModel.sevenDays,
    includeNote: false,
    revision: this.renderRevision,
    fontId: this.viewModel.sevenFontId,
    paperId: this.viewModel.sevenPaperId
  })
}
```

- [ ] **Step 2: Make node keys include visibility explicitly**

Use a key containing the literal state:

```typescript
`${item.localDate}-${this.includeNote ? 'notes-on' : 'notes-off'}-${this.revision}`
```

- [ ] **Step 3: Run the local test suite**

```powershell
$env:DEVECO_SDK_HOME='D:\local\DevEcoStudio\sdk'
& 'D:\local\DevEcoStudio\tools\hvigor\bin\hvigorw.bat' test --mode module -p module=entry@default -p product=default -p buildMode=debug --no-daemon
```

Expected: all tests PASS, including the recorded/blank/missing note visibility rule.

### Task 3: Remove the Faulty Custom Thumbnail

**Files:**
- Modify: `OneWord_dev/entry/src/main/ets/service/ShareImageService.ets`
- Modify: `OneWord_dev/AppScope/app.json5`

**Interfaces:**
- Consumes: the high-resolution component `PixelMap`.
- Produces: one PNG URI shared without a custom `thumbnail`; app version `1.0.8` / `1000008`.

- [ ] **Step 1: Remove the second snapshot and JPEG packer**

Delete `thumbnailPixelMap`, `thumbnailPacker`, `thumbnailBuffer`, and their release calls. Keep the existing high-resolution PNG `packToFile` path.

- [ ] **Step 2: Omit thumbnail from SharedData**

Construct the record as:

```typescript
const sharedData = new systemShare.SharedData({
  utd: imageUtd,
  uri: fileUri.getUriFromPath(filePath),
  title: '一字日记',
  description: '一天一字，一年成诗。'
});
```

- [ ] **Step 3: Bump the patch version**

```json5
"versionCode": 1000008,
"versionName": "1.0.8",
```

- [ ] **Step 4: Run tests and build the final Debug HAP**

Run the test command from Task 2 and the build command from Task 1. Expected: both finish with `BUILD SUCCESSFUL`.

### Task 4: Runtime Verification and Commit

**Files:**
- Verify: `OneWord_dev/entry/build/default/outputs/default/entry-default-unsigned.hap`

**Interfaces:**
- Consumes: the version 1.0.8 Debug HAP and an active Local Emulator.
- Produces: visual evidence for note rendering and receiver thumbnail compatibility.

- [ ] **Step 1: Install and launch on Local Emulator**

Install the new HAP with `hdc install -r`, then launch `com.oneword.diary/EntryAbility`.

- [ ] **Step 2: Verify the seven-day toggle**

Open `分享预览 → 最近七日`, toggle notes off/on/off, and confirm:

- real notes and fallback copy appear only when enabled;
- missing dates remain compact;
- dates, axis, and footer do not overlap.

- [ ] **Step 3: Verify the received image preview**

Share both a single-day and seven-day image to an external image-capable app. Confirm the unexpanded preview uses the original light paper image and the opened PNG remains clear.

- [ ] **Step 4: Commit**

```powershell
git add OneWord_dev/AppScope/app.json5 OneWord_dev/entry/src/main/ets/components/scroll/ScrollRecordNode.ets OneWord_dev/entry/src/main/ets/components/share/ShareScrollCard.ets OneWord_dev/entry/src/main/ets/pages/ScrollPage.ets OneWord_dev/entry/src/main/ets/pages/SharePreviewPage.ets OneWord_dev/entry/src/main/ets/service/ShareImageService.ets
git commit -m "fix: render seven-day notes and share usable previews"
```
