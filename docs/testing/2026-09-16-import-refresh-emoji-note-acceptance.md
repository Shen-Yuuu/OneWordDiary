# 导入刷新与备注 Emoji 修复验收

## 已完成

- 备份导入事务成功后，备份页通知根页面立即重新读取今日记录、记录总数和设置。
- 导入失败、取消和导出操作不会发送刷新通知。
- 字素拆分保留肤色修饰符、国旗、组合附加符与 ZWJ Emoji 的完整性。
- 备注普通文字继续使用日记保存的字体，Emoji 使用系统字体并锁定与备注相同的字号。
- 首页记录、确认页、历史详情、文字长卷、单日分享和近七日分享共用同一备注渲染规则。

## 自动验证

- `assembleHap --mode module -p module=entry@default -p product=default --no-daemon`：通过。
- `assembleApp --mode project -p product=default --no-daemon`：通过，已生成签名 APP。
- 新增 Emoji 与普通文字分段测试，覆盖普通 Emoji、肤色 Emoji、国旗、ZWJ 组合 Emoji 和组合附加符。
- `test --mode module -p module=entry@default -p product=default --no-daemon`：`UnitTestArkTS` 编译通过；Windows RichPreviewer 启动后持续无输出，已停止挂起运行器。

## 真机检查

1. 清除当天记录，导入包含当天记录的备份，导入成功后直接返回首页，确认无需重启即可显示。
2. 备注输入 `不想上班😮‍💨但要加油`，依次检查确认页、首页、历史详情、文字长卷与分享图。
3. 分别使用可选字体保存包含 Emoji 的备注，确认中文仍随记录字体变化，Emoji 大小稳定。
