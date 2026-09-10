# Minimal Copy and Reminder Retirement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 精简备份、隐私和设置页面的非必要文案，隐藏提醒入口，并在应用启动时可靠停用历史提醒。

**Architecture:** 页面层只保留操作与必要风险信息。新增独立的 `ReminderRetirementService`，在服务容器初始化时取消系统提醒并把持久化状态改为关闭；失败采用尽力而为策略，绝不阻塞应用启动。

**Tech Stack:** HarmonyOS NEXT、ArkTS、ArkUI、Preferences、Reminder Agent、Hypium、Hvigor

**Spec:** `docs/plans/2026-09-10-minimal-copy-reminder-retirement-design.md`

## Global Constraints

- 不修改日记、备注、背景、分享、主题或备份文件格式。
- 保留提醒底层接口、设置字段与现有实现，供未来重新设计。
- 不移除通知权限声明，隐藏功能不再主动申请权限。
- 保留 `SettingsPage.ets` 中用户未提交的“瑰粉/瑰”修改。
- 错误、不可逆操作与未加密备份仍需提供必要提示。

---

### Task 1: 启动时停用历史提醒

**Files:**
- Create: `OneWord_dev/entry/src/main/ets/service/ReminderRetirementService.ets`
- Create: `OneWord_dev/entry/src/test/ReminderRetirementService.test.ets`
- Modify: `OneWord_dev/entry/src/test/List.test.ets`
- Modify: `OneWord_dev/entry/src/main/ets/service/AppServiceContainer.ets`

**Interfaces:**
- Consumes: `SettingsRepository.load()`, `SettingsRepository.saveReminder(ReminderSettings)`, `ReminderScheduler.cancelAll()`
- Produces: `ReminderRetirementService.retire(): Promise<void>`

- [ ] **Step 1: 编写失败测试**

覆盖三个行为：已开启提醒会调用 `cancelAll()` 并保存 `enabled: false` 与 `reminderId: -1`；默认关闭状态也保持幂等；`cancelAll()` 抛错时仍保存关闭状态且 `retire()` 正常返回。把测试套件注册到 `List.test.ets`。

- [ ] **Step 2: 运行测试并确认新服务尚不存在**

Run: `cd OneWord_dev; hvigorw test --mode module -p module=entry@default`

Expected: FAIL，提示无法解析 `ReminderRetirementService`。

- [ ] **Step 3: 实现停用服务**

实现构造函数：

```ts
constructor(settingsRepository: SettingsRepository, reminderScheduler: ReminderScheduler)
```

`retire()` 先加载设置，再尽力调用 `cancelAll()`；无论系统取消是否成功，都保存以下状态：

```ts
{
  enabled: false,
  hour: settings.reminder.hour,
  minute: settings.reminder.minute,
  reminderId: -1,
  permissionRequested: settings.reminder.permissionRequested
}
```

系统取消失败只写日志。设置读取或保存失败也由服务内部记录，避免阻塞启动。

- [ ] **Step 4: 接入服务容器初始化**

在 `AppServiceContainer.initialize()` 完成中断清空恢复后创建并 `await` 新服务的 `retire()`，随后继续其他初始化。该调用必须位于 `loadContent` 之前，确保旧提醒在应用启动时尽早取消。

- [ ] **Step 5: 运行相关测试**

Run: `cd OneWord_dev; hvigorw test --mode module -p module=entry@default`

Expected: 新增测试和既有设置测试 PASS。

---

### Task 2: 隐藏设置页提醒界面并精简提示

**Files:**
- Modify: `OneWord_dev/entry/src/main/ets/pages/SettingsPage.ets`

**Interfaces:**
- Consumes: 既有 `SettingsViewModel` 的主题、备份、隐私和清空数据能力
- Produces: 不包含提醒入口的设置页面

- [ ] **Step 1: 删除提醒专用页面状态与方法**

删除 `reminderTimeLabel`、`toggleReminder()`、`showReminderExplanation()`、`showTimePicker()`、`updateReminderTime()`、`formatReminderTime()` 和 `reminderTimeRow()`。`loadSettings()` 只调用 `viewModel.load()`。

- [ ] **Step 2: 删除提醒区块**

删除“提醒”标题、开关、时间行、状态文字、重新检查按钮以及包围该区块的多余分隔线。主题区后直接进入“关于数据”。

- [ ] **Step 3: 精简清空数据文案**

首次确认信息改为“这会永久删除设备上的全部日记和背景图片，并恢复默认风格。”；最终确认保留不可恢复说明。成功 Toast 改为“已清空全部数据”，加载文字改为“正在清空…”。

