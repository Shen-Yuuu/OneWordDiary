# Historical Single Share Theme Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 单日分享还原日记保存时的主题，七日分享保持当前主题。

**Architecture:** `ShareViewModel.activePaperId` 根据分享模式选择历史单日主题或当前七日主题，分享页面继续只消费这一统一接口。卡片底层维持主题色直接绘制。

**Tech Stack:** HarmonyOS NEXT、ArkTS、ArkUI、Hypium、Hvigor

**Spec:** `docs/plans/2026-09-10-share-historical-single-theme-design.md`

## Global Constraints

- 不恢复固定 SVG 分享底图。
- 不修改记录中保存的主题字段。
- 不改变背景图片优先级和分享布局。

### Task 1: 恢复按模式选择主题

**Files:**
- Modify: `OneWord_dev/entry/src/main/ets/viewmodel/ShareViewModel.ets`
- Modify: `OneWord_dev/entry/src/test/ShareViewModel.test.ets`

- [ ] 修改 `activePaperId`：单日且存在记录时返回 `singleData.paperId`，否则返回 `sevenPaperId`。
- [ ] 测试当前瑰粉、历史素灰时，单日返回 `plain_ash_dev` 和 `#EFEFEA`。
- [ ] 测试切换到最近七日后返回 `rose_pink_dev` 和 `#F8E8EC`。

### Task 2: 验证与交付

**Files:**
- Create: `docs/testing/2026-09-10-share-historical-single-theme-acceptance.md`

- [ ] 运行 UnitTestArkTS 编译和相关测试。
- [ ] 运行 signed HAP 构建并要求 `BUILD SUCCESSFUL`。
- [ ] 运行 `git diff --check`，记录结果并提交为 `fix: restore historical theme for single shares`。
