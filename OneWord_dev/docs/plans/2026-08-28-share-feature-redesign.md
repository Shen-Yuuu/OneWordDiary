# 分享功能重新设计 - 简化方案

## 问题背景

之前的修复尝试失败，出现两个核心问题：

1. **组件快照失败**：错误日志显示 `Can't find a component that id or key are secure_field`
   - 使用 `.key()` 强制重建导致组件 ID 不稳定
   - `getComponentSnapshot().get(id)` 无法找到目标组件

2. **备注开关无响应**：切换"展示备注"开关后 UI 不更新
   - `@Prop` 传递布尔值到子组件
   - 子组件的条件渲染和 getter 没有正确响应状态变化

## 设计目标

从功能目标出发，设计简洁可靠的实现：

- **目标 1**：导出分享图片必须成功，背景不透明
- **目标 2**：备注开关切换后，预览和导出都要立即反映变化
- **目标 3**：代码简单易调试，关键节点有日志

## 核心设计原则

### 原则 1：单向数据流 + 计算好的值

**问题根源**：将 `includeNote: boolean` 传递给子组件，子组件内部计算备注文本，响应式追踪失效。

**解决方案**：父组件计算好最终要显示的备注文本，直接传递字符串给子组件。

```typescript
// 父组件：SharePreviewPage
get singleNoteText(): string {
  if (!this.showNote) return '';
  if (!this.viewModel.singleData) return '';
  const kind = this.viewModel.singleData.recordType === RecordType.WORD ?
    ShareDayKind.WORD : ShareDayKind.BLANK;
  return resolveShareNoteText(true, kind, this.viewModel.singleData.note);
}

// 传递计算好的字符串
ShareSingleCard({
  noteText: this.singleNoteText,  // 字符串，不是布尔值
  ...
})

// 子组件：ShareSingleCard
@Prop noteText: string = '';  // 接收最终文本

get shouldShowNote(): boolean {
  return this.noteText.length > 0;  // 简单判断
}

if (this.shouldShowNote) {
  Text(this.noteText)  // 直接显示
}
```

**优势**：
- 数据流清晰：父组件负责业务逻辑，子组件负责渲染
- 子组件只依赖简单的字符串长度判断
- 避免复杂的响应式追踪和 getter 缓存问题

### 原则 2：稳定的组件 ID，不使用动态 key

**问题根源**：使用 `.key()` 强制重建时，组件的实际标识符变化，快照 API 找不到组件。

**解决方案**：完全移除 `.key()` 属性，依靠 ArkUI 的响应式系统自动更新。

```typescript
// 修改前（失败）
Stack() {
  this.shareCardContent()
}
.id(SHARE_CARD_COMPONENT_ID)
.key(`share-card-${this.renderVersion}`)  // ❌ 导致 ID 不稳定

// 修改后（成功）
Stack() {
  this.shareCardContent()
}
.id(SHARE_CARD_COMPONENT_ID)  // ✅ ID 始终稳定
```

**原理**：
- 组件 ID 在整个生命周期保持稳定
- 快照 API 可以可靠地找到目标组件
- 状态变化时，ArkUI 自动 diff 并更新必要的子树

### 原则 3：关键节点日志

在所有关键操作点添加详细日志，方便调试：

1. **状态变化**：Toggle onChange、getter 计算
2. **组件生命周期**：aboutToAppear、build 入口
3. **快照流程**：开始快照、获取成功、打包完成
4. **错误处理**：捕获异常并记录详细信息

```typescript
// 示例：Toggle onChange
.onChange((isOn: boolean) => {
  console.info(`SharePreviewPage Toggle onChange: isOn=${isOn}, before showNote=${this.showNote}`);
  this.showNote = isOn;
  console.info(`SharePreviewPage Toggle onChange: after showNote=${this.showNote}`);
})

// 示例：组件构建
@Builder
private shareCardContent() {
  console.info(`SharePreviewPage shareCardContent: building, mode=${this.selectedMode}, showNote=${this.showNote}`);
  // ...
}

// 示例：快照流程
console.info(`ShareImageService shareCard: getting component snapshot for id=${componentId}`);
const pixelMap = await uiContext.getComponentSnapshot().get(componentId, { ... });
console.info('ShareImageService shareCard: component snapshot obtained successfully');
```

## 具体实现

### 1. SharePreviewPage 修改

**新增 getter 计算备注文本**：
```typescript
get singleNoteText(): string {
  if (!this.showNote) {
    console.info('SharePreviewPage singleNoteText: showNote is false, returning empty');
    return '';
  }
  if (this.viewModel.singleData === null) {
    console.info('SharePreviewPage singleNoteText: singleData is null, returning empty');
    return '';
  }
  const kind = this.viewModel.singleData.recordType === RecordType.WORD ?
    ShareDayKind.WORD : ShareDayKind.BLANK;
  const noteText = resolveShareNoteText(true, kind, this.viewModel.singleData.note);
  console.info(`SharePreviewPage singleNoteText: computed noteText="${noteText}"`);
  return noteText;
}
```

