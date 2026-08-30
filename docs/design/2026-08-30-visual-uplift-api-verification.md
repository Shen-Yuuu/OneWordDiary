# 视觉升级方案 API 断言核实报告

- 日期：2026-08-30
- 目的：对《界面背景 / 字体 / 布局艺术化升级建议》中提出的全部技术断言逐条核实，标注「确认 / 修正 / 推翻」，给出修正后的落地写法，供后续设计定稿引用。
- 核实方法：
  - 离线 API 参考：`harmony-next` skill 自带的 HarmonyOS API 12–23 文档快照（`references/JsEtsAPIReference/`）；
  - 网络检索：ohpm 三方库中心仓、GitHub、字体社区资料（用于字体素材与三方库事实）；
  - 项目实测事实：本仓库代码与配置（`build-profile.json5` 等）。
- 本项目 API 基线：`targetSdkVersion` / `compatibleSdkVersion` 均为 **6.0.1(21)（API 21）**，下文所有版本标记均以此为可用性判据。

---

## 一、结论总览

| # | 原断言 | 核实结论 | 证据来源 |
|---|--------|---------|---------|
| 1 | `font.registerFont({ familyName, source: $rawfile(...) })` 注册自定义字体 | ⚠️ **修正**：参数名是 `familySrc` 不是 `source`；且全局 `font.registerFont` 自 API 18 起废弃，应改用 `UIContext.getFont().registerFont()` | `@ohos.font (注册自定义字体).md` |
| 2 | 注册位置：EntryAbility `onWindowStageCreate` | ✅ 确认（官方明确要求在 `windowStage.loadContent` 回调中注册以全局生效） | 同上 |
| 3 | 自定义字体缺字自动回退系统字体 | ⚠️ **修正**：离线文档未承诺"自动回退"；文档明确支持的机制是 `fontFamily` 逗号分隔多字体按优先级生效（如 `'Arial,n'`）。稳妥做法是显式写回退链 `'oneword_wenkai, serif'` | `Text.md` |
| 4 | 系统通用字体族 `'serif'` / `'sans-serif'` | ⚠️ **存疑但可用**：离线文档未列出受支持的通用字体族清单；本项目已在用且通过设备验收（经验事实成立）。官方映射关系建议真机核对 | 项目代码 + `Text.md` |
| 5 | `geometryTransition` 共享元素转场 | ✅ 确认存在（API 7 声明、API 10 生效），但**定位是"组件内"转场**：配合 `animateTo` 使用（不支持 `.animation()`）；同一 id 只允许绑定 in/out 两个组件 | `组件内隐式共享元素转场 (geometryTransition).md` |
| 6 | 「首页今日大字 → 详情页」用 geometryTransition | ❌ **推翻**：`sharedTransition` 仅支持 **router** 页面路由，本项目用的是 **Navigation**。正确路径是 `Navigation.customNavContentTransition`（API 11+）手动实现，或放弃跨页共享元素改为"组件内 if/else 场景"（如首页编辑↔定稿态） | `共享元素转场 (sharedTransition).md`、`Navigation.md` |
| 7 | `TransitionEffect.asymmetric(...)` + `.combine()` + `.animation()` | ✅ 确认（asymmetric 为 API 10+；`TransitionEffect.SLIDE` 本身就是 asymmetric(move(START), move(END)) 的等价写法） | `组件内转场 (transition).md` |
| 8 | `curves.springMotion` / `curves.frictionSpring` | ⚠️ **半修正**：`springMotion`（API 9+）确认存在；**`frictionSpring` 不存在**。可选弹簧曲线实为 `springMotion`、`responsiveSpringMotion`（API 9+）、`springCurve`、`interpolatingSpring`（API 10+）。物理曲线下 `duration` 参数不生效 | `@ohos.curves (插值计算).md` |
| 9 | `animateTo` 无限循环：`iterations: -1` + `PlayMode.Alternate` | ✅ 确认（文档示例原文即为该组合） | `属性动画 (animation).md` |
| 10 | 内置 `Particle` 粒子组件 | ✅ 确认（API 10+，支持圆点/图片粒子；息屏或切后台自动暂停） | `粒子动画 (Particle).md` |
| 11 | `SymbolGlyph` + `symbolEffect` 符号动效 | ✅ 确认：组件 API 11+；`effectStrategy(SymbolEffectStrategy)` 与 `symbolEffect(SymbolEffect, isActive?)` 为 API 12+ | `SymbolGlyph.md` |
| 12 | `backgroundBlurStyle(BlurStyle.NoComponentNormal)` | ❌ **修正**：属性确认存在（API 9+），但枚举值 `NoComponentNormal` 不存在。`BlurStyle` 实际取值：`Thin / Regular / Thick / BACKGROUND_ULTRA_THIN…ULTRA_THICK / COMPONENT_ULTRA_THIN…ULTRA_THICK`。卡片底托建议 `BlurStyle.COMPONENT_THIN` 一类 | `背景设置.md` |
| 13 | `backgroundImage(src, repeat?: ImageRepeat)` + `ImageRepeat.XY` 平铺 | ✅ 确认，签名完全一致；另有 API 18 新增 `options` 重载与 `backgroundImageSize/Position` 可配合使用 | `背景设置.md` |
| 14 | `linearGradient` / `radialGradient` 渐变 | ✅ 确认（另支持 `sweepGradient`；API 18 起均有 `Optional` 重载） | `颜色渐变.md` |
| 15 | Image 的 SVG 支持是子集，`feTurbulence` 噪点滤镜大概率不可用 | ✅ **确认并可精确化**：Image 仅支持 SVG 1.1 的部分功能；滤镜标签白名单为 `filter / feOffset / feGaussianBlur / feBlend / feComposite / feColorMatrix / feFlood`，**不含 `feTurbulence`**。运行时程序化生成纸纹此路不通，维持"离线烘焙贴图"方案。另：API 21 提供 `supportSvg2` 可增强 transform 解析 | `SVG标签说明.md` |
| 16 | `@ohos.vibrator` 轻振动反馈（原写法 `startPulse`） | ❌ **修正**：接口名为 `vibrator.startVibration(effect: VibrateEffect, attribute: VibrateAttribute)`（API 9+）。交互反馈推荐 `VibratePreset`（预置振感，如 `'haptic.clock.timer'`）；需在 module.json5 声明 `ohos.permission.VIBRATE` | `@ohos.vibrator (振动).md` |
| 17 | 三方库 `@ohos/lottie` 可用（JSON 动画） | ✅ 确认：OpenHarmony 三方库中心仓在库，`ohpm install @ohos/lottie`，稳定版 v2.0.x；另有性能增强版 `@ohos/lottie-turbo`。原断言"约 200KB"体积数字未经核实，予以删除 | ohpm.openharmony.cn |
| 18 | 霞鹜文楷（LXGW WenKai）：OFL 许可、可免费商用、有 Screen 等变体 | ✅ 确认：SIL Open Font License 1.1，个人与企业均可免费商用（不得单独出售字体文件本身）；基于 Fontworks Klee One；已确认变体：TC / GB / Mono / KR / **Screen**（屏幕优化版）。原提到的 "Lite" 变体本次未核实到，落地时以 GitHub Releases 实际清单为准。完整 TTF 约 58MB，**必须子集化** | GitHub lxgw/LxgwWenkai 及多方资料 |
| 19 | 子集化：`pyftsubset` 保留 3500 常用字，压到 1.5~3MB | ⚠️ **量级修正**：工具与方法确认（`pip install fonttools`）；社区实测表明完整中文字体（几十 MB）子集化后通常降至**几百 KB ~ 2MB**量级（取决于是否 `--no-hinting` 等）。精确体积以对目标字体的实测为准 | fonttools 相关实践文章 |
| 20 | 暗色模式资源缺失（先修项） | ✅ 确认（代码审计事实，非 API 断言）：`dark/element/color.json` 仅覆盖 13 个颜色中的 7 个；`paper_warm / paper_plain / text_tertiary / outline_soft / ink_button / surface_low` 缺失，且未锁定 colorMode，系统深色下存在浅字浅底风险 | 本仓库 `resources/dark/element/color.json`、`module.json5` |

