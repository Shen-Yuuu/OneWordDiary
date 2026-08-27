# Share Card Black Rect Regression Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove the oversized black Shape from share previews and exported PNG files while retaining a fully painted homepage-colored card background.

**Architecture:** The preview page stops creating a percentage-sized Shape. Each share card paints its own background with an explicitly sized `Rect`, using the same width and height values already owned by that component, so ArkUI measurement and component snapshots use one geometry source.

**Tech Stack:** HarmonyOS NEXT, ArkTS, ArkUI Shape/Stack, ImageKit, Hypium, Hvigor

**Spec:** `docs/plans/2026-08-27-share-card-black-rect-regression-design.md`

## Global Constraints

- Single-day card size remains exactly `286vp × 440vp`.
- Seven-day card width remains exactly `286vp`; height remains `cardHeight`.
- Paper-and-ink snapshot background is exactly `#FDF8F7`.
- Plain-ash snapshot background is exactly `#F7F7F5`.
- `ShareImageService` continues direct PixelMap-to-PNG packing.
- Run build commands from `OneWord_dev`.

---

### Task 1: Move the painted background into the card components

**Files:**
- Modify: `OneWord_dev/entry/src/main/ets/pages/SharePreviewPage.ets`
- Modify: `OneWord_dev/entry/src/main/ets/components/share/ShareSingleCard.ets`
- Modify: `OneWord_dev/entry/src/main/ets/components/share/ShareScrollCard.ets`

**Interfaces:**
- Consumes: `paperId`, `ShareSingleCard` fixed height `440`, and `ShareScrollCard.cardHeight`.
- Produces: card roots whose exact measured bounds are fully painted before `SHARE_CARD_COMPONENT_ID` is captured.

- [ ] **Step 1: Confirm the failing source pattern**

Run:

```powershell
rg -n -U "Rect\(\)\s*\.width\('100%'\)\s*\.height\('100%'\)" entry/src/main/ets/pages/SharePreviewPage.ets
```

Expected before the fix: the command reports the percentage-sized `Rect` in `shareCard()`.

- [ ] **Step 2: Remove the page-level percentage Shape**

Delete only this block from `SharePreviewPage.shareCard()`:

```typescript
Rect()
  .width('100%')
  .height('100%')
  .fill(this.activePaperColor)
```

Keep the `Stack`, `ForEach`, component ID, and existing `backgroundColor` modifier unchanged.

- [ ] **Step 3: Give the single-day card an exact painted layer**

Change `ShareSingleCard.paperColor` to the homepage colors:

```typescript
get paperColor(): string {
  return this.paperId === 'plain_ash_dev' ? '#F7F7F5' : '#FDF8F7';
}
```

In `build()`, replace the initial root `Column() {` with a `Stack() {`, add the exact Shape below as the first child, then start a new `Column() {` immediately before the existing date `Text`. The existing date `Text`, 292vp content `Column`, and app footer `Row` remain children of that new inner `Column` in their current order.

```typescript
Stack() {
  Rect({ width: 286, height: 440 })
    .fill(this.paperColor)
}
.width(286)
.height(440)
.border({ width: 1, color: this.paperId === 'plain_ash_dev' ? '#E5E5E2' : '#EEE5E1' })
.borderRadius(2)
```

Keep `.width(286)`, `.height(440)`, and `.alignItems(HorizontalAlign.Center)` on the inner `Column`. Move the existing border and radius modifiers to the outer `Stack`, and remove the inner `Column` background modifier so the explicit `Rect` is the only background owner.

- [ ] **Step 4: Give the seven-day card an exact dynamic painted layer**

Change `ShareScrollCard.paperColor` to the same homepage colors. In `build()`, replace the initial root `Column() {` with a `Stack() {`, add the exact Shape below as the first child, then start a new `Column() {` immediately before the existing timeline `Column`. The timeline and footer remain children of that inner `Column` in their current order.

```typescript
Stack() {
  Rect({ width: 286, height: this.cardHeight })
    .fill(this.paperColor)
}
.width(286)
.height(this.cardHeight)
.border({ width: 1, color: this.paperId === 'plain_ash_dev' ? '#E5E5E2' : '#EEE5E1' })
.borderRadius(2)
```

Keep `.width(286)`, `.height(this.cardHeight)`, and `.alignItems(HorizontalAlign.Center)` on the inner `Column`. Move the existing border and radius modifiers to the outer `Stack`, remove the inner `Column` background modifier, and do not duplicate or move the `timelineHeight` and `cardHeight` calculations.

- [ ] **Step 5: Confirm the failing pattern is gone**

Run the Step 1 command again.

Expected after the fix: no matches and exit code `1` from `rg`.

### Task 2: Compile and package the regression fix

**Files:**
- Verify: `OneWord_dev/entry/build/default/outputs/default/entry-default-unsigned.hap`

**Interfaces:**
- Consumes: the three modified ArkUI files from Task 1.
- Produces: a compilable Debug HAP for device verification.

- [ ] **Step 1: Run source and whitespace checks**

Run:

```powershell
git diff --check
rg -n "OpaquePixelComposer|createOpaquePixelMap" entry/src/main/ets
```

Expected: both searches produce no obsolete pixel-composer references and `git diff --check` prints nothing.

- [ ] **Step 2: Run the module tests**

Run:

```powershell
$env:DEVECO_SDK_HOME='D:\local\DevEcoStudio\sdk'
& 'D:\local\DevEcoStudio\tools\hvigor\bin\hvigorw.bat' test --mode module -p module=entry@default -p product=default -p buildMode=debug --no-daemon
```

Expected: `BUILD SUCCESSFUL`.

- [ ] **Step 3: Build the Debug HAP**

Run:

```powershell
$env:DEVECO_SDK_HOME='D:\local\DevEcoStudio\sdk'
& 'D:\local\DevEcoStudio\tools\hvigor\bin\hvigorw.bat' assembleHap --mode module -p module=entry@default -p product=default -p buildMode=debug --no-daemon
```

Expected: `BUILD SUCCESSFUL` and `entry/build/default/outputs/default/entry-default-unsigned.hap` exists.

- [ ] **Step 4: Commit the fix**

```powershell
git add entry/src/main/ets/pages/SharePreviewPage.ets entry/src/main/ets/components/share/ShareSingleCard.ets entry/src/main/ets/components/share/ShareScrollCard.ets
git commit -m "fix: size share card backgrounds explicitly"
```

- [ ] **Step 5: Perform device acceptance**

Verify all four preview states: single-day, seven-day, seven-day notes off, and seven-day notes on. Export each style once and confirm there is no black block, card geometry matches the preview, notes remain visible, and all PNG corners use the selected homepage paper color.
