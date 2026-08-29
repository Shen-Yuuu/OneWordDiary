# 分享备注响应与不透明背景修复设计

## 目标

修复分享功能的两个核心问题：
1. 点击"展示备注"按钮后，分享图片中的备注内容不显示
2. 导出的 PNG 图片具有透明背景，需要添加不透明底色

## 问题分析

### 问题 1：备注展示无响应

**现象**：
- 用户在分享预览页面切换"展示备注"开关
- Toggle 状态正确更新（`showNote` 变为 `true`）
- 但分享卡片（单日和七日）中的备注内容不显示

**根本原因**：
- `ShareSingleCard` 和 `ShareScrollCard` 使用 `@Prop includeNote` 接收父组件状态
- 当 `includeNote` 变化时，条件渲染块 `if (this.shouldShowNote)` 没有可靠触发重建
- ArkUI 的条件渲染在某些情况下不会自动重新计算 getter 依赖

**受影响代码**：
- `SharePreviewPage.ets:104-123` - shareCardContent() 构建方法
- `ShareSingleCard.ets:137-158` - 备注区域条件渲染
- `ShareScrollCard.ets:52-70` - 备注文本计算

### 问题 2：导出图片透明背景

**现象**：
- 导出的 PNG 文件在某些应用中显示为透明背景
- 分享预览界面看起来有底色，但导出的文件本身是透明的

**根本原因**：
- `ShareImageService.shareCard()` 直接将组件快照打包为 PNG
- 组件快照的 `PixelMap` 保留了 Alpha 通道
- 背景图片资源可能有透明区域

## 解决方案

### 方案 1：条件分支强制重建

将 `shareCardContent()` 中的单个组件调用拆分为两个独立的条件分支，每个分支传入不同的常量值。

**实现位置**：`SharePreviewPage.ets:104-145`

**变更**：
```typescript
// 修改前
@Builder
private shareCardContent() {
  if (this.selectedMode === DiaryShareMode.SINGLE && this.viewModel.singleData !== null) {
    ShareSingleCard({
      includeNote: this.showNote,  // 动态值
      ...
    })
  }
}

// 修改后
@Builder
private shareCardContent() {
  if (this.selectedMode === DiaryShareMode.SINGLE && this.viewModel.singleData !== null) {
    if (this.showNote) {
      ShareSingleCard({
        includeNote: true,  // 常量 true
        ...
      })
    } else {
      ShareSingleCard({
        includeNote: false,  // 常量 false
        ...
      })
    }
  }
}
```

**原理**：
- ArkUI 将 `if (this.showNote)` 的两个分支视为不同的组件实例
- 当 `showNote` 变化时，旧分支被销毁，新分支被创建
- 每个分支传入常量布尔值，避免响应式追踪问题
- 确保 `ShareSingleCard` 和 `ShareScrollCard` 完全重建

### 方案 2：添加纯色背景层

在分享卡片 Stack 的最底层添加纯色 Row 作为不透明背景，确保导出的图片没有透明区域。

**实现位置**：
- `ShareSingleCard.ets:52-59`
- `ShareScrollCard.ets:91-98`

**变更**：
```typescript
// 修改前
build() {
  Stack() {
    Image(this.paperBackground)
      .width(286)
      .height(440)
      .objectFit(ImageFit.Fill)
    ...
  }
}

// 修改后
build() {
  Stack() {
    // 不透明背景底色
    Row()
      .width(286)
      .height(440)
      .backgroundColor(this.paperId === 'plain_ash_dev' ? '#F7F7F5' : '#FDF8F7')
    
    Image(this.paperBackground)
      .width(286)
      .height(440)
      .objectFit(ImageFit.Fill)
    ...
  }
}
```

**原理**：
- Stack 从底到顶渲染：纯色背景 → 纸张图片 → 文字内容
- 纯色 Row 完全不透明，填充整个卡片区域
- 即使纸张图片有透明像素，底层纯色也会显示
- 组件快照包含完整的不透明背景
- 导出的 PNG 自然不透明，无需像素处理