统计：✅ 确认 12 项；⚠️ 修正/存疑 5 项；❌ 推翻 3 项（#6、#8 的 frictionSpring、#16 的 startPulse；#12 的枚举名一并归入修正）。

---

## 二、修正后的关键写法（落地基准）

以下代码均为按 API 21 核实后的正确形态，可直接作为实现参考。

### 2.1 字体注册（修正 #1/#2/#3）

```typescript
// EntryAbility.ets — onWindowStageCreate 内，loadContent 回调中注册
import { font } from '@kit.ArkUI';

onWindowStageCreate(windowStage: window.WindowStage): void {
  windowStage.loadContent('pages/Index', () => {
    // API 18 起 font.registerFont 静态入口已废弃，改走 UIContext
    this.getUIContext().getFont().registerFont({
      familyName: 'oneword_wenkai',
      familySrc: $rawfile('fonts/LXGWWenKaiScreen-Regular-subset.ttf') // familySrc 支持 $rawfile
    });
  });
}
```

```typescript
// 使用处：显式回退链（文档确认的多字体按序生效机制）
Text(this.content)
  .fontFamily('oneword_wenkai, serif')
```

注意：`registerFont` 为异步接口，**不支持并发调用**；多字重需分别注册不同 `familyName`。

### 2.2 跨页转场方案（修正 #5/#6）

