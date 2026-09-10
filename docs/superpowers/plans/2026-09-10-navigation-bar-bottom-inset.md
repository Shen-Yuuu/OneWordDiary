# Navigation Bar Bottom Inset Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为所有沉浸式页面的前景内容提供统一 32vp 底部导航条避让。

**Architecture:** 背景层继续通过安全区扩展覆盖系统栏；前景页面根容器同时应用顶部和底部资源尺寸，保持一处定义、全局一致。

**Tech Stack:** HarmonyOS NEXT、ArkTS、ArkUI、Hvigor

**Spec:** `docs/plans/2026-09-10-navigation-bar-bottom-inset-design.md`

## Global Constraints

- 底部前景避让固定为 32vp。
- 不关闭沉浸式窗口，不修改背景安全区扩展。
- 不改变顶部 32vp 内容偏移。

### Task 1: 新增尺寸并覆盖前景页面

**Files:**
- Modify: `OneWord_dev/entry/src/main/resources/base/element/float.json`
- Modify: `OneWord_dev/entry/src/main/ets/pages/Index.ets`
- Modify: `OneWord_dev/entry/src/main/ets/components/diary/TodayConfirmation.ets`
- Modify: `OneWord_dev/entry/src/main/ets/pages/ScrollPage.ets`
- Modify: `OneWord_dev/entry/src/main/ets/pages/DetailPage.ets`
- Modify: `OneWord_dev/entry/src/main/ets/pages/SharePreviewPage.ets`
- Modify: `OneWord_dev/entry/src/main/ets/pages/SettingsPage.ets`
- Modify: `OneWord_dev/entry/src/main/ets/pages/BackupPage.ets`
- Modify: `OneWord_dev/entry/src/main/ets/pages/PrivacyPage.ets`

- [ ] 在 `float.json` 添加 `immersive_bottom_content_offset`，值为 `32vp`。
- [ ] 在主页和确认页前景根容器增加资源化 bottom padding。
- [ ] 在所有 NavDestination 前景根容器增加相同 bottom padding。
- [ ] 确认 `PaperBackdrop` 与 `DiaryBackground` 未应用该 padding。

### Task 2: 构建与验收

**Files:**
- Create: `docs/testing/2026-09-10-navigation-bar-bottom-inset-acceptance.md`

- [ ] 运行资源和 ArkTS 编译。
- [ ] 构建 signed HAP 并要求 `BUILD SUCCESSFUL`。
- [ ] 静态检查全部目标页面引用统一底部尺寸。
- [ ] 运行 `git diff --check`，记录验收并提交。
