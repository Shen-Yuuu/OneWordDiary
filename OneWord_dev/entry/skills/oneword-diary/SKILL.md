---
name: oneword-diary
description: 一字日记的记录与样式设置能力，响应"记日记"、"写日记"、"换日记主题/字体"等指令，可按指定内容、备注、主题与字体完成当天的日记记录
---

## 触发场景

当用户明确表达**记录今天的日记**或**设置日记主题/字体**时调用。典型话术：

- "帮我记今天的日记，日记内容是'开心'，备注是'吃了一顿大餐'"
- "用一字日记记一下，今天写'见晴'"
- "记日记，内容'好困'，备注'加班到十一点'"
- "帮我记今天的日记，内容是'雨'，主题设置成瑰粉，字体设置为小楷"
- "把一字日记的主题换成雾蓝"
- "日记字体换成得意黑"

不调用的情况：

- 用户说"看看今天的日记"、"我前几天写了什么"——意图是查看记录，本Skill仅支持记录与样式设置。
- 用户说"删除日记"、"清空数据"——本Skill不提供删除能力。
- 用户说"写一篇五百字的日记"——一字日记只支持一至四个字的极简记录，长文记录应拒绝。
- 用户没有明确指向记录或样式设置（如"日记有什么用"）——闲聊或咨询，无需调用。

## 能力契约

### 场景1：记录今天的日记（recordTodayDiary）

#### 执行参数

```
exec-cli(command: ohos-arkTSScript --skillName 'oneword-diary' --scriptPath 'scripts/DiarySkill.ets' --functionName 'recordTodayDiary' --args '{
    "arg1": "开心",
    "arg2": "吃了一顿大餐",
    "arg3": "rose_pink",
    "arg4": "oneword_kai"
}'
)
```

```json
{
  "args": {
    "type": "object",
    "properties": {
      "arg1": {
        "type": "string",
        "description": "日记内容，一至四个字，必填。如：开心、见晴、慢一点"
      },
      "arg2": {
        "type": "string",
        "description": "备注，可选，最多三十个字，单行。如：吃了一顿大餐"
      },
      "arg3": {
        "type": "string",
        "description": "主题，可选。取值（中文说法映射）：纸墨=paper_ink、素灰=plain_ash、松青=pine_mist、雾蓝=mist_blue、杏笺=apricot_paper、瑰粉=rose_pink。用户说'瑰粉'、'玫瑰粉'、'粉色'时填 rose_pink"
      },
      "arg4": {
        "type": "string",
        "description": "字体，可选。取值（中文说法映射）：小楷/文楷/楷体/默认字体=oneword_kai、得意黑=smiley_sans_oblique、悠然小楷=slide_youran、汇文明朝体=mingchao。用户说'小楷'时填 oneword_kai"
      }
    },
    "required": ["arg1"]
  }
}
```

#### 执行返回值

```
// 1. 记录成功
{
    "type": "result",
    "status": "success",
    "data": {
        "date": "2026-09-18",
        "content": "开心",
        "note": "吃了一顿大餐",
        "theme": "rose_pink",
        "themeName": "瑰粉",
        "font": "oneword_kai",
        "fontName": "小楷（默认字体）",
        "settingsSaved": true
    }
}
```

日记写入成功后才会保存本次指定的主题或字体为后续默认设置。若日记已写入但默认设置保存失败，仍返回 `success`，`settingsSaved` 为 `false`；当日记录仍保留本次指定的样式。不要据此重试记录，以免收到“今天已有记录”。

```
// 2. 入参非法（内容为空、超过四个字、主题或字体不支持等）
{
    "type": "result",
    "status": "failed",
    "errCode": "ERR_INVALID_PARAMS",
    "errMsg": "unsupported theme: 紫色",
    "suggestion": "暂不支持主题「紫色」，可选：纸墨、素灰、松青、雾蓝、杏笺、瑰粉"
}
```

