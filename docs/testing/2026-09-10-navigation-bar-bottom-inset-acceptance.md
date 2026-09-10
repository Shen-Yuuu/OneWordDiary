# 导航条底部避让验收

## 已验证

- 新增统一前景底部尺寸 `immersive_bottom_content_offset = 32vp`，高于上架自检要求的 28vp。
- 主页和日记确认页底部控件整体避让 32vp。
- 长卷、详情、分享、设置、备份和隐私页面的前景根容器均使用相同底部尺寸。
- `PaperBackdrop` 与 `DiaryBackground` 没有增加底部间距，主题和图片背景继续覆盖导航条系统区域。
- 顶部沉浸式偏移和窗口全屏设置保持不变。
- 静态检查共确认八个前景容器引用统一底部尺寸。
- `git diff --check` 通过。
- `hvigorw assembleHap --mode module -p module=entry@default -p product=default` 构建结果为 `BUILD SUCCESSFUL`。

## 产物

`OneWord_dev/entry/build/default/outputs/default/entry-default-signed.hap`
