# 分享图片跟随当前主题验收

## 已验证

- 单日分享和最近七日分享统一使用设置仓库解析出的当前主题 `paperId`。
- 单日日记记录中原有的历史 `paperId` 保持不变，只调整分享卡片的显示主题。
- 分享卡片不再覆盖仅支持纸墨、素灰两色的不透明 SVG 底图。
- 卡片背景、正文、次级文字、印章强调色和边框均来自同一当前主题色板。
- 瑰粉主题解析为 `rose_pink_dev`，分享背景色为 `#F8E8EC`。
- 单日分享的上传背景图片层保持原有位置；没有图片或图片加载失败时显示当前主题纯色。
- `git diff --check` 通过。

## 构建与测试

- `hvigorw test --mode module -p module=entry@default` 完成 UnitTestArkTS 编译。
- 新增的当前瑰粉主题分享断言未报告失败。
- 完整测试运行器报告两个既有 `BackupFileGateway` 边界测试失败，分别涉及超限错误映射和空文件读取；失败文件不在本次分享主题修改范围。
- `hvigorw assembleHap --mode module -p module=entry@default -p product=default`：`BUILD SUCCESSFUL`。

## 产物

`OneWord_dev/entry/build/default/outputs/default/entry-default-signed.hap`
