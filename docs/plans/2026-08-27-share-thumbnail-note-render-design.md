# 分享缩略图与七日备注渲染设计

## 目标

修复分享后的图片缩略图全黑，以及最近七日分享开启“展示备注”后只有节点位置轻微变化、备注文字仍不显示的问题。

## 已确认原因

- 主分享图片点开后显示正常，故障集中在应用额外生成并传入 Share Kit 的低清 JPEG thumbnail。组件快照包含透明像素时，JPEG 编码会以黑色合成，形成黑底缩略图。
- 七日分享页的开关和状态文案均正常变化，说明 showNote 页面状态有效。七日记录节点仍依赖 ScrollDisplayItem 内部的 showNote 与 note 字段刷新，ArkUI 复用了旧节点子树；外层高度计算更新，所以日期只发生轻微位移。

## 分享图片

ShareImageService 只生成一次高分辨率 PNG，并在关闭文件后把 URI 交给 Share Kit。不再创建第二份低清 PixelMap、JPEG ImagePacker 或自定义 thumbnail。

HarmonyOS Share Kit 在图片分享未传 thumbnail 时会使用原图作为预览图。这样既移除透明 PixelMap 转 JPEG 的黑底路径，也避免自定义缩略图 32KB 上限。

参考：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V13/share-utd-image-V13

## 七日备注

ScrollRecordNode 新增两个独立基础属性：

- noteVisible: boolean
- noteText: string

节点高度、备注条件分支、无备注提示和无障碍文本统一读取这两个属性，不再把嵌套的 item.showNote 作为刷新信号。

ScrollPage 继续从现有 ScrollDisplayItem 传入这两个属性。ShareScrollCard 则直接根据 includeNote 和日期类型传入：

- 已记录日期且开关开启：noteVisible = true。
- 有备注：noteText 为真实备注。
- 无备注：noteText 为空，由节点显示“这条记录没有备注”。
- 缺失日期或开关关闭：noteVisible = false。

SharePreviewPage 对七日分享使用明确的开启/关闭条件分支，使 ArkUI 替换整个七日卡片子树。ShareScrollCard 内部也以 revision 和备注状态构造稳定且不同的节点键。

备注区域使用固定高度与明确宽度，避免在半宽内容栏中被压缩为零高。卡片总高度继续使用与节点相同的备注显示规则。

## 不变范围

- 不修改 RDB、日记正文或备注数据。
- 不增加权限、依赖、网络能力或持久化设置。
- 分享文件仍为 PNG，系统分享目标和选择方式不变。
- 单日分享的视觉设计与备注逻辑保持不变。

## 验证

- 最近七日关闭备注时保持紧凑布局。
- 开启备注后，有备注显示真实内容，无备注显示提示，缺失日期不显示备注。
- 开关反复切换时，卡片高度、轴线和节点内容同步变化。
- 生成并分享单日和七日 PNG，接收端未点开缩略图不再全黑，点开后的原图保持清晰。
- 运行 ArkTS 本地测试和 Debug HAP 编译，并在 Local Emulator 上完成运行时复验。
