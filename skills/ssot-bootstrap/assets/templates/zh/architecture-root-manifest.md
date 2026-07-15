---
manifest_archetype: architecture-root
intent_recovery: gap
---
# 架构恢复清单

<!-- 写作对象默认是 implementation-delegator。本文件只做具体路由登记表；
     路径与内部标签出现前，先链接到平实语言讲清的系统故事。 -->

<!-- 将本模板渲染为 02-architecture/_manifest.md。这里恢复架构形态与证据；
     系统解释仍在根文档、视图与领域中。声称 covered 前替换 gap 行。 -->

## 架构主干覆盖

覆盖与证据栏保留协议值：`gap` 表示仍有缺口，`missing` 表示证据缺失；完成后要
用真实状态和证据替换，不能把初始值当成结论。

| 必答架构问题 | 唯一叙事所有者 | 覆盖 | 证据 | 闭合动作 |
|---|---|---|---|---|
| 当前请求到结果故事与系统环境 | [架构根文档](./README.md) | gap | missing | 追踪一条从入口到可见结果的真实当前路径 |
| 运行时所有者与边界理由 | [架构根文档](./README.md) | gap | missing | 验证状态、生命周期、契约与失败所有权 |
| 跨所有者流程、状态、信任、恢复、部署、观测与演进 | [架构视图](./views/README.md) | gap | missing | 完成每项适用的视图问题类别 |
| 详细运行时事实 | 各领域 README | gap | missing | 每个运行时所有者链接到唯一领域 |
| 全局不变量及其压力 | [架构根文档](./README.md) | gap | missing | 在所有受影响所有者上验证执行 |
| 适用 Q01-Q21 条件的执行与运维后果 | [STATUS](../STATUS.md#质量风险与治理)链接的架构所有者 | gap | missing | 从每项适用产品含义追踪到执行、观测、恢复与具名缺口所有者 |

## 运行时所有者清单

<!-- 每个直接编号架构目录保留一行。`Owner ID` 在 SSOT 内稳定。`runtime` 拥有
     独立当前运行时边界；`support` 解释当前支撑关注点但不假装拥有该边界；
     `target` 属于预期设计，不能作为当前证据。源码目录或团队名称本身不足以
     构成所有者。 -->

| 所有者 ID | 所有者类别 | 叙事所有者 | 当前状态 | 证据或闭合 |
|---|---|---|---|---|
| `owner:<slug>` | `runtime`（当前运行时）/ `support`（支撑）/ `target`（目标） | [所有者](./NN-<domain>/README.md) | 契约 / 设计 / POC / 债务 / 混合 | `闭合: <可证伪边界或证据条件>` |

## 产品到运行时桥接

<!-- 从 01-product/_manifest.md 精确复制每个产品表面 ID 一次，包括 target 与
     out。current/limited/target 使用已登记 owner ID，target 可路由到 target
     类 owner；out 在三个架构格中都写具名 not_applicable 处置。这也包括
     command、public-interface、output-artifact、notification 与
     help-onboarding 表面，不只页面和控件。 -->

| 产品表面 ID | 运行时所有者 ID | 契约或状态边界 | 失败或运维视图 |
|---|---|---|---|
| `surface:<current-or-target-slug>` | `owner:<slug>` | `path::symbol` 或计划边界 | [失败与恢复](./views/failure-and-recovery.md)或[当前目标缺口](./views/current-target-gap.md) |
| `surface:<out-slug>` | `not_applicable: <理由>` | `not_applicable: <理由>` | `not_applicable: <理由>` |

## 唯一技术表面清单

<!-- 每个关键技术表面分配稳定 `tech:<slug>`。允许的类型只有 `entry`、
     `write-store`、`contract`、`operator-surface` 与 `external-integration`。
     每行路由到一个叙事所有者；共同使用不等于共同拥有。把该行同步到对应
     owner 的 manifest，解决重叠后才能声称 covered。 -->

| 技术表面 ID | 表面类型 | 叙事所有者 | 当前状态 | 稳定锚点 | 证据或闭合 |
|---|---|---|---|---|---|
| `tech:<slug>` | `entry`（入口）/ `write-store`（写入存储）/ `contract`（契约）/ `operator-surface`（操作者表面）/ `external-integration`（外部集成） | `owner:<slug>` | `contract`（契约）/ `design`（设计）/ `poc`（概念验证）/ `debt`（债务）/ `mixed`（混合） | `src/...::symbol` | 证据或 `闭合: <条件>` |

## 技术表面类别处置

<!-- 以下五类各保留一行。applicable 至少列一个同类已登记 tech ID；
     not_applicable 写具体原因且不能有该类登记行，不能为了填表伪造表面。 -->

| 表面类型 | 处置 | 已登记表面 | 处置原因 |
|---|---|---|---|
| `entry`（入口） | applicable / not_applicable | `tech:<slug>` / none | |
| `write-store`（写入存储） | applicable / not_applicable | `tech:<slug>` / none | |
| `contract`（契约） | applicable / not_applicable | `tech:<slug>` / none | |
| `operator-surface`（操作者表面） | applicable / not_applicable | `tech:<slug>` / none | |
| `external-integration`（外部集成） | applicable / not_applicable | `tech:<slug>` / none | |

## 当前、目标与缺口覆盖

| 范围 | 当前所有者 | 目标所有者 | 开放缺口所有者 | 证据 |
|---|---|---|---|---|
| 全局实现演进 | [当前、目标与缺口](./views/current-target-gap.md) | [当前、目标与缺口](./views/current-target-gap.md) | `unresolved`（未解决） | 采用未来设计前先验证当前结论 |

## 冷读证据

<!-- 把 `reader-review.md` 渲染到 `SSOT/.bootstrap/`，再记录真实分数、事实错误、
     必要改动与结论。评审精确覆盖 C01-C09、A01-A18 与 Q01-Q21。 -->

| 评审范围 | 产物 | 分数 | 严重事实错误 | 未解决必要改动 | 结论 |
|---|---|---|---|---|---|
| 隐藏表格后的架构 | `SSOT/.bootstrap/<review-file>.md` | `not-scored`（未评分）/32 | `not-counted`（未计数） | `not-counted`（未计数） | `needs-review`（需要评审） |
