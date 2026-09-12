# 主题墨水体系设计

- 日期：2026-09-13
- 分支：界面优化
- 背景：六套主题（纸墨/素灰/松青/雾蓝/杏笺/瑰粉）此前只切换纸面与背景色，而落字大字、墨晕、印章、光标、确认弹层强调色、长卷文字颜色均固定在"纸墨"默认色——切主题只换了"墙"，没换"墨"。

## 方案

主题的 `textPrimary` 即该主题的"墨色"，`accent` 即该主题的"印泥色"。所有艺术元素从固定资源（`$r('app.color.text_primary'/'accent_vermilion')`、硬编码 `#1C1814`）切换为 `styleForPaper(paperId).light.*` 运行时取色：

| 元素 | 墨色（textPrimary） | 印泥色（accent） |
|---|---|---|
| 落字逐字（FallingChar） | ✓ | — |
| 墨晕圆（DiaryHeroContent） | ✓ | — |
| 留白点（recordedBlank） | — | ✓ |
| 印章「已」（InkSeal） | — | ✓ |
| 确认弹层（TodayConfirmation） | — | ✓（留白点/提示/定稿标注/加载圈）|
| 编辑器光标与提示（TodayEditor） | — | ✓（双光标/背景图提示）|
| 加载/错误面板（AppStatusPanel） | — | ✓ |
| 长卷条目（ScrollRecordNode） | ✓ | —（faint 用 divider，line 用 divider）|
| 分享卡（已由历史主题方案覆盖） | ✓ | ✓ |

- 组件内通过 `@StorageProp('currentPaperId')` 取当前纸色标识（全局单一数据源），再经 `styleForPaper().light.*` 取色——沿用全项目已验证的模式，遵守"子组件参数内联、不用 struct getter"约束。
- 深浅色：App 已锁定浅色模式（EntryAbility setColorMode LIGHT），统一取 `light.*`。

## 顺带清理

- 长卷 `scroll_text/secondary/faint/line/accent_warm/plain` 共 10 个双主题变体资源删除（被完整主题色板取代）；`accent_vermilion` 资源删除（零引用）。
- `faintColor` 映射为 `light.divider`（缺日条目保持"几乎不可见"的层级）。

## 主题墨色对照（light）

| 主题 | 纸 | 墨 | 印泥 |
|---|---|---|---|
| 纸墨 | #FDF8F7 | #282622 | #A65C4D |
| 素灰 | #EFEFEA | #242424 | #606060 |
| 松青 | #EAF1EC | #29342F | #4F7464 |
| 雾蓝 | #EAF0F6 | #29333E | #58718C |
| 杏笺 | #F7EFE2 | #3D3127 | #A76D46 |
| 瑰粉 | #F8E8EC | #3D2930 | #B15F76 |

## 待办（下一步）

- 墨滴 Lottie（ink_drop.json 已在 rawfile）：接入 @ohos/lottie 后按主题墨色生成六变体（生成脚本已参数化墨色）。
