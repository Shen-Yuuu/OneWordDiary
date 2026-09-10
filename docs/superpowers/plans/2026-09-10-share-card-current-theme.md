# Share Card Current Theme Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让单日和最近七日分享图片完整使用用户当前选择的主题色板。

**Architecture:** 分享 ViewModel 继续读取当前设置主题；页面将当前 `paperId` 同时传给两类分享卡片。卡片移除覆盖主题色的不透明固定 SVG，使用 `styleForPaper()` 的背景、文字、强调色和分隔线直接绘制。

**Tech Stack:** HarmonyOS NEXT、ArkTS、ArkUI、Hypium、Hvigor

**Spec:** `docs/plans/2026-09-10-share-card-current-theme-design.md`

## Global Constraints

- 单日和七日分享统一使用当前设置主题。
- 上传背景图片优先显示，失败时回退当前主题纯色。
- 不改变分享布局、尺寸、文案或快照分享流程。

---

### Task 1: 统一分享主题来源

**Files:**
- Modify: `OneWord_dev/entry/src/main/ets/pages/SharePreviewPage.ets`
- Modify: `OneWord_dev/entry/src/test/ShareViewModel.test.ets`

**Interfaces:**
- Consumes: `ShareViewModel.sevenPaperId`，它由当前 `SettingsRepository` 主题生成
- Produces: 单日和七日卡片共享的当前主题 `paperId`

- [ ] 在 `ShareViewModel.test.ets` 增加当前瑰粉主题被解析为 `rose_pink_dev` 的断言，同时确认单日记录原有 `paperId` 不改变持久化数据。
- [ ] 将 `ShareSingleCard.paperId` 从 `singleData.paperId` 改为页面当前 `paperId`；七日卡片维持当前主题输入。
- [ ] 检查页面快照外层也使用相同 `paperId`。

### Task 2: 删除固定背景覆盖层

**Files:**
- Modify: `OneWord_dev/entry/src/main/ets/components/share/ShareSingleCard.ets`
- Modify: `OneWord_dev/entry/src/main/ets/components/share/ShareScrollCard.ets`

**Interfaces:**
- Consumes: `styleForPaper(paperId).light`
- Produces: 完整使用主题色板的分享卡片

- [ ] 删除两个组件的 `paperBackground()` 方法。
- [ ] 删除两个组件 Stack 中的固定 `Image(share_bg_*)`。
- [ ] 保留卡片根 Stack 的主题 `backgroundColor` 与 `divider` 边框。
- [ ] 确认单日 `DiaryBackground` 仍位于主题底色上方。

### Task 3: 验证和交付

**Files:**
- Create: `docs/testing/2026-09-10-share-card-current-theme-acceptance.md`

**Interfaces:**
- Consumes: Tasks 1–2 的实现
- Produces: signed HAP 与验收记录

- [ ] 运行 `hvigorw test --mode module -p module=entry@default`，确认 UnitTestArkTS 编译通过并记录运行器结果。
- [ ] 运行 `hvigorw assembleHap --mode module -p module=entry@default -p product=default`，要求 `BUILD SUCCESSFUL`。
- [ ] 运行 `git diff --check` 并检查仅修改本任务文件。
- [ ] 记录六种主题、单日和七日一致性、图片回退及产物路径。
- [ ] 提交为 `fix: apply current theme to share cards`。