**修改 shareCardContent() 传递字符串**：
```typescript
@Builder
private shareCardContent() {
  console.info(`SharePreviewPage shareCardContent: building, mode=${this.selectedMode}, showNote=${this.showNote}`);

  if (this.selectedMode === DiaryShareMode.SINGLE && this.viewModel.singleData !== null) {
    const noteText = this.singleNoteText;
    console.info(`SharePreviewPage shareCardContent: rendering ShareSingleCard, noteText="${noteText}"`);

    ShareSingleCard({
      noteText: noteText,  // 传递字符串
      localDate: this.viewModel.singleData.localDate,
      recordType: this.viewModel.singleData.recordType,
      content: this.viewModel.singleData.content,
      fontId: this.viewModel.singleData.fontId,
      paperId: this.viewModel.singleData.paperId
    })
  }
  // ... 七日分享保持 includeNote 布尔值（暂不修改）
}
```

**移除 key 属性**：
```typescript
@Builder
private shareCard() {
  console.info(`SharePreviewPage shareCard: building with id=${SHARE_CARD_COMPONENT_ID}`);

  Stack() {
    this.shareCardContent()
  }
  .id(SHARE_CARD_COMPONENT_ID)  // ID 稳定
  .backgroundColor(this.activePaperColor)
  // 不再使用 .key()
}
```

### 2. ShareSingleCard 修改

**修改接口，接收字符串**：
```typescript
@Component
export struct ShareSingleCard {
  @Prop noteText: string = '';  // 改为字符串
  @Prop localDate: string = '';
  @Prop recordType: RecordType = RecordType.WORD;
  @Prop content: string = '';
  // 移除 @Prop note: string = '';
  // 移除 @Prop includeNote: boolean = false;
  @Prop fontId: string = 'system_serif_dev';
  @Prop paperId: string = 'warm_paper_dev';
  // ...
}
```

**简化 getter**：
```typescript
get shouldShowNote(): boolean {
  const shouldShow = this.noteText.length > 0;
  console.info(`ShareSingleCard shouldShowNote: noteText="${this.noteText}", shouldShow=${shouldShow}`);
  return shouldShow;
}

// 移除 visibleNote getter，直接使用 this.noteText
```

**修改渲染逻辑**：
```typescript
if (this.shouldShowNote) {
  console.info(`ShareSingleCard build: rendering note area, noteText="${this.noteText}"`);
  Column({ space: 6 }) {
    Row().width(28).height(1).backgroundColor(this.secondaryColor)
    Text(this.noteText)  // 直接使用 noteText
      .width(238)
      .fontSize(12)
      // ...
  }
}
```

### 3. ShareImageService 修改

**添加详细日志**：
```typescript
async shareCard(
  uiContext: UIContext,
  context: common.UIAbilityContext,
  componentId: string,
  fileName: string
): Promise<void> {
  console.info(`ShareImageService shareCard: start, componentId=${componentId}, fileName=${fileName}`);
  this.cleanup();

  console.info(`ShareImageService shareCard: getting component snapshot for id=${componentId}`);
  const pixelMap = await uiContext.getComponentSnapshot().get(componentId, {
    scale: 3,
    waitUntilRenderFinished: true
  });
  console.info('ShareImageService shareCard: component snapshot obtained successfully');

  // ... 打包和分享
  console.info('ShareImageService shareCard: image packed successfully');
  // ... 释放资源
  console.info('ShareImageService shareCard: resources released');
}
```

### 4. 背景不透明处理

在分享卡片的 Stack 上直接设置 backgroundColor：

```typescript
// ShareSingleCard 和 ShareScrollCard
Stack() {
  Image(this.paperBackground)  // 纸张纹理
  Column() { /* 内容 */ }
}
.width(286)
.height(440)
.backgroundColor(this.paperId === 'plain_ash_dev' ? '#F7F7F5' : '#FDF8F7')  // 不透明背景
.border({ width: 1, color: this.paperId === 'plain_ash_dev' ? '#E5E5E2' : '#EEE5E1' })
.borderRadius(2)
```

**背景色映射**：
- `plain_ash_dev`（素灰风）→ `#F7F7F5`
- `warm_paper_dev`（纸墨风）→ `#FDF8F7`

## 数据流图

```
用户点击 Toggle
    ↓
SharePreviewPage.showNote 更新 (@State)
    ↓
singleNoteText getter 重新计算
    ↓
shareCardContent() 重新构建
    ↓
ShareSingleCard 接收新的 noteText
    ↓
shouldShowNote 返回新值
    ↓
条件渲染更新 UI
```

## 日志追踪点

### 正常流程的日志序列

