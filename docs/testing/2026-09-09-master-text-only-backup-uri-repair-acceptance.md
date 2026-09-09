# master 分支备份与导入验收

## 已验证

- `BackupCodec` 固定生成 v1 纯文字备份，单文件上限 5 MiB、最多 10000 条记录。
- 含本机 `backgroundImageId` 的日记导出后不含 `background_image`、图片 ID 或 Base64 数据。
- 导入的新记录使用 `backgroundImageId: null`；冲突日期跳过并保留本机正文、备注和背景。
- v2 图片备份返回 `UNSUPPORTED_VERSION`，不会写入数据库或图片存储。
- `DocumentUriBackupFileGateway` 通过文档 URI 文件描述符执行 `open/stat/read/write/close`，覆盖分块、部分读写、大小上限和错误映射。
- master 的背景图片服务、数据库字段、启动清理和页面展示路径继续保留。
- `assembleHap` 成功，产出签名 HAP。

## 当前环境限制

Hypium 运行阶段在本机 RichPreviewer 启动时失败：ArkCompiler 无法申请 1.5 GiB 连续虚拟内存（Windows 错误 1455）。ArkTS 单测编译阶段完成；失败发生在测试运行器初始化，已有结果文件未报告测试断言失败。建议在 DevEco Studio 或真机上执行导出、覆盖导出、导入、取消、损坏文件、超限文件和 v2 拒绝场景。