| 场景 | 可用方案（本项目为 Navigation 架构） |
|---|---|
| 同一页面内状态切换（如首页 编辑态 ↔ 定稿态、确认弹层） | `geometryTransition(id)` + `this.getUIContext().animateTo(...)`；同 id 仅允许 in/out 两组件 |
| NavDestination 页面间自定义转场 | `Navigation.customNavContentTransition(delegate)`（API 11+），在 `NavigationAnimatedTransition` 中手动编排 from/to 动画 |
| 首页大字 → 详情页"飞字" | 无开箱即用的跨 NavDestination 共享元素；务实做法：a) 用 customNavContentTransition 手写位移缩放过渡；或 b) 放弃跨页共享，改为详情页大字独立做"落字"入场动画 |
| ~~sharedTransition~~ | 仅适用于 router 跳转，**本项目不可用** |

### 2.3 动效曲线（修正 #8）

```typescript
import { curves } from '@kit.ArkUI';

// 落字/弹性出现：物理弹簧（duration 不生效，时长由参数与初速度决定）
this.getUIContext().animateTo({ curve: curves.springMotion(0.4, 0.8) }, () => { ... });
// 交互打断续接场景用 responsiveSpringMotion；需要"速度+刚度+阻尼"精调用 springCurve
// 呼吸循环：iterations: -1 + PlayMode.Alternate（已确认）
```

### 2.4 背景（确认 #13/#14/#15）

```typescript
// PaperBackdrop 升级形态：平铺贴图 + 边缘晕染（两层，均为文档确认能力）
Stack() {
  Column()
    .width('100%').height('100%')
    .backgroundColor(this.paperColor)
    .backgroundImage($r('app.media.paper_tile_warm'), ImageRepeat.XY) // 签名核实一致
    .backgroundImageSize(ImageSize.Auto) // 或指定平铺单元尺寸

  Column()
    .width('100%').height('100%')
    .radialGradient({ center: [50, 50], radius: 120,
      colors: [['transparent', 0.6], ['#E8DFD833', 1]] }) // 边角压暗/墨晕
}
.hitTestBehavior(HitTestMode.None)
```