```
// 3. 今天已有记录（不覆盖）
{
    "type": "result",
    "status": "failed",
    "errCode": "ERR_ALREADY_RECORDED",
    "errMsg": "今天已经留下记录",
    "suggestion": "今天已经留下记录了，打开一字日记可以查看或修订"
}
```

```
// 4. 内部错误（存储失败、服务未就绪等）
{
    "type": "result",
    "status": "failed",
    "errCode": "ERR_INTERNAL",
    "errMsg": "record failed",
    "suggestion": "记录日记失败了，请稍后再试"
}
```

```json
{
  "type": "object",
  "required": ["type", "status"],
  "properties": {
    "type":   { "type": "string", "const": "result" },
    "status": { "type": "string", "enum": ["success", "failed"] },
    "data": {
      "type": "object",
      "properties": {
        "date":      { "type": "string" },
        "content":   { "type": "string" },
        "note":      { "type": "string" },
        "theme":     { "type": "string" },
        "themeName": { "type": "string" },
        "font":      { "type": "string" },
        "fontName":  { "type": "string" },
        "settingsSaved": { "type": "boolean" }
      }
    },
    "errCode": {
      "type": "string",
      "enum": ["ERR_INVALID_PARAMS", "ERR_ALREADY_RECORDED", "ERR_NOT_READY", "ERR_INTERNAL"]
    },
    "errMsg":     { "type": "string", "minLength": 1 },
    "suggestion": { "type": "string", "minLength": 1 }
  }
}
```

### 场景2：设置日记主题或字体（applyDiaryStyle）

#### 执行参数

```
exec-cli(command: ohos-arkTSScript --skillName 'oneword-diary' --scriptPath 'scripts/DiarySkill.ets' --functionName 'applyDiaryStyle' --args '{
    "arg1": "mist_blue",
    "arg2": "mingchao"
}'
)
```

```json
{
  "args": {
    "type": "object",
    "properties": {
      "arg1": {
        "type": "string",
        "description": "主题。取值（中文说法映射）：纸墨=paper_ink、素灰=plain_ash、松青=pine_mist、雾蓝=mist_blue、杏笺=apricot_paper、瑰粉=rose_pink"
      },
      "arg2": {
        "type": "string",
        "description": "字体。取值（中文说法映射）：小楷/文楷/楷体/默认字体=oneword_kai、得意黑=smiley_sans_oblique、悠然小楷=slide_youran、汇文明朝体=mingchao"
      }
    },
    "anyOf": [
      { "required": ["arg1"] },
      { "required": ["arg2"] }
    ]
  }
}
```

#### 执行返回值

```
// 1. 设置成功
{
    "type": "result",
    "status": "success",
    "data": {
        "theme": "mist_blue",
        "themeName": "雾蓝",
        "font": "mingchao",
        "fontName": "汇文明朝体"
    }
}
```

```
// 2. 入参非法（主题与字体均为空、取值不支持）
{
    "type": "result",
    "status": "failed",
    "errCode": "ERR_INVALID_PARAMS",
    "errMsg": "theme and font are both empty",
    "suggestion": "请告诉我想使用的主题或字体"
}
```

```
// 3. 内部错误
{
    "type": "result",
    "status": "failed",
    "errCode": "ERR_INTERNAL",
    "errMsg": "save style failed",
    "suggestion": "设置样式失败了，请稍后再试"
}
```

```json
{
  "type": "object",
  "required": ["type", "status"],
  "properties": {
    "type":   { "type": "string", "const": "result" },
    "status": { "type": "string", "enum": ["success", "failed"] },
    "data": {
      "type": "object",
      "properties": {
        "theme":     { "type": "string" },
        "themeName": { "type": "string" },
        "font":      { "type": "string" },
        "fontName":  { "type": "string" }
      }
    },
    "errCode": {
      "type": "string",
      "enum": ["ERR_INVALID_PARAMS", "ERR_NOT_READY", "ERR_INTERNAL"]
    },
    "errMsg":     { "type": "string", "minLength": 1 },
    "suggestion": { "type": "string", "minLength": 1 }
  }
}
```
