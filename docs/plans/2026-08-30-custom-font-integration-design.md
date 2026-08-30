# 自定义字体接入设计 (Custom Font Integration)

- 日期：2026-08-30
- 前置：`docs/design/2026-08-30-visual-uplift-api-verification.md` 已核实 `@ohos.font.registerFont`（API 9+；API 18 起全局静态入口废弃，推荐 `UIContext.getFont().registerFont`）、`Text.fontFamily` 逗号多字体回退链、霞鹜文楷 SIL OFL 1.1 许可。
- 目标：将设计文档规定的文学衬线字体真正打包进 App（此前全部使用系统通用族 `serif`），首选 **霞鹜文楷 LXGW WenKai**（楷体骨架、笔锋轻，契合「一词日记」气质）。

## 1. 字体资产

| 项 | 值 |
|---|---|
| 来源 | github.com/lxgw/LxgwWenkai release **v1.522**（Regular/Medium 两个字重） |
| 许可 | SIL Open Font License 1.1（可免费商用；随包附带 `OFL-LICENSE.txt`） |
| 子集字符集 | **4038 字** = GB2312 一级常用字 3755 + App 全部 UI 字符（从源码提取 349 个）∪ ASCII + 中文标点（U+3000-303F）+ 全角（U+FF01-FF5E）+ 常用西文标点（U+2013-2026 等） |
| 工具 | Python fontTools 4.61：`pyftsubset`（保留 hinting）+ name 表改名 |
| 产物 | `OneWordKai-Regular.ttf` 1.72MB、`OneWordKai-Medium.ttf` 1.71MB（原字重 24MB/个） |
| 存放 | `entry/src/main/resources/rawfile/fonts/` |

**OFL 合规要点**：子集属于「修改版」，OFL 1.1 的保留字体名（RFN）条款要求修改版不得沿用保留名 "LXGW WenKai"，故注册族名与字体内部 name 表（ID 1/2/4/6/16/17）均改为 **"OneWord Kai"**；许可文件随字体分发。

**缺字回退**：用户输入生僻字（子集未覆盖）时，经 `fontFamily` 逗号链回退系统衬线——两族名均带 `, serif` 后缀。日常用字覆盖率约 99%+（GB2312 一级字表）。

## 2. 注册（EntryAbility.ets）

- 时机：`onWindowStageCreate` 内调用 `windowStage.getMainWindow().then(win => win.getUIContext().getFont().registerFont(...))`（官方指引：全局字体在 onWindowStageCreate 经 loadContent/主窗口注册；`Window.getUIContext` 为 API 10+，`UIContext.getFont().registerFont` 为推荐形态）。
- 注册两个独立族（不做同族多字重——同族多文件注册行为未在文档中保证）：
  - `oneword_wenkai` ← `fonts/OneWordKai-Regular.ttf`
  - `oneword_wenkai_medium` ← `fonts/OneWordKai-Medium.ttf`
- 失败静默降级：注册失败仅记日志（AppLogger），UI 经回退链落回系统衬线，不影响可用性。

## 3. 字体族常量与接线

`StyleTokens.ets` 新增（2026-08-30 真机调试后定稿形态）：

```typescript
export class FontFamilies {
  static readonly SERIF: string = 'oneword_wenkai, serif';
  static readonly SERIF_HEAVY: string = 'oneword_wenkai_medium, serif';
  private constructor() {
  }
}
```

> **坑（真机复现）**：跨模块引用字体族字符串在 @Component struct 内运行时取值为 `undefined`（历经 `export const` 活绑定与 `class` 静态成员两代实现，现象一致；而同模块的 enum 在 struct 内正常、UIAbility class 文件内两种方式都正常；StyleTokens 无 import、无循环依赖，Clean 重编无效）。同时 v2/v3 两轮日志逐字节一致，无法排除"设备运行旧 HAP"。**最终定稿：14 个 struct 文件直接内联字面量 `'oneword_wenkai, serif'` / `'oneword_wenkai_medium, serif'`**（字符串不可变，内联无维护风险）；`FontFamilies` 类仅保留在 StyleTokens（定义）、EntryAbility（class 文件访问正常，日志探针）、DiaryHeroContent（诊断探针，读 `FontFamilies.SERIF` 并 try/catch）。`font.hero_v4` 日志的 `staticRead` 字段可判定 struct 内模块绑定是否恢复；`shadowed` 字段判定实例属性遮蔽。

