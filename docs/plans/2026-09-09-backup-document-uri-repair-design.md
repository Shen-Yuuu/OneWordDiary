# 备份文档 URI 读写修复设计

## 问题

备份页面通过 `DocumentViewPicker` 获取系统文件管理器返回的文档 URI。当前导入实现把该 URI 直接传给只支持应用沙箱路径的 `readTextSync`，在 API 21 真机上读取失败。导出实现用 `READ_WRITE | TRUNC` 打开保存 URI，并假定一次 `writeSync` 会写完全部 UTF-8 内容；这扩大了所需访问模式，也没有处理部分写入。

现有测试从字符串直接进入 `BackupCodec` 或 `BackupService.prepareImportFromText`，没有经过系统 URI、文件描述符和字节读写，因此无法发现此类真机问题。

## 原则

- 文档 URI 是由用户选择动作授予的短期访问能力，不把它当作普通路径解析、转换或长期保存。
- 选择器返回后立即打开 URI，并在同一次操作中完成读写与关闭。
- 文件系统适配与备份领域逻辑分离，使 URI 边界可以独立验证。
- 不申请泛化的存储权限，不改变备份格式、数据库、合并规则或隐私承诺。
- 所有读取和写入都有确定的字节上限、进度检查和资源关闭路径。

## 架构

新增 `BackupFileGateway` 接口与生产实现 `DocumentUriBackupFileGateway`：

- `readUtf8(uri, maxBytes)` 返回 UTF-8 文本。
- `writeUtf8(uri, text, maxBytes)` 完整写入 UTF-8 文本。
- 生产实现是唯一直接调用 `fileIo` 的备份模块。

`BackupService` 通过构造函数接收网关。它仍负责读取记录和设置、调用 `BackupCodec`、计算导入计划以及执行数据库事务，但不再了解 `fileIo` 的 URI 细节。`AppServiceContainer` 负责装配生产网关。

## 导入数据流

1. `BackupPage` 使用带 `UIAbilityContext` 的 `DocumentViewPicker` 选择一个 `.oneword` 文件。
2. 页面把选择器返回的 URI 原样交给 `BackupViewModel`；取消选择正常返回。
3. `BackupService` 调用文件网关读取。
4. 网关以 `READ_ONLY` 调用 `openSync(uri)`，获得文件描述符。
5. 网关对文件描述符查询大小，在分配内存前拒绝超过 5 MiB 的文件。
6. 网关循环调用 `readSync`，直到读满声明长度；零进度或长度变化视为读取失败。
7. 网关按 UTF-8 解码，并始终在 `finally` 中关闭文件。
8. 服务调用现有 codec 完整预检，页面展示导入摘要，用户确认后才进入现有事务。

空文件进入 codec 后按损坏备份处理；无法打开、查询或完整读取映射为 `READ_FAILED`。超限保持 `FILE_TOO_LARGE`，避免被笼统读取错误覆盖。

## 导出数据流

1. 页面显示未加密提示，用户选择保存位置。
2. 服务生成与当前格式完全相同的 UTF-8 JSON，并在写入前检查字节上限。
3. 网关以 `WRITE_ONLY | TRUNC` 打开保存 URI。
4. 网关循环调用 `writeSync`，直到全部 UTF-8 字节写完；零进度或异常映射为写入失败。
5. 网关始终关闭文件；成功后页面才显示导出记录数。

API 21 的保存选择器负责返回可写目标 URI。本次不依赖 API 23 的 `autoCreateEmptyFile`，也不向 URI 打开模式增加未经真机契约证明必需的 `CREATE`。

## 错误和日志

- 选择器取消不显示失败。
- 选择器本身异常继续显示“未选择/未导出文件”。
- URI 打开、读取、写入和关闭异常由领域边界映射为现有可理解错误，不显示 URI、正文或系统堆栈。
- 只有完整写入后才报告成功；导入在完整解码和预检前不改变本机数据。

## 测试与验收

- 用内存文件系统适配器验证部分读取、部分写入、零进度、超限和关闭行为。
- 用假文件网关验证 `BackupService` 的导出、导入、错误保留和往返路径。
- 运行全部 Hypium 测试和 Debug HAP 构建。
- 真机验收必须覆盖：首次导出、覆盖导出、导入刚导出的文件、取消选择、损坏文件、超限文件，以及导入冲突不覆盖本机数据。

当前工作区没有已连接设备时，产物构建通过只能证明编译与自动化测试通过；文档 URI 的最终结论保留为待真机复验。
