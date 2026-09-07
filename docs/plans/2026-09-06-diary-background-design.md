# 每日日记背景图设计

日期：2026-09-06。用户已确认本方案，授权直接实施并由主智能体验收。

## 产品行为
- 每条日记可选一张本地静态背景图片，与备注一样非必填。选择、更换、移除在编辑区完成。
- 首页编辑/确认可预览草稿；保存后的首页、历史详情、单日分享图片展示对应记录的全幅背景，等比居中裁切并加适度遮罩确保文字可读。
- 未记录且没有当前选择、未选择图片的日记、图片读取失败均回退现有纯色。跨日不继承图片。七日分享与长卷列表保持原样。
- 背景跟随现有提交/修订规则，不增加历史修改入口，不改变文字、备注、字体、导航、提醒或隐私同意流程。
- 本期静态图片；检测多帧图片后明确提示暂不支持动态图，禁止无提示截取第一帧。

## 架构和不变量
- DailyRecord、DiaryEntryInput、NormalizedDiaryEntry 增加 backgroundImageId?: string | null，缺失统一视作 null，RDB 增加 nullable background_image_id，事务升级保留旧数据。
- 图片由 BackgroundImageService 管理，存于 filesDir/diary-backgrounds，使用应用生成的唯一文件名；数据库只存文件名标识，禁止外部路径与临时相册 URI 入库。
- 图片选择后验证真实编码、帧数、字节和尺寸上限，按长边最多 2048 像素编码静态 JPEG（透明图使用明确底色或保留 PNG），去除来源元数据。资源在 finally 释放。
- 每次导入生成新标识，不覆盖现有文件。草稿取消/替换清理未提交文件；提交失败保留可重试草稿；保存成功后才允许清理旧图。启动清理无引用残留只在没有活跃草稿时执行。
- 图片错误不能阻止无图日记继续使用。图库取消静默处理。异步选择结果按草稿版本与日期检查，过时结果不得附到另一日。
- 备份升级为携带图片数据的自包含格式，同时导入旧版纯文字备份。完整预检、总量上限、冲突日期保留本地，文件写入失败回滚新文件，数据库失败不损伤原有图片。
- 清空全部数据包含背景目录，延续 reset_pending 恢复机制。

## 服务接口契约
BackgroundImageStore 在 model/BackgroundImage.ets 定义，BackgroundImageService 实现：
```ts
export interface BackgroundImageStore {
  importFromUri(uri: string): Promise<string>;
  resolveUri(id: string | null | undefined): string;
  remove(id: string): void;
  clearAll(): void;
}
```
AppServiceContainer.getBackgroundImageService() 返回 BackgroundImageService；初始化时注入备份与清空服务。
TodayViewModel 增加可选第七参数 BackgroundImageStore，供 UI 注入并允许原有测试无图运行；提供 draftBackgroundImageId、backgroundImageUri getter、isPickingBackground、backgroundError、async selectBackgroundFromUri(uri)、removeBackgroundImage()。UI 负责系统选择器，VM 负责异步导入和草稿生命周期。
DetailViewModel 与 ShareViewModel/ShareCardData 传递 backgroundImageId；UI 经服务 resolveUri 后展示。分享等待背景加载完成，失败回退纯色并允许重试，不输出半加载图片。

## 验收
- 自动测试：旧记录默认无图；两日期不同图片互不影响；保存、修订、移除、取消与失败重试；跨日异步回调失效；详情/单日分享数据一致；七日分享回归；备份新版往返、旧版兼容、非法图片与路径拒绝、冲突与回滚。
- 运行全量现有 Hypium 测试和 Debug HAP 构建。
- 可用设备上验证相册选择、重启恢复、编辑与历史详情、单日分享实际 PNG、深浅色/无图对照和按钮可用性；无法完成的真机项明确记录，不宣称完美验收。

## 实施落地（2026-09-07）
- 数据库版本升级为 2；记录的 schemaVersion 保持原有语义。旧记录新增图片列为 NULL。
- 源图片上限 20 MiB、80 × 1024 × 1024 像素；归一化后长边不超过 2048、单张不超过 5 MiB。保留透明通道时使用 PNG，其余编码 JPEG。
- 多帧图片明确拒绝。原生界面支持动态图有可行性，但当前分享产物是静态 PNG，动画导出及跨页面一致性需要额外实现与设备验证，因此本期不提供动态图功能。
- 无图片的导出继续使用 v1（5 MiB），有图片使用 v2 自包含 JSON（64 MiB），最多 10000 条记录。导出对所引用图片执行格式、帧数、尺寸和解码校验，缺失或损坏时整体报错；导入重建新 ID，避免重复 JPEG 压缩。
- 图片导入使用清空代际检查，清空前开始的异步处理不得在清空后写回文件。失败清理保留 reset_pending，启动重试。
- 首页在本地午夜刷新，保存期间短暂推迟，回到前台重排定时器。图库返回时同时检查操作起始日期和当前日期。
- 单日分享等待解码完成，2.5 秒未就绪则回退纯色并提供重试；使用 URI 与加载代次过滤过期事件。保留原有不透明底板，七日分享不加背景图。
- 自动测试不等同于 ImageKit、图库和 componentSnapshot 的真机验收，设备检查项见验收记录。
