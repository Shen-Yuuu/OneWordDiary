# 背景渲染与系统安全区修复验收记录

日期：2026-09-09。状态：实现、静态审查、自动测试和签名构建完成；真机视觉复验待执行。

## 实现结果

- `DiaryBackground` 不再依赖空 `Row` 的纸色蒙版和中心渐变。背景照片直接使用 `PHOTO_IMAGE_OPACITY = 0.16`，下层 `PaperBackdrop` 提供主题纸色和纸纹。
- 参数只需在 `OneWord_dev/entry/src/main/ets/components/common/DiaryBackground.ets` 文件首行调整。数值越低，照片越淡；建议真机调节范围为 0.10 至 0.22。
- URI 监听、图片加载代次、成功与失败回调、加载完成前隐藏、失败后纯色回退以及上下安全区扩展均保持不变。
- 首页、确认页、历史详情和单日分享共同使用该图片透明度；单日分享已删除局部 0.74 覆盖。
- 编辑页删除背景缩略图。无图显示“选择背景”，有图显示“更换背景”和“移除”；操作按钮使用项目最小触控高度并补充完整无障碍名称。
- 窗口调用改为 `setWindowLayoutFullScreen(false)`。状态栏和导航栏继续透明、系统图标继续使用深色；页面前景恢复系统安全区避让，只有 `PaperBackdrop` 与 `DiaryBackground` 扩展到上下系统区域。

## 自动验证

- Hypium：`Tests run: 70, Failure: 0, Error: 0, Pass: 70, Ignore: 0`。
- 测试日志：`.hvigor/background-rendering-repair-test.log`。
- Debug `assembleHap`：CompileArkTS、PackageHap、PackingCheck 和 SignHap 成功。
- 构建日志：`.hvigor/background-rendering-repair-build.log`。
- 签名产物：`E:\desktop\Code\harmony\OneWordDiary\OneWord_dev\entry\build\default\outputs\default\entry-default-signed.hap`。
- 产物大小：5313647 字节；生成时间：2026-09-09 11:14:42。
- SHA-256：`8244C9695E1C49A7114AC0DD666C35275FA5829768D5F3BEE193477B633AC007`。
- `git diff --check` 通过；修改文本无 U+FFFD；未修改权限、依赖、版本、签名或数据库版本。
- `OneWord_dev/test-data/` 保持为用户原有未跟踪目录，本次未修改或纳入提交。

## 真机待验收

当前 `hdc list targets -v` 只有 UART Ready 条目，没有 Connected 设备，本轮未安装应用或操作真实数据。

1. 使用此前高对比度图片检查首页文字、刷新图标、计数、备注、按钮和底部统计是否清晰。
2. 临时将 `PHOTO_IMAGE_OPACITY` 从 0.16 改为 0.05，分别构建截图；两者必须出现明显的图片强度差异。随后恢复 0.16，证明实际图片节点透明度已进入合成链。
3. 检查确认页、历史详情和单日分享预览及导出 PNG 的图片强度一致。
4. 检查顶部日期、关闭/设置/长卷按钮不再与状态栏时间、电量和挖孔区域重叠。
5. 使用手势导航和三键导航检查底部按钮处于安全区内，同时纸色或照片连续覆盖底部系统区域。
6. 检查选择、更换、移除背景及失败重试，确认删除缩略图没有改变图片业务状态。

## 已知边界

- 自动测试和 ArkTS 编译不能替代真机 GPU 合成与系统栏布局验收。
- 如果 0.05 与 0.16 在真机仍没有明显差异，应直接检查 `Image.opacity` 的设备渲染和安装环境，不再恢复空容器蒙版方案。