**背景色映射**：
- `plain_ash_dev`（素灰风）→ `#F7F7F5`
- `warm_paper_dev`（纸墨风）→ `#FDF8F7`

## 技术细节

### ArkUI 条件渲染机制

- **常量传递**：传入常量值（`true`/`false`）而非变量（`this.showNote`），避免响应式系统误判
- **分支隔离**：使用 `if/else` 创建两个独立的组件实例，而非一个实例的参数变化
- **强制重建**：条件分支变化时，ArkUI 销毁旧组件并创建新组件

### Stack 层叠渲染

- **渲染顺序**：Stack 子组件按代码顺序从底到顶渲染
- **覆盖关系**：后声明的组件覆盖先声明的组件
- **透明处理**：上层透明区域显示下层内容

### 组件快照行为

- **捕获内容**：快照包含 Stack 的所有可见层
- **Alpha 通道**：保留原始渲染的透明度信息
- **最终结果**：纯色背景 + 纸张纹理 + 文字 = 完全不透明

## 优势与权衡

### 方案优势

**备注响应修复**：
- ✅ 无需 key 属性，更符合声明式 UI 原则
- ✅ 强制组件重建，确保状态同步
- ✅ 代码清晰，易于理解和维护

**背景不透明**：
- ✅ 实现简单，无需像素级操作
- ✅ 性能开销极小（仅多渲染一个 Row）
- ✅ 兼容性强，不依赖特定 API
- ✅ 与未来用户背景图片功能兼容

### 性能影响

**备注响应**：
- **开销**：条件分支切换触发组件重建
- **场景**：用户切换备注开关（低频操作）
- **影响**：可忽略，用户无感知

**背景渲染**：
- **额外绘制**：一个 286×440 的纯色矩形
- **GPU 加速**：现代设备硬件加速，开销极小
- **内存占用**：纯色填充，几乎无额外内存

## 兼容性与未来扩展

### 未来用户背景图片支持

设计已考虑用户自定义背景：
- 纯色背景作为最底层保底
- 用户背景图片可插入纯色背景和纸张纹理之间
- 即使用户图片有透明区域，纯色背景也能填补
- 渲染顺序：纯色 → 用户背景 → 纸张纹理 → 内容

### 多主题支持

- 背景色与 `paperId` 动态绑定
- 新增主题只需扩展颜色映射
- 无需修改渲染逻辑

## 验证清单

### 功能验证

- [ ] 单日分享：切换备注开关，卡片正确显示/隐藏备注
- [ ] 七日分享：切换备注开关，卡片正确显示/隐藏备注
- [ ] 有备注记录：开启时显示真实备注内容
- [ ] 无备注记录：开启时显示"这条记录没有备注"
- [ ] 留白记录：备注处理正确
- [ ] 导出图片：背景完全不透明
- [ ] 纸墨风：背景色正确（#FDF8F7）
- [ ] 素灰风：背景色正确（#F7F7F5）
- [ ] 切换单日/七日：卡片正确重建

### 边界情况

- [ ] 快速切换开关：不崩溃，最终状态正确
- [ ] 连续导出：文件正确生成
- [ ] 预览与导出一致：导出图片与预览显示相同

### 代码质量

- [ ] ArkTS 类型检查通过
- [ ] 无 any 类型使用
- [ ] 资源正确释放
- [ ] 异常路径处理完整

## 非目标

本次修复**不包括**：
- 修改分享卡片布局或样式
- 更改备注文本处理逻辑（resolveShareNoteText）
- 添加新的分享模式或选项
- 优化分享预览加载速度
- 添加图片质量或尺寸选项
- 实现复杂的像素级合成算法

## 参考设计文档

- `2026-08-27-share-note-and-opaque-export-design.md` - 原始不透明导出设计
- `2026-08-28-share-note-initialization-safety-design.md` - 备注初始化安全修复
