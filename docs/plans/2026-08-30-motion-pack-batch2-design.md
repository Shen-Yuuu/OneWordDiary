# 动效包·批次 2 设计（页面入场 / 风格卡选中 / 灵感句渐变 / 分享卡切换）

- 日期：2026-08-30
- 前置：批次 1（`motion-pack-batch1-design.md`）已真机验证通过；技术约束沿用其第 6 节（struct 内禁用 getter 传子组件参数）
- 设计原则不变：transform/opacity only；时长 120~300ms；不替换系统 Navigation 默认页面滑动，只做内容层"落定"动效

## 1. 页面内容入场（6 个 NavDestination 页）

**实现方式**：`@State contentShown` + `aboutToAppear` 内 30ms 延迟 `animateTo`（300ms EaseOut），内容列 opacity 0→1 + translateY 14→0。

选择该方案而非 `.transition()` 的原因：Navigation 推栈/出栈是框架驱动的转场，子组件 `.transition()` 是否参与未在文档中保证；而自驱 `animateTo` **保证生效**。纸张背景（PaperBackdrop + 页面底色）不参与动画，全程稳定。

接入页面：长卷 / 详情 / 分享预览 / 设置 / 备份 / 隐私（首页 @Entry 不做，保持启动即现）。

## 2. 设置风格卡选中动效

选中态变化时（`stylePresetId` 驱动）：描边宽度 1↔2 与颜色平滑过渡；样字「墨/灰」scale 1↔1.08。均通过属性 `.animation({ duration: 220, curve: Curve.EaseOut })` 绑定（属性动画无需 animateTo 上下文）。

## 3. 灵感句刷新渐变

点击换一句：旧句淡出下移（150ms EaseIn）→ 调 `onRefresh()` → 新句淡入复位（200ms EaseOut）。`fading` 状态防重入；计时器 aboutToDisappear 清理。

## 4. 分享预览

- 单日↔七日切换：`selectMode` 内以 `animateTo(240ms)` 包裹 `selectedMode` 变更，两张卡的 if/else 上下树配 `.transition(TransitionEffect.OPACITY.animation(240ms))` 交叉淡入淡出
- 模式胶囊：选中背景与文字颜色变化加 220ms 属性动画（滑块感）

## 5. 批次 1+2 动效总览

| 场景 | 动效 |
|---|---|
| 落字确认 | 墨点绽开（小点快速放大变浅 500ms）→ 逐字落纸（错峰 80ms spring）→ 印章盖下 → 18ms 轻振 → 印章呼吸（1↔1.12）|
| 详情页进入 | 同款逐字 + 印章序列重放 |
| 六页进入 | 内容淡入上浮 300ms（纸张不动）|
| 按钮按压 | 图标 0.92 / 主按钮 0.96 缩放 |
| 风格切换 | 卡片描边与样字缩放过渡 |
| 灵感句 | 淡出下移 → 换词 → 淡入 |
| 分享模式切换 | 卡片交叉淡化 + 胶囊色变 |

## 6. 批次 3：细节项（原视觉升级计划的收尾三条）

1. **一二字竖排**：`DiaryHeroContent` 落字排布——1~2 字竖排（Column，错峰 90ms），3~4 字保持横排（Row）。首页今日卡与详情页同时生效
2. **长卷边缘渐隐**：列表 `.overlay` 上下各一条 26vp 纸色→透明的 linearGradient 渐隐带（随 paperId 响应），`hitTestBehavior(None)` 不影响滚动与点击
3. **墨线时间轴——已回退**：曾将直线 Divider 替换为程序生成的成对笔触贴图（起笔收笔纺锤剖面），真机评估后**决定保留原来的简约样式**并移除该实验：`ScrollAxisNode` 恢复主题色 1px Divider（`lineColor` 传参/getter 复原），词下恢复 32×1 灰线，`ink_line_leave/arrive/ink_stroke` 贴图已删除。批注：若未来重拾墨线方案，生成脚本思路为多频噪声外形 + 节点处 0.45→中段 1.0 的两段式宽度剖面（中段约为两侧两倍粗）
