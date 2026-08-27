# 分享卡片黑块回归修复设计

## 问题与根因

上一轮修复在 `SharePreviewPage.shareCard()` 的自动测量 `Stack` 中加入了以下底层：

```typescript
Rect()
  .width('100%')
  .height('100%')
  .fill(this.activePaperColor)
```

该 `Stack` 位于 `Scroll` 内，尺寸原本由单日或最近七日卡片的固有尺寸决定。百分比 Shape 参与布局后，宽高参照外层可视区域，而不是卡片的 `286vp` 宽度和实际卡片高度，导致预览尺寸被放大、内容错位。当前设备还将该 Shape 的资源色呈现为默认黑色，所以同一个黑块同时进入预览和组件快照导出的 PNG。

## 修复设计

`SharePreviewPage` 不再绘制或计算分享卡片底层，只负责选择卡片、刷新预览和截取统一组件 ID。

实体底层由拥有精确尺寸信息的卡片组件自己绘制：

- `ShareSingleCard` 使用 `286vp × 440vp` 的固定 `Rect`。
- `ShareScrollCard` 使用 `286vp × cardHeight` 的动态 `Rect`；`cardHeight` 仍由现有时间线高度逻辑唯一计算。
- 两个 `Rect` 都位于内容下方，不使用百分比尺寸，不参与外层 `Scroll` 的百分比测量。
- Shape 使用字符串色值，不再传入页面的 `ResourceColor`：纸墨风为 `#FDF8F7`，素灰风为 `#F7F7F5`。
- 卡片内容和边框保持现有尺寸与排版；外层 `Stack` 使用与底层完全相同的明确宽高。

## 图片导出

`ShareImageService` 保持当前已经恢复的直接导出路径：组件快照生成 `PixelMap` 后直接由 `ImagePacker` 编码 PNG。底色在截图前已由精确尺寸的 Shape 绘制，因此无需重新引入逐像素读取和 PixelMap 重建。

## 回归范围

- 单日分享预览恢复为 `286vp × 440vp`，不出现黑块或内容错位。
- 最近七日卡片宽度保持 `286vp`，高度随备注开关和时间线内容变化。
- 开启最近七日备注后，备注文字继续由 `ScrollDisplayItem.note/showNote` 驱动。
- 预览与导出的 PNG 使用相同底色和布局。
- 两种纸张风格都覆盖卡片完整边界，包括四角。

## 验证

- 检查源码中不再存在分享卡片百分比 `Rect`。
- 模块测试通过。
- Debug HAP 构建通过。
- 真机分别检查单日、最近七日、备注关闭与开启四种预览，并检查导出的 PNG。