- [ ] **Step 4: 验证用户已有主题命名**

确认 `ROSE_PINK` 显示仍为“瑰粉”，样例仍为“瑰”，不回退未提交的用户修改。

- [ ] **Step 5: 编译设置页**

Run: `cd OneWord_dev; hvigorw assembleHap --mode module -p module=entry@default -p product=default`

Expected: ArkTS 编译成功且生成 signed HAP。

---

### Task 3: 精简备份与隐私文案

**Files:**
- Modify: `OneWord_dev/entry/src/main/ets/pages/BackupPage.ets`
- Modify: `OneWord_dev/entry/src/main/ets/pages/PrivacyPage.ets`
- Modify: `OneWord_dev/entry/src/main/ets/components/privacy/PrivacyConsentGate.ets`

**Interfaces:**
- Consumes: 现有备份选择器、备份 ViewModel 和隐私页面导航回调
- Produces: 保留必要信息的简洁页面

- [ ] **Step 1: 精简备份页**

删除顶部介绍区；卡片说明分别改为“导出 .oneword 文件”和“从 .oneword 文件恢复”；底部改为“同日期记录不会被覆盖”。导出提示改为“备份文件未加密，包含日记正文和备注。”结果卡只显示结果文本；加载状态改为“正在导出…”“正在导入…”“正在检查文件…”。

- [ ] **Step 2: 精简隐私页**

删除宣传式大标题和版本口号，只保留三项：

```text
本机存储：日记保存在当前设备。
分享与备份：仅在你主动操作时生成或读取文件。
清除数据：可在设置中清空全部数据。
```

保留“查看完整《一字日记隐私政策》”入口。

- [ ] **Step 3: 精简首次同意页**

说明改为“请阅读并同意《一字日记隐私政策》。”，保留加载、错误、查看政策、同意与拒绝按钮。

- [ ] **Step 4: 静态检查用户可见文案**

Run: `rg -n "只在你主动选择时读写文件|备份不经过网络|你的文字，只属于你|克制的提醒|离线优先|没有改动本机数据|正在整理备份|正在收入长卷|每日回望提醒|提醒时间" OneWord_dev/entry/src/main/ets`

Expected: 无匹配；日记提交组件原有“正在收入长卷”不属于本次设置与备份范围，可按完整路径确认后保留。

---

### Task 4: 综合验收与提交

**Files:**
- Create: `docs/testing/2026-09-10-minimal-copy-reminder-retirement-acceptance.md`

**Interfaces:**
- Consumes: Tasks 1–3 的全部变更
- Produces: 可复核的测试记录与 signed HAP

- [ ] **Step 1: 运行单元测试**

Run: `cd OneWord_dev; hvigorw test --mode module -p module=entry@default`

Expected: 所有可运行的 Hypium 测试通过；若本机 RichPreviewer 环境阻塞，记录已完成的 ArkTS 编译阶段及明确环境限制。

- [ ] **Step 2: 构建实际产物**

Run: `cd OneWord_dev; hvigorw assembleHap --mode module -p module=entry@default -p product=default`

Expected: BUILD SUCCESSFUL，产物位于 `OneWord_dev/entry/build/default/outputs/default/entry-default-signed.hap`。

- [ ] **Step 3: 检查工作区与差异**

Run: `git diff --check; git status --short; git diff --stat`

Expected: 无空白错误；只包含本任务文件及预先存在的“瑰粉/瑰”修改。

- [ ] **Step 4: 写入验收记录**

记录精简后的文案、提醒入口移除情况、提醒停用测试结果、构建命令、产物路径和任何环境限制。

- [ ] **Step 5: 提交实现**

```bash
git add OneWord_dev/entry/src/main/ets/service/ReminderRetirementService.ets \
  OneWord_dev/entry/src/main/ets/service/AppServiceContainer.ets \
  OneWord_dev/entry/src/main/ets/pages/SettingsPage.ets \
  OneWord_dev/entry/src/main/ets/pages/BackupPage.ets \
  OneWord_dev/entry/src/main/ets/pages/PrivacyPage.ets \
  OneWord_dev/entry/src/main/ets/components/privacy/PrivacyConsentGate.ets \
  OneWord_dev/entry/src/test/ReminderRetirementService.test.ets \
  OneWord_dev/entry/src/test/List.test.ets \
  docs/testing/2026-09-10-minimal-copy-reminder-retirement-acceptance.md
git commit -m "feat: simplify copy and retire reminders"
```
