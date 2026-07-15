---
manifest_archetype: product-root
intent_recovery: gap
---
# 产品恢复清单

<!-- 写作对象默认是 implementation-delegator。单元格保持简短具体；内部标签
     出现前，先链接到平实语言写成的叙事。 -->

<!-- 将本模板渲染为 01-product/_manifest.md。这里只做恢复索引，不承载产品
     叙事。把 gap 行替换为仓库真实证据后，才能把 intent_recovery 改为
     covered；正文只留在唯一所有者。 -->

## 产品主干覆盖

初始协议值 `gap`、`not_assessed`、`missing` 分别表示有缺口、尚未评估、证据缺失；
恢复真实产品事实后必须替换这些初始值。

| 必答产品问题 | 唯一叙事所有者 | 恢复覆盖 | 证据核实后的产品成熟度 | 证据保真度 | 闭合证据或所有者 |
|---|---|---|---|---|---|
| 目的、受众、当前承诺、产品表面与非目标 | [产品简介](./prd.md) | gap | not_assessed | missing | 对照当前产品资料与真实可达表面验证 |
| 人、对象、生命周期、访问、隐私与语言 | [产品模型](./product-model.md) | gap | not_assessed | missing | 验证产品对象、政策与用户预期 |
| 持久用户结果 | [产品能力](./capabilities/README.md) | gap | not_assessed | missing | 盘点稳定能力及其验收含义 |
| 主路径、选择、控制、恢复与诊断 | [产品旅程](./journeys/README.md) | gap | not_assessed | missing | 从当前体验建立旅程覆盖 |
| 阶段意图、验收与产品级缺口 | [路线图与验收](./roadmap-and-acceptance.md) | gap | not_assessed | missing | 链接可观察门槛与具名闭合所有者 |
| 非页面表面与适用 Q01-Q21 的产品含义 | [STATUS](../STATUS.md#质量风险与治理)链接的产品所有者 | gap | not_assessed | missing | 把 P21 与每个适用 Q 项路由到平实的产品含义和可见验收 |
| 持续价值与反馈学习闭环 | [产品简介](./prd.md#持续价值与反馈闭环) | gap | not_assessed | missing | 把 P23 路由到当前指标、反指标、反馈回到路线图的流程、隐私边界与复核触发；不得编造数字 |

## 产品表面清单

<!-- 每个用户或操作者实际可到达的表面分配稳定 `surface:<slug>`。允许的类别
     只有 `page`、`navigation`、`entry-mode`、`control`、`settings`、
     `diagnostic`、`external-channel`、`command`、`public-interface`、
     `output-artifact`、`notification` 与 `help-onboarding`。每个适用表面单独一行。
     每个类别只能二选一：有真实表面，或恰好一行带具体理由的 `not_applicable`；
     不能同时出现真实与不适用，也不能为同一类写两行不适用。current/limited 的源锚点必须解析
     到实现；尚无代码的计划表面使用 `planned_in: [路线图 owner](...)`、
     `target`、`missing` 与可证伪闭合，不能伪造源码路径。正文、旅程、验收与
     架构复用同一 ID。 -->

| 表面 ID | 表面类别 | 源表面锚点 | 产品所有者 | 产品成熟度 | 证据保真度 | 稳定证据或闭合 |
|---|---|---|---|---|---|---|
| `surface:<slug>` | `page`（页面）/ `navigation`（导航）/ `entry-mode`（进入方式）/ `control`（控件）/ `settings`（设置）/ `diagnostic`（诊断）/ `external-channel`（外部渠道）/ `command`（命令）/ `public-interface`（公共接口）/ `output-artifact`（输出产物）/ `notification`（通知）/ `help-onboarding`（帮助与上手） | `src/...::symbol` / `planned_in: [路线图](./roadmap-and-acceptance.md#anchor)` / `not_applicable: <理由>` | [产品所有者](./prd.md) | `current`（当前）/ `limited`（受限）/ `target`（目标）/ `out`（不在产品内） | `browser`（浏览器实机）/ `integration`（集成）/ `unit`（单元）/ `static`（静态）/ `missing`（缺失） | 证据指针或 `闭合: <可证伪条件>`；缺少类别使用 `out` + `static` + 处置理由 |

## 资料主题处置

| 资料主题 | 处置 | 唯一产品所有者 | 证据或闭合 |
|---|---|---|---|
| 尚未审阅的产品资料集 | gap | [产品简介](./prd.md) | 将每项重要主题归为 `absorbed`（已吸收）、`linked`（已链接）、`rejected-stale`（拒绝过时内容）或 `gap`（缺口） |

## 冷读证据

<!-- 把 `reader-review.md` 渲染到 `SSOT/.bootstrap/`，再记录真实分数、事实错误、
     必要改动与结论。评审精确覆盖 C01-C09、P01-P23 与 Q01-Q21。 -->

| 评审范围 | 产物 | 分数 | 严重事实错误 | 未解决必要改动 | 结论 |
|---|---|---|---|---|---|
| 隐藏表格后的产品 | `SSOT/.bootstrap/<review-file>.md` | `not-scored`（未评分）/32 | `not-counted`（未计数） | `not-counted`（未计数） | `needs-review`（需要评审） |
