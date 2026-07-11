---
manifest_archetype: architecture-root
intent_recovery: gap
---
# 架构恢复清单

<!-- 将本模板渲染为 02-architecture/_manifest.md。这里恢复架构形态与证据；
     系统解释仍在根文档、视图与领域中。声称 covered 前替换 gap 行。 -->

## 架构主干覆盖

| 必答架构问题 | 叙事所有者 | 覆盖 | 证据 | 闭合动作 |
|---|---|---|---|---|
| 当前请求到结果故事与系统环境 | [架构根文档](./README.md) | gap | missing | 追踪一条从入口到可见结果的真实当前路径 |
| 运行时所有者与边界理由 | [架构根文档](./README.md) | gap | missing | 验证状态、生命周期、契约与失败所有权 |
| 跨所有者流程、状态、信任、恢复与演进 | [架构视图](./views/README.md) | gap | missing | 完成每项适用的视图问题类别 |
| 详细运行时事实 | 各领域 README | gap | missing | 每个运行时所有者链接到唯一领域 |
| 全局不变量及其压力 | [架构根文档](./README.md) | gap | missing | 在所有受影响所有者上验证执行 |

## 唯一表面所有权

| 表面类别 | 所属领域 | 重叠检查 | 稳定证据 |
|---|---|---|---|
| 对外路由与协议 | unresolved | not-run | 将每个表面映射到唯一运行时所有者 |
| 持久存储与写操作 | unresolved | not-run | 将每次写入映射到一个权威所有者 |
| 用户可见运行时组件与命令 | unresolved | not-run | 将每个适用表面映射到一个所有者 |

## 当前、目标与缺口覆盖

| 范围 | 当前所有者 | 目标所有者 | 开放缺口所有者 | 证据 |
|---|---|---|---|---|
| 全局实现演进 | [当前、目标与缺口](./views/current-target-gap.md) | [当前、目标与缺口](./views/current-target-gap.md) | unresolved | 采用未来设计前先验证当前结论 |

## 冷读证据

| 评审 | 状态 | 分数 | 证据 |
|---|---|---|---|
| 隐藏表格后的架构复述 | needs-review | not-scored | 声称 covered 前记录一次独立评审 |
