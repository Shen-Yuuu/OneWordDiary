# 深色模式补全设计 (Dark Mode Completion)

- 日期：2026-08-30
- 背景：`docs/design/2026-08-30-visual-uplift-api-verification.md` 确认暗色资源仅覆盖 13 个颜色中的 7 个，且组件层存在硬编码颜色，系统深色模式下会出现浅字浅底、图标隐形等问题。本设计为该先修项的实施方案。
- 决策（2026-08-30 更新）：**补全深色色板后锁定浅色模式**。本设计先完成了色板与组件的全部深色适配（资产保留，处于休眠状态，未来若要支持深色可随时放开）；最终产品决策为 App 强制浅色：在 `EntryAbility.onCreate` 中调用 `this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT)`（API 已按离线文档核实：`ApplicationContext.setColorMode` 为 API 11+，枚举 COLOR_MODE_LIGHT/DARK/NOT_SET）。`resources/dark/` 目录（element 色板 + media 变体）不参与运行时解析，作为已验收的深色资产存档。

## 1. 现状问题清单

| 问题 | 位置 | 深色下的表现 |
|---|---|---|
| 纸底色不翻转 | `paper_warm`/`paper_plain` 无 dark 值 | 纸底仍为 #FDF8F7 浅色，而 `text_primary` 翻转为 #F2ECE8 浅色 → 浅字浅底 |
| 墨色按钮 | `ink_button` 无 dark 值 | 深色按钮融进深色背景；且按钮白字硬编码 #FFFFFF 无法随按钮反色 |
| 时间轴节点调色板 | `ScrollRecordNode.ets` 5 个 getter 硬编码 | 纸底翻暗后，节点文字仍是 #282622 深色 → 深字深底 |
| 图标描边 | `ic_back` 等 7 枚 SVG 硬编码 #4A463F | 深色底上对比度约 1.6:1，几乎不可见 |
| 时间轴节点 SVG | `timeline_*.svg` 外圆用 #FFFCFB 遮挡轴线 | 深色底上变为亮白圆点（遮罩圆必须与纸底同色） |
| 错误红 | `#BA1A1A` 硬编码于设置/编辑/确认弹层 | 深红在深底上对比度不足 |
| 加载幕帘 | `#E6FDF8F7`（90% 纸色）、`#66FFFFFF`（40% 白卡片底） | 深色模式下弹出刺眼浅色遮罩 |
| 次级文字 | `text_tertiary`、`outline_soft` 无 dark 值 | 中灰在深底可读但层次错乱；浅描边框在深底突兀 |

说明：**分享卡片（ShareSingleCard/ShareScrollCard）整卡硬编码浅色，属于刻意设计（导出作品不随主题变化），本设计不改。** `surface_low` 为闲置资源，顺手补齐 dark 值防止未来误用。

## 2. 色板设计

### 2.1 `resources/dark/element/color.json` 补全（6 项缺失）

| 资源 | dark 值 | 依据 |
|---|---|---|
| paper_warm | #191715 | StyleTokens PAPER_INK.dark.background |
| paper_plain | #151515 | StyleTokens PLAIN_ASH.dark.background 调深一档，与 paper_warm 暗值 #191715 保持可感知区分 |
| surface_low | #211F1C | 与 surface_primary 暗值一致 |
| text_tertiary | #8C8783 | 较 text_secondary 暗值 #B8B0AB 更弱一档的暖灰 |
| outline_soft | #4A463F | 高于 divider 暗值 #3A3632 一档，保持浅色下的相对关系 |
| ink_button | #F2ECE8 | 深色下主按钮反色为纸白（ink↔paper 互换），配合 on_ink_button |

### 2.2 新增语义色（base + dark 双份）

| 资源 | base | dark | 用途 |
|---|---|---|---|
| on_ink_button | #FFFFFF | #191715 | 墨色按钮上的文字/图标，随按钮反色 |
| error_danger | #BA1A1A | #FFB4AB | 错误提示红（dark 取 M3 风格浅红） |
| scrim_paper | #E6FDF8F7 | #E6191715 | 90% 纸色加载幕帘 |
| card_overlay | #66FFFFFF | #66211F1C | 40% 白列表卡片底（Backup 页） |

### 2.3 长卷节点调色板（ScrollRecordNode 专用，10 名 × base/dark）

保留既有「按记录 paperId 区分纸墨/素灰」的行为，不合并；dark 值按两套预设的 dark 色板推导（文字取 StyleTokens dark textPrimary，轴线取高于 divider 一档，强调色取 dark accent）：

