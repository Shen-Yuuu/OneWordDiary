# 动效包·批次 1 设计（落字仪式 / 呼吸印章 / 按压反馈 / 轻振动）

- 日期：2026-08-30
- 前置：`docs/design/2026-08-30-visual-uplift-api-verification.md`（动效 API 已核实）；风格传播（§8.3）已收口
- 设计总原则：动效只服务"落字如墨、纸张呼吸"的安静仪式感；全部使用 transform/opacity（GPU 友好）；常驻循环仅印章呼吸一处；粒子/Lottie/跨页共享元素 v1 明确不做
- 交付：两批制。本文件为批次 1；批次 2（页面转场 / 设置卡选中 / 灵感句渐变 / 分享卡切换）验证通过后另立文档

## 1. 落字仪式（核心）

触发：确认弹层点击「收入长卷」→ 记录卡浮现（首页）；进入详情页时重放一次。

时间轴（4 字最坏情况）：

```
t=60    墨晕：小点 (0.06 倍≈18px) 快速放大至 1.25 倍，颜色由深 (0.9) 快速变浅（500ms EaseOut 单段）
t≈250   放大约过半，第 1 字开始落纸（190ms 起，逐字错峰 80ms，springMotion）
t=落定+80 印章盖下：scale 1.45→1 + rotate -12°→0 + opacity 0→1（springMotion）
t=落章+420 「已」章开始呼吸循环：scale 1↔1.12，1300ms Alternate 无限
```

**墨晕实现（多轮真机反馈后定稿）**：单色正圆（300×300，borderRadius 150，墨色 `#1C1814`），单段连续动画——放大与变淡同步进行，无弹入、无贴图、无飞溅。曾尝试程序生成的不规则墨渍贴图方案，因观感偏卡通且用户偏好简洁圆晕而移除（相关贴图与脚本已删除）。

## 2. 新增组件

| 文件 | 职责 |
|---|---|
| `components/common/FallingChar.ets` | 单字落纸动画；`splitChars()` 按码点拆分（代理对安全，emoji 不碎裂） |
| `components/common/InkSeal.ets` | 印章盖下 + 呼吸循环；盖章与呼吸分内外两层容器，避免同属性动画争用；计时器在 aboutToDisappear 清理 |
| `utils/HapticFeedback.ets` | `inkDrop()`：`vibrator.startVibration({type:'time', duration:18}, {usage:'touch'})`，异常静默降级 |

接入点：

- `DiaryHeroContent`：`recordedWord` 改为 `Row` + `FallingChar` 逐字渲染（字号映射 136/76/56/44 不变，letterSpacing 改为 Row space）；Stack 底层新增墨晕层（radialGradient 8% 墨色，播放后移除）；印章 Text 替换为 `InkSeal({ delay })`；详情页自动获得同款入场
- `DiaryWordDisplay`（确认弹层预览）：同步逐字化（错峰 70ms，无墨晕无印章）
- `TodayConfirmation`：确认按钮 `onTap` 首行调用 `HapticFeedback.inkDrop()`

## 3. 微交互按压反馈

`DiaryIconButton`：按下 scale 0.92 + opacity 0.7，120ms；`DiaryPrimaryButton`：按下 scale 0.96，160ms。均以 `@State pressed` + `onTouch(Down/Up/Cancel)` 驱动，`animation` 属性平滑过渡。

## 4. 振动权限

`module.json5` 已有 `ohos.permission.VIBRATE`（提醒功能时声明），无需新增。振动 usage 取 `'touch'`（受系统触感开关管控，关闭时自动不振，属预期）。

## 5. 已知边界

- 呼吸循环为常驻动画，仅作用于 36×36 印章一层，性能开销可忽略
- 逐字拆分按码点而非完整字素聚类：组合符号序列会按字位错峰（视觉可接受），emoji 主体不会碎裂
- 批次 2（未实施）：页面转场、设置风格卡选中动效、灵感句渐变、分享卡模式切换

## 6. 实现期发现的框架级约束（重要）

**struct getter 传子组件参数 = undefined**：确认预览页实测暴露——`DiaryWordDisplay.contentFontSize`（getter）传入 `FallingChar.charSize` 得到 undefined，@Prop 回落默认值 136 导致预览字撑爆屏幕；`TodayConfirmation.primaryLabel`（getter）传入按钮 label 得到 undefined 导致按钮无字。结合此前 `fontFamily`/`activePaperId` 案例，规律为：

- getter 在**本组件 build 属性位置**：可用（paperColor/contentFontSize/ScrollRecordNode 系列均正常）
- getter 在**子组件参数位置**或**方法上下文读取**：不可靠（undefined）
- 普通方法、@State/@Prop 字段、内联三元：全部可靠

**规范（真机两次复核后收紧）**：子组件参数一律内联三元或传字段值；渲染相关的取值**一律使用普通方法或字段，不使用 struct getter**——首轮仅判定"子组件参数/方法上下文不可靠"，但长卷正文 `fontFamily(this.recordFontFamily)`（getter、build 属性位置）真机仍不生效，而同文件改普通方法后正常，故 getter 在 build 属性位置亦不可信。已将 ScrollRecordNode / ShareScrollCard / ShareSingleCard 的全部 getter 转为普通方法（含字号、颜色、family、行高等全部取值）。已修复：DiaryWordDisplay 字号、TodayConfirmation 按钮文案、Index 的 recordCanRevise/finalLabel。
