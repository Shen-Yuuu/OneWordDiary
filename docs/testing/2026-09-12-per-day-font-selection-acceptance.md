# 每日日记字体选择验收

## 已完成

- 设置页新增六种字体：默认字体、得意黑楷体、呆萌手写体、悠然小楷体、汇文明朝体、云峰飞云体。
- 字体选择通过 Preferences 独立持久化，不再由主题颜色决定。
- 当天未提交的正文和备注会使用当前字体；从设置页返回时会保留同一天的草稿并刷新字体。
- 新记录在提交时保存字体编号；修订记录在重新提交时保存当前字体编号；修改设置不会改变未修订的历史记录。
- 首页已记录内容、详情、文字长卷、单日分享和七日分享均按记录字体编号渲染。七日分享允许每天使用不同字体。
- 旧字体编号 `system_serif_dev`、`system_sans_dev` 继续解析为默认字体；未知编号回退默认字体。
- 备份格式保持 text-only v1，只写字体编号，不写字体文件或背景图片。纸张与字体改为独立校验。
- 清空全部数据会同时恢复默认主题与默认字体。

## 字体资源验证

- 五个用户提供的 `.ttf` / `.otf` 文件均可由 fontTools 解析。
- 字符映射数量：呆萌手写体 7800、汇文明朝体 14086、悠然小楷体 6956、得意黑楷体 9440、云峰飞云体 6896。
- 设置页名称、字体名称和“静、雨、风、瑰、粉”等验收字符在五个字体中均存在。
- 签名 HAP 清单确认包含现有两款 OneWord Kai 与五款新增字体。
- 已移除 `YunfengFeiyun.ttf` 原文件的只读属性，避免 Windows 重复构建时无法清理资源缓存。

## 自动验证

- `hvigorw test --mode module -p module=entry@default -p product=default --no-daemon`：`UnitTestArkTS` 编译完成，本次新增和修改的字体功能用例未报告失败。
- 完整测试运行器仍报告仓库已有的两个 `BackupFileGateway.test.ets` Windows 文件边界用例失败；同一问题已记录于 2026-09-10 的两份分享功能验收中，本次未修改该网关。
- `hvigorw assembleHap --mode module -p module=entry@default -p product=default`：`BUILD SUCCESSFUL`。
- `hvigorw assembleApp --mode project -p product=default`：`BUILD SUCCESSFUL`。
- `git diff --check`：通过。

## 构建产物

- HAP：`OneWord_dev/entry/build/default/outputs/default/entry-default-signed.hap`，约 55.49 MiB。
- APP：`OneWord_dev/build/outputs/default/OneWord_dev-default-signed.app`，约 31.35 MiB。

## 真机检查清单

1. 在设置页依次选择六种字体，确认预览字形不同且重启后仍记住所选项。
2. 输入正文和备注后进入设置切换字体，返回首页，确认草稿未丢失且字形更新。
3. 使用不同字体保存多天记录，确认文字长卷中各天正文和备注保持各自字形。
4. 打开历史详情和单日分享，确认使用该日字体；切换七日分享，确认每天可显示不同字体。
5. 更改默认字体后检查旧日记，确认旧日记不变；修订其中一条并提交，确认只有该条更新字体。
6. 导出并导入包含多种字体的备份，确认文本与字体编号恢复，且备份文件不含字体二进制和背景图片。