| 资源 | base | dark |
|---|---|---|
| scroll_text_warm | #282622 | #F2ECE8 |
| scroll_text_plain | #242424 | #F1F1EF |
| scroll_secondary_warm | #8C8783 | #B0A9A2 |
| scroll_secondary_plain | #777775 | #ABABA8 |
| scroll_faint_warm | #B8ADA7 | #5C564F |
| scroll_faint_plain | #AFAFAC | #555553 |
| scroll_line_warm | #D8C7C0 | #47403A |
| scroll_line_plain | #CFCFCA | #3D3D3B |
| scroll_accent_warm | #A65C4D | #C87867 |
| scroll_accent_plain | #626260 | #A4A4A0 |

## 3. 媒体资源 dark 变体（`resources/dark/media/`）

利用颜色模式限定词目录（`资源分类与访问`：限定词目录支持 media 资源组），仅覆盖深色下有问题的图形，几何不变只换色：

| 文件 | 变更 |
|---|---|
| ic_back / ic_close / ic_note / ic_scroll / ic_settings / ic_share | 描边 #4A463F → #B8B0AB |
| ic_refresh | 描边 #7B776E → #8F8880 |
| timeline_word_node | 遮罩外圆 #FFFCFB → #191715；内点 #A65C4D → #C87867 |
| timeline_blank_node | 遮罩外圆 #FFFCFB → #191715；描边与中心点 → #C87867 |
| timeline_missing_node | 遮罩外圆 → #191715；描边 #B8ADA7 → #5A554E |
| paper_grain_dev | 噪点 #7B776E → #C7C1BB（深底上恢复可感知的纸纹） |

## 4. 组件修改

1. `ScrollRecordNode.ets` / `ScrollAxisNode.ets`：5 个颜色 getter 改为返回 `$r` 资源（按 paperId 二选一），`lineColor` 等类型改为 `ResourceColor`；getter 结构与分支逻辑不变。
2. 白字替换（5 处，均位于 ink_button 之上）：`ScrollPage.ets:114`、`DiaryPrimaryButton.ets:13`、`AppStatusPanel.ets:68`、`DetailPage.ets:98`、`SharePreviewPage.ets:103` → `on_ink_button`。
3. 错误红替换（8 处）：`SettingsPage.ets:109/294`、`TodayConfirmation.ets:134`、`TodayEditor.ets:66/72/90/110` → `error_danger`。
4. 幕帘替换：`BackupPage.ets:138` → `card_overlay`；`BackupPage.ets:258`、`SettingsPage.ets:334` → `scrim_paper`。
5. 保持不动：`DiaryHeroContent.ets:100` 印章白字（装饰性，朱红底白字在两种模式下均成立）；StyleTokens.ets（调色板数据，供未来主题扩展）；全部分享卡片组件。

## 5. 验证方式

1. `hvigorw assembleHap` 构建通过（资源引用编译期校验）。
2. 真机/模拟器切换系统深浅色，确认：App 在系统深色下**仍保持浅色**（锁定生效），浅色下界面与改造前逐像素一致。
3. 输出卡（分享卡片）确认仍为固定浅色。

## 6. 已知残留

- `DiaryHeroContent.ets:100` 印章白字、分享卡内白字为刻意保留（固定浅色语义）。
- `StyleTokens.ets` 中两套预设的 dark 色板数据保留不动，供未来主题扩展。
- 本机无完整 HarmonyOS SDK，未能执行 `hvigorw` 构建，已用静态校验替代（JSON 语法、base/dark 27 色对齐、代码 24 处颜色引用全部可解析）；需在 DevEco 中构建回归。

## 7. 补充：素灰纸色对比度增强（2026-08-30 真机反馈）

真机验证发现「纸墨 ↔ 素灰」切换几乎无视觉响应：两套浅色纸底 `#FDF8F7` 与 `#F7F7F5` 的 RGB 差仅 (6,1,2)，约 2% 亮度差，不可感知（切换机制本身工作正常）。调整：

- `paper_plain`（light）：`#F7F7F5` → **`#EFEFEA`**（冷调中性，ΔL*≈4.2，切换可感知且保持轻盈）
- `paper_plain`（dark，休眠资产）：`#171717` → `#151515`
- `share_bg_plain.svg` 底色同步 `#EFEFEA`（与素灰分享卡保持一致）
- 长卷/分享卡的素灰文字色（#242424 等）在新底色上对比度仍然充足，不改

## 8. 补充：风格切换传播修复（2026-08-30 真机反馈）

**现象**：切换素灰后仅「七日分享预览卡」背景变化，其余页面无响应。

**根因**：各页面纸张来源不一致——

| 页面 | 修复前来源 | 切换响应 |
|---|---|---|
| 首页（有记录时） | 记录快照 `recordPaperId` | ✗ |
| 长卷 | `PaperBackdrop()` 无参 = 硬编码暖纸 | 永不响应 |
| 详情 | 记录快照 `viewModel.paperId` | ✗ |
| 设置 | 当前预设 | ✓（变化细微）|
| 分享·单日卡 | 记录快照 | ✗ |
| 分享·七日卡 | 当前预设 | ✓（用户观察到的唯一变化）|

