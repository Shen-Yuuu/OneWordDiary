# 单日分享恢复历史主题验收

## 已验证

- `ShareViewModel.activePaperId` 在单日模式返回日记记录保存的历史 `paperId`。
- 从文字长卷进入旧日记详情后发起分享，会沿用该记录的历史主题。
- 最近七日模式继续返回当前设置主题，整张长图保持统一。
- 测试覆盖当前瑰粉、历史素灰场景：单日背景为 `#EFEFEA`，七日背景为 `#F8E8EC`。
- 上传背景图片优先级、纯色回退和上一轮移除固定 SVG 底图的实现保持不变。
- UnitTestArkTS 编译通过，本次分享主题测试未报告失败。
- 完整测试仍报告两个既有 `BackupFileGateway` 边界用例失败，与本次修改无关。
- signed HAP 构建结果为 `BUILD SUCCESSFUL`。

## 产物

`OneWord_dev/entry/build/default/outputs/default/entry-default-signed.hap`
