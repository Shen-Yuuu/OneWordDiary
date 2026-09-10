# 简约文案与提醒功能隐藏验收

## 已完成

- 备份页删除顶部说明，操作项改为简短的导出与导入描述。
- 备份页只保留同日期不覆盖和未加密备份包含内容两项必要提示。
- 备份成功、失败和处理中状态删除重复标题及修辞性文案。
- 隐私说明页删除宣传标题、提醒说明、重复备份细节和版本口号，保留本机存储、分享与备份、清除数据三项事实。
- 首次隐私同意说明缩短为单句，完整政策入口和同意、拒绝路径保持不变。
- 设置页已隐藏提醒开关、提醒时间、提醒状态和相关弹窗。
- 清空数据提示与进度文案改为直接描述操作结果。
- 应用启动时调用 `ReminderRetirementService`：取消本应用已排程的提醒，并将本地提醒状态保存为关闭。
- 系统取消提醒失败时仍保存关闭状态；整个停用过程不会阻塞应用启动，并会在下次启动时再次尝试。
- 提醒底层实现和持久化字段继续保留，方便以后重新设计。
- 保留设置页原有未提交的“瑰粉/瑰”主题名称修改。

## 自动验证

- `git diff --check` 通过。
- 新增三个提醒停用测试场景：正常停用、重复调用幂等、系统取消失败仍保存关闭状态。
- `hvigorw test --mode module -p module=entry@default` 完成资源与 UnitTestArkTS 编译，没有本次变更引入的 ArkTS 错误。
- 测试运行阶段在 Windows RichPreviewer 启动后持续无输出，已停止挂起进程；该环境问题与项目此前测试记录一致。
- `hvigorw assembleHap --mode module -p module=entry@default -p product=default` 成功。

## 构建产物

`OneWord_dev/entry/build/default/outputs/default/entry-default-signed.hap`

构建结果：`BUILD SUCCESSFUL`。