- `PAPER_INK_STYLE.fontFamily` 由 `'serif'` 改为 `FontFamilies.SERIF`；`fontId: 'system_serif_dev'` **保持不变**（数据库兼容，历史记录按 fontId 渲染时自动获得新字体）。
- 全仓 23 处 `fontFamily('serif')` 字面量 + 4 处 `fontId` 映射 getter + 1 处默认 Prop 全部替换为常量（15 个文件）。
- Medium/Bold 字重处（5 处）使用 `FontFamilies.SERIF_HEAVY`：长卷页标题、月份表头、今日确认标题、印章「已」字、落字输入框；其余 Normal 字重处使用 `FontFamilies.SERIF`。
- 素灰预设（`PLAIN_ASH`）维持系统 `sans-serif`，不受影响；设置页风格卡片预览同步（纸墨卡片直接呈现文楷实际效果）。
- 分享卡片随记录 fontId 使用文楷渲染，导出快照同样生效（同进程已注册字体）。

**注册时机（真机复现修正）**：`getMainWindow()` 必须在 `loadContent` 回调内调用；在 `onWindowStageCreate` 入口直接调用会报 `1300002`（This window state is abnormal）。最终顺序：`loadContent 成功 → font.constants_check → font.asset_ok ×2 → registerFont ×2（系统打印 begin to register font.）→ font.custom_registered`。

## 4. 体积与性能评估

- 安装包增量约 **3.4MB**（两字重子集）。
- 注册在窗口创建期一次性完成；`registerFont` 为异步接口，不阻塞首帧（首帧可能短暂使用系统衬线，注册完成后生效）。
- 运行时渲染开销与系统字体一致，无额外成本。

## 5. 验证方式

### 5.1 日志验证（2026-08-30 补充）

三层日志点，tag `OneWord`（domain 0x4F57），过滤关键字 `font.`：

| 日志 | 位置 | 证明什么 |
|---|---|---|
| `font.register_start` | EntryAbility | 注册流程启动 |
| `font.asset_ok <path> bytes=<n>` | EntryAbility（getRawFdSync） | 字体文件确实打进安装包且可读；bytes 应为 1803740 / 1795816 |
| `font.custom_registered` | EntryAbility | 两次 registerFont 调用无同步异常（异步加载无回调，需结合视觉确认） |
| `font.asset_missing` / `font.register_failed` | EntryAbility | 异常路径：文件未打包 / 窗口获取失败 |
| `font.word_display family=... hero=...` | DiaryWordDisplay | 首页大字/今日卡实际请求的字体族 |
| `font.hero_content fontId=... family=...` | DiaryHeroContent | 详情页实际请求的字体族 |
| `font.share_card fontId=... family=...` | ShareSingleCard | 分享卡实际请求的字体族 |

查看方式：DevEco Log 窗口过滤 `font.`；或命令行 `hdc shell hilog -T OneWord`（`%{public}` 格式，内容可见）。

判定链：`asset_ok`（文件在包里）+ `family=oneword_wenkai, serif`（UI 请求正确）+ 视觉楷体笔锋（引擎加载成功）三者齐备 = 替换生效。日志正常但字形仍似宋体时，属引擎层静默回退，用素灰/纸墨切换对照实验区分。

### 5.2 功能回归

1. DevEco 构建通过；真机运行：
   - 首页大字（1~4 字）应呈现楷体笔锋；输入框、确认弹层、长卷、详情、分享卡同步变化；
   - 素灰预设仍为系统黑体（对比验证）；
   - 输入生僻字（如「龘」）验证回退链无豆腐块。
2. 安装包体积对比（预期 +3.4MB 左右）。

## 6. 已知边界

- 竖排文字（后续视觉升级项）若采用逐字换行方案无需字体支持；若采用真正的纵向排版特性需另行评估 vmtx（子集已保留纵向度量）。
- 若未来需要 Light 字重（更纤细的展示），可按相同流程子集化 `LXGWWenKai-Light.ttf` 并注册第三族名。
- 本机无完整 HarmonyOS SDK，构建与真机回归需在 DevEco 完成。
