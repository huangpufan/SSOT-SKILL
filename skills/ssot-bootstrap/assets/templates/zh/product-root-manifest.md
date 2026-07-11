---
manifest_archetype: product-root
intent_recovery: gap
---
# 产品恢复清单

<!-- 将本模板渲染为 01-product/_manifest.md。这里只做恢复索引，不承载产品
     叙事。把 gap 行替换为仓库真实证据后，才能把 intent_recovery 改为
     covered；可选机制应直接省略，不保留空表。 -->

## 产品主干覆盖

| 必答产品问题 | 叙事所有者 | 恢复覆盖 | 证据核实后的产品成熟度 | 证据保真度 | 闭合证据或所有者 |
|---|---|---|---|---|---|
| 目的、受众、当前承诺、产品表面与非目标 | [产品简介](./prd.md) | gap | not_assessed | missing | 对照当前产品资料与真实挂载表面验证 |
| 人、对象、生命周期、访问、隐私与语言 | [产品模型](./product-model.md) | gap | not_assessed | missing | 验证产品对象、政策与用户预期 |
| 持久用户结果 | [产品能力](./capabilities/README.md) | gap | not_assessed | missing | 盘点稳定能力及其验收含义 |
| 主路径、选择、控制、恢复与诊断 | [产品旅程](./journeys/README.md) | gap | not_assessed | missing | 从当前体验建立旅程覆盖 |
| 阶段意图、验收与产品级缺口 | [路线图与验收](./roadmap-and-acceptance.md) | gap | not_assessed | missing | 链接可观察门槛与具名闭合所有者 |

## 当前产品表面覆盖

| 表面类别 | 产品所有者 | 覆盖 | 证据保真度 | 闭合动作 |
|---|---|---|---|---|
| 路由、页面与导航 | [产品简介](./prd.md) | gap | missing | 检查真实挂载的产品入口 |
| 创建或进入模式与主要控制项 | [产品简介](./prd.md) | gap | missing | 在用户可见边界运行每个当前模式 |
| 设置与操作者诊断 | [产品模型](./product-model.md) | gap | missing | 为每项适用表面指定所有者或记录合理排除 |
| 外部访问渠道与集成 | [产品旅程](./journeys/README.md) | gap | missing | 验证每个当前渠道及其失败体验 |

## 资料主题处置

| 资料主题 | 处置 | 唯一产品所有者 | 证据或闭合 |
|---|---|---|---|
| 尚未审阅的产品资料集 | gap | [产品简介](./prd.md) | 将每项重要主题归为 absorbed、linked、rejected-stale 或 gap |

## 冷读证据

| 评审 | 状态 | 分数 | 证据 |
|---|---|---|---|
| 隐藏表格后的产品复述 | needs-review | not-scored | 声称 covered 前记录一次独立评审 |
