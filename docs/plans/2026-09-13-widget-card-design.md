# 桌面卡片「今日一字」设计

- 日期：2026-09-13
- 分支：桌面卡片功能
- 范围：2×2 ArkTS 卡片一张，展示今日一字 + 日期；纸底/墨色/字体跟随记录快照主题（逐日一致语义）。

## 结构

| 文件 | 职责 |
|---|---|
| `resources/base/profile/form_config.json` | 卡片配置：2×2、00:10 定时刷新（跨日更新日期）、dataStoreEnabled |
| `ets/entryformability/EntryFormAbility.ets` | 生命周期：onAddForm（记 formId + 异步推数据）、onUpdateForm、onRemoveForm（清 formId）|
| `ets/widget/pages/WordCardCard.ets` | 卡片 UI：LocalStorageProp 绑定卡片数据 |
| `ets/utils/WidgetSync.ets` | 偏好存储（payload + formIds）与推送（formProvider.updateForm）|

## 数据流

```
App（保存/启动）→ WidgetSync.syncWidgetFromRecord
  → 写 word_card_storage 偏好（payload: content/date/paperColor/inkColor/accentColor/fontFamily）
  → 对每个 formId formProvider.updateForm
卡片 ← LocalStorageProp 自动绑定 payload 字段
```

- 卡片侧数据源：FormExtensionAbility 与 App 共用应用级偏好（同 hap），卡片添加时 formId 入库、移除时出库。
- 系统定时刷新（00:10）触发 onUpdateForm，从偏好重读 payload（跨日更新日期）。
- record 为 null（当日未写）→ 卡片显示占位「一字」。

## 主题与字体同步

卡片颜色三值（纸/墨/印泥）与字体族全部由 `styleForPaper(record.paperId).light.*` 与 `fontFamilyForId(record.fontId)` 推导——**跟随记录保存时的主题快照**（逐日一致语义），切换当前主题不影响已固化卡片。重新修订提交或新落后，卡片随新快照更新。

## 字体说明

卡片字体通过 payload 的 fontFamily 传入注册字体族名（oneword_wenkai 等）。若卡片渲染进程未注册自定义字体导致回退系统字体，观感仍可接受；真机验证后如需强化，再研究卡片上下文的字体注册路径。


## 真机反馈迭代（同日）

1. **卡片字体**：卡片渲染环境独立于 App 进程，App 内注册的字体对卡片不可见——在卡片页 `aboutToAppear` 中对当前渲染环境执行 `getUIContext().getFont().registerFont(...)`（七款全部注册，单款失败不影响其余），`fontFamily` 才能命中。
2. **字号自适应**：一字 56 / 两字 42 / 三字 34 / 四字 28，`maxLines(1)` 保证不裁切。
3. **右上角印章**：新增「已」印章角标（20×20，印泥色随主题），呼应主页记录卡。
4. **备注开关**：预览页模式胶囊下方新增「显示备注」开关；单日卡备注按详情页样式（记录字体/正文墨色/居中，内容区 292→244 让位）；七日卡备注在词下横线下方以 10fp 浅灰小字展示，随开关显隐。


## 验证

1. 添加 2×2 卡片到桌面：显示今日一字 + 日期，纸底墨字
2. App 内写/改今日内容 → 卡片同步（formIds 已登记的卡片即时更新）
3. 切换主题/字体 → 重新落字后卡片跟随新快照
4. 跨日（次日 00:10 定时刷新）→ 日期自动更新