**切换备注开关**：
```
SharePreviewPage Toggle onChange: isOn=true, before showNote=false
SharePreviewPage Toggle onChange: after showNote=true
SharePreviewPage singleNoteText: computed noteText="这是一条备注"
SharePreviewPage shareCardContent: building, mode=SINGLE, showNote=true
SharePreviewPage shareCardContent: rendering ShareSingleCard, noteText="这是一条备注"
ShareSingleCard aboutToAppear: noteText="这是一条备注", localDate=2026-08-28
ShareSingleCard shouldShowNote: noteText="这是一条备注", shouldShow=true
ShareSingleCard build: rendering note area, noteText="这是一条备注"
```

**点击分享**：
```
SharePreviewPage shareCurrentCard: start, mode=SINGLE, showNote=true
SharePreviewPage shareCurrentCard: calling imageService.shareCard, fileName=oneword-single-share.png, componentId=oneword_share_card
ShareImageService shareCard: start, componentId=oneword_share_card, fileName=oneword-single-share.png
ShareImageService shareCard: getting component snapshot for id=oneword_share_card
ShareImageService shareCard: component snapshot obtained successfully
ShareImageService shareCard: packing image to file
ShareImageService shareCard: image packed successfully
ShareImageService shareCard: resources released
SharePreviewPage shareCurrentCard: shareCard completed successfully
```

### 异常流程的排查

如果仍然失败，日志会显示在哪个环节出错：

- **快照失败**：
  ```
  ShareImageService shareCard: getting component snapshot for id=oneword_share_card
  SharePreviewPage shareCurrentCard failed: Can't find component...
  ```
  → 检查组件 ID 是否正确设置

- **状态不更新**：
  ```
  SharePreviewPage Toggle onChange: after showNote=true
  SharePreviewPage singleNoteText: showNote is false, returning empty
  ```
  → 检查状态同步问题

## 验证清单

### 功能验证

- [ ] 进入分享预览页面，卡片正确显示
- [ ] 切换"展示备注"开关到打开，卡片立即显示备注内容
- [ ] 切换"展示备注"开关到关闭，卡片立即隐藏备注内容
- [ ] 点击"系统分享"按钮，成功生成并分享图片
- [ ] 导出的图片背景不透明（纸墨风 #FDF8F7 或素灰风 #F7F7F5）
- [ ] 切换单日/七日模式正常工作

### 日志验证

- [ ] Toggle onChange 有日志输出
- [ ] singleNoteText getter 有日志输出
- [ ] shareCardContent 构建有日志输出
- [ ] ShareSingleCard aboutToAppear 有日志输出
- [ ] shouldShowNote 计算有日志输出
- [ ] 备注区域渲染有日志输出
- [ ] 快照流程每个步骤有日志输出

### 边界情况

- [ ] 无备注的记录：显示"这条记录没有备注"
- [ ] 留白记录：备注处理正确
- [ ] 快速切换开关：不崩溃，最终状态正确

## 技术优势

1. **简单可靠**：
   - 单向数据流，父组件计算，子组件渲染
   - 没有复杂的响应式追踪问题
   - 组件 ID 稳定，快照 API 可靠

2. **易于调试**：
   - 关键节点都有日志
   - 可以通过日志追踪完整的数据流
   - 快速定位问题环节

3. **性能良好**：
   - 没有不必要的组件重建（移除了 key）
   - ArkUI 自动 diff 和优化更新
   - 字符串判断比复杂的 getter 更高效

4. **易于维护**：
   - 代码逻辑清晰
   - 职责分离明确
   - 未来扩展方便

## 未来扩展

### 七日分享优化

当前七日分享仍使用 `includeNote: boolean`，未来可以统一为字符串传递：

```typescript
// 父组件计算每一天的备注文本
get sevenDaysWithNoteText(): ShareDayItemWithNote[] {
  return this.viewModel.sevenDays.map(day => ({
    ...day,
    noteText: this.showNote ? resolveShareNoteText(true, day.kind, day.note) : ''
  }));
}

// 传递包含 noteText 的数组
ShareScrollCard({
  days: this.sevenDaysWithNoteText,
  fontId: this.viewModel.sevenFontId,
  paperId: this.viewModel.sevenPaperId
})
```

### 用户自定义背景

Stack 背景色方案已经兼容未来的用户背景图片：

```typescript
Stack() {
  // 底层：纯色背景（保底）
  // 中层：用户背景图片（可选）
  if (this.userBackgroundImage) {
    Image(this.userBackgroundImage)
  }
  // 上层：纸张纹理
  Image(this.paperBackground)
  // 最上层：内容
  Column() { /* ... */ }
}
.backgroundColor(...)  // 纯色保底
```

## 参考文档

- `2026-08-28-share-note-response-and-opaque-background-design.md` - 之前的失败尝试
- `2026-08-27-share-note-and-opaque-export-design.md` - 原始不透明导出设计
- `2026-08-28-share-note-initialization-safety-design.md` - 备注初始化安全修复