SVG 纸纹路线限制：`<feTurbulence>` 不受支持，程序化噪点不可行；继续沿用现有手写散点 SVG 或改为离线烘焙的平铺贴图（推荐后者）。API 21 的 `supportSvg2` 只增强 transform 解析，不增加滤镜白名单。

### 2.5 振动反馈（修正 #16）

```typescript
import { vibrator } from '@kit.SensorServiceKit';

// module.json5 需声明： "requestPermissions": [{ "name": "ohos.permission.VIBRATE" }]
vibrator.startVibration(
  { type: 'preset', count: 1 },          // VibratePreset：交互反馈推荐；具体 effectId 需真机验证支持项
  { usage: 'touch' }
);
// 或最简时长控制：{ type: 'time', duration: 10 }
```

### 2.6 毛玻璃（修正 #12）

```typescript
.backgroundBlurStyle(BlurStyle.COMPONENT_THIN) // 枚举：Thin/Regular/Thick/BACKGROUND_*/COMPONENT_*
```

---

## 三、对原方案落地计划的影响

1. **字体包（第 2 步）**：方案成立，但注册代码、参数名、废弃提示按 §2.1 修正；`Lite` 变体未核实，下载时以 [GitHub Releases](https://github.com/lxgw/LxgwWenkai) 实际清单为准（Screen 版已确认存在，更适合手机阅读）。
2. **动效包（第 4 步）**：曲线名 `frictionSpring` → `springMotion` / `responsiveSpringMotion`；「跨页飞字」从 geometryTransition 降级为 customNavContentTransition 手写或详情页独立入场动画，建议设计阶段重新取舍。
3. **背景纹理（第 3 步）**：方案成立且能力全部确认；放弃任何"运行时 SVG 滤镜生成噪点"的想法。
4. **振动反馈**：API 存在但注意三点——需要声明权限、预置 effectId 的设备支持面需真机验证、`startVibration` 与本项目"安静克制"的气质需产品层面确认是否引入。
5. **先修项（暗色资源补全或锁定 colorMode）不受本报告影响，维持原建议。**

## 四、待真机/构建期实测清单

| 事项 | 方法 |
|---|---|
| 通用字体族 `'serif'` 实际映射的字体文件 | 真机 `font.getSystemFontList()`（PC/2in1 生效）或目测比对；至少在目标机型上确认渲染差异 |
| 霞鹜文楷子集化后精确体积 | 对目标 TTF 执行 `pyftsubset --text-file=常用3500字.txt --no-hinting` 后实测 |
| `VibratePreset` 各 effectId 支持情况 | 真机 `vibrator.isSupportEffect(id, callback)` 逐个探测 |
| `@ohos/lottie` 在 API 21 上的运行表现 | 集成后真机回归（本项目依赖列表当前为空，属新增依赖） |
| 子集字体缺字时的实际渲染行为 | 输入生僻字（如「龘」）验证回退链 `'oneword_wenkai, serif'` 的表现 |

## 五、参考

- 离线 API 参考（harmony-next skill，HarmonyOS API 12–23 快照）：`@ohos.font`、`Text`、`组件内隐式共享元素转场 (geometryTransition)`、`共享元素转场 (sharedTransition)`、`Navigation`、`组件内转场 (transition)`、`@ohos.curves`、`属性动画 (animation)`、`粒子动画 (Particle)`、`SymbolGlyph`、`背景设置`、`颜色渐变`、`SVG标签说明`、`@ohos.vibrator`
- [OpenHarmony 三方库中心仓（@ohos/lottie）](https://ohpm.openharmony.cn/)
- [GitHub: lxgw/LxgwWenkai](https://github.com/lxgw/LxgwWenkai)、[Google Fonts: LXGW WenKai TC](https://fonts.google.com/specimen/LXGW+WenKai+TC)
- fonttools 子集化实践：[CSDN](https://blog.csdn.net/lemonbit/article/details/132353196)、[博客园](https://www.cnblogs.com/feffery/p/17588053.html)、[知乎专栏](https://zhuanlan.zhihu.com/p/26615252)