**决策**：**页面纸张（chrome）跟随当前风格预设全局响应；日记内容（已落笔的字）保持书写时的风格快照**（记录的 fontId/paperId 继续存在于数据层，用于内容渲染与单日分享卡）。

**变更**：`Index.activePaperId` 去除记录快照分支；`ScrollPage` / `DetailPage` 新增当前预设加载（`SettingsRepository.load()` → @State paper）；`SharePreviewPage.activePaperId` 与卡片背景解耦（页面背景恒为当前预设，单日卡仍用记录快照）；`TodayEditor` 输入字体经 `fontFamily` prop 跟随预设（素灰=系统黑体）。

**日志**（tag `OneWord`，过滤 `style.`）：`style.select`（保存结果）、`style.settings_load`、`style.today_load`、`style.scroll_load`、`style.detail_load`、`style.share_load`、`style.backdrop`（每个页面实际收到的 paperId——传播链终点验证）。

### 8.1 补充：getter 失效与 @State 化（2026-08-30 第二轮真机反馈）

真机日志显示首轮修复后背景仍全部为 warm，且 `share_load paper=undefined`——`SharePreviewPage` 的 `activePaperId` **getter 在 struct 方法上下文返回 undefined**（与此前 `fontFamily` getter 失效同类；getter 在 build 上下文部分可用，方法上下文不可靠）。**定稿方案：struct 内不再用 getter 传递状态**——五个页面（Index/Scroll/Detail/Share/Settings）统一为 `@State paperId` + `loadPaperStyle()`（直读 SettingsRepository）模式；SettingsPage 经 `changeStyle()` 在切换后立即同步纸张；`PaperBackdrop` 加 `@Prop @Watch` 打 `style.backdrop_change` 日志验证属性同步。

**字体统一（产品决策）**：两种风格所有文字均使用霞鹜文楷——4 处 `recordFontFamily` 映射、设置页风格卡、`TodayEditor` 输入框全部固定为 `'oneword_wenkai, serif'` / `'oneword_wenkai_medium, serif'`；`fontId`/`sevenFontId` 数据字段保留但不再影响渲染。两风格的可见差异收敛为：纸张底色 + 分享卡底图。

### 8.2 补充：分享卡背景统一（2026-08-30 第三轮真机反馈）

**现象**：素灰模式下七日分享卡与今日分享卡背景颜色不一致。根因：七日卡 paperId 来自当前预设、今日卡来自记录快照（记录书写那天的风格），两个数据源并存。**修复**：`SharePreviewPage` 向两张卡片统一传递页面级 `paperId`（当前预设），卡片内文字色/底图随之跟随预设；`singleData.paperId` / `sevenPaperId` 不再驱动渲染（数据字段保留）。日志：`style.share_card` / `style.share_scroll_card` 输出卡片实际收到的 paperId。

**注**：`style.backdrop paperId=warm_paper_dev` 的创建期日志属预期——页面先以默认值实例化，异步加载当前预设后由 `backdrop_change` 确认同步（毫秒级过渡）。

### 8.3 定稿：AppStorage 全局响应式纸张（2026-08-30 第四轮真机反馈）

**现象**：@State+逐页加载方案下，主页/长卷/详情仍不跟随。两个根因：① `Index.onPageShow` 在 Navigation 内部 NavDestination 推栈/出栈时**不会触发**（同一页面内的覆盖层，非页面级导航），主页回显机制失效；② `ScrollPage` 存在**三层硬编码 `paper_warm`** 的不透明容器背景（Column/Stack/NavDestination），把已正确同步的 PaperBackdrop 盖住了。

**定稿架构**：`AppStorage` 键 `currentPaperId` 作为全局纸张单一数据源——

- 写入方（仅两处）：`SettingsViewModel.load()/selectStyle()`（含保存失败回滚）、`TodayViewModel.load()`（冷启动时从持久化预设初始化）
- 读取方：五个页面 `@StorageProp('currentPaperId') paperId`，变更自动响应，**无需任何手动刷新时机**；`PaperBackdrop` 的 `@Prop @Watch` 日志 `style.backdrop_change` 继续验证传播
- 长卷三层容器背景改为随 `paperId` 的三元表达式；`ScrollPage` 原硬编码为根因之一
- struct 方法上下文 getter 不可靠（8.1 的教训）→ 各页不再持有任何纸张 getter，背景色全部用 `@StorageProp` 字段 + build 内三元表达式

此方案同时消除了逐页 `loadPaperStyle` 的异步竞态与暖纸闪烁（切换设置时，栈内所有页面即时同步）。
