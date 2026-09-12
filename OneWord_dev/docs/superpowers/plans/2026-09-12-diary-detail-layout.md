# Diary Detail Layout Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Place record status, notes, dates, and privacy content at the requested visual positions without changing diary data or navigation behavior.

**Architecture:** Keep page-level placement in the existing ArkUI components. `TodayRecordCard` owns the post-submit action/status relationship; `DetailRecordContent` owns the detail date/share relationship; `DiaryHeroContent` is the shared note typography source; `PrivacyPage` owns its scroll content alignment.

**Tech Stack:** HarmonyOS NEXT, ArkTS, ArkUI declarative UI, Hvigor.

**Spec:** User request in the Codex task dated 2026-09-12.

## Global Constraints

- Keep all existing diary content, revision behavior, share callbacks, and accessibility text functional.
- Use resource-based text colors so dark mode remains legible while notes are black on the light paper.
- Verify with the debug HAP build command used by this project.

---

### Task 1: Reflow the post-submit action status

**Files:**
- Modify: `entry/src/main/ets/components/diary/TodayRecordCard.ets`
- Test: debug HAP build

**Interfaces:**
- Consumes: existing `canRevise`, `finalLabel`, `onRevise`, and `onShare` properties.
- Produces: finalized status immediately above the share action, and revision status immediately above the revise action.

- [ ] **Step 1: Place the revision status inside the revision action column**

Replace the standalone revision label with a nested `Column` that places `Text('尚可修订 1 次')` directly before `DiaryPrimaryButton({ label: '修订今日' })`.

- [ ] **Step 2: Remove the deadline copy**

Do not interpolate `revisionDeadline`; the visible revision label must be exactly `尚可修订 1 次`.

- [ ] **Step 3: Place the finalized label above the share button**

Wrap the finalized label and `DiaryIconButton` in a `Column({ space: 10 })`, so `Text(this.finalLabel)` sits directly above the share action.

- [ ] **Step 4: Build the debug HAP**

Run:

```powershell
$env:DEVECO_SDK_HOME='D:\local\DevEcoStudio\sdk'
& 'D:\local\DevEcoStudio\tools\hvigor\bin\hvigorw.bat' assembleHap --mode module -p module=entry@default -p product=default -p buildMode=debug --no-daemon
```

Expected: `BUILD SUCCESSFUL`.

### Task 2: Standardize note and detail-date placement

**Files:**
- Modify: `entry/src/main/ets/components/common/DiaryHeroContent.ets`
- Modify: `entry/src/main/ets/components/diary/TodayConfirmation.ets`
- Modify: `entry/src/main/ets/components/scroll/ScrollRecordNode.ets`
- Modify: `entry/src/main/ets/components/detail/DetailRecordContent.ets`
- Test: debug HAP build

**Interfaces:**
- Consumes: existing `note`, `dateLabel`, and `DiaryHeroContent` properties.
- Produces: primary-color notes and a date label at the top of detail content.

- [ ] **Step 1: Use the primary text resource for notes**

In `DiaryHeroContent.build()` and `TodayConfirmation.build()`, replace displayed-note `fontColor` values with `$r('app.color.text_primary')`; in `ScrollRecordNode.noteContent()`, use `this.textColor()`. Retain each component's existing font size and line height.

- [ ] **Step 2: Move the date label before the hero content**

In `DetailRecordContent.build()`, render `Text(this.dateLabel)` before `DiaryHeroContent`, with an explicit bottom margin. Remove the current date label after the hero content.

- [ ] **Step 3: Preserve accessibility labels**

Keep `dateLabel` in the existing `accessibilityText` branches; moving visual order must not remove date information from screen reader output.

- [ ] **Step 4: Build the debug HAP**

Run the Hvigor command from Task 1. Expected: `BUILD SUCCESSFUL`.

### Task 3: Anchor privacy content at the top

**Files:**
- Modify: `entry/src/main/ets/pages/PrivacyPage.ets`
- Test: debug HAP build

**Interfaces:**
- Consumes: existing privacy item builders and the `Scroll` container.
- Produces: top-aligned privacy information within the remaining page height.

- [ ] **Step 1: Declare start alignment on the scroll content column**

Add `.justifyContent(FlexAlign.Start)` to the `Column` inside `Scroll()` and preserve its current top padding.

- [ ] **Step 2: Build the debug HAP**

Run the Hvigor command from Task 1. Expected: `BUILD SUCCESSFUL`.

### Task 4: Review the completed layout

**Files:**
- Review: `entry/src/main/ets/components/diary/TodayRecordCard.ets`
- Review: `entry/src/main/ets/components/common/DiaryHeroContent.ets`
- Review: `entry/src/main/ets/components/detail/DetailRecordContent.ets`
- Review: `entry/src/main/ets/pages/PrivacyPage.ets`

**Interfaces:**
- Consumes: the completed visual layout changes.
- Produces: a concise handoff with the exact margin/padding controls for later vertical tuning.

- [ ] **Step 1: Inspect the final diff**

Run `git diff --` for the four modified files and verify that no persistence, reminder, or navigation code was changed.

- [ ] **Step 2: Report adjustment points**

Document the final `margin`/`space` controls: revision status margin in `TodayRecordCard.build()`, final-label/share column space in `TodayRecordCard.build()`, date bottom margin in `DetailRecordContent.build()`, and note `fontSize` in `DiaryHeroContent.build()`.
