---
manifest_archetype: architecture-views
intent_recovery: gap
---
# 架构视图恢复清单

<!-- 将本模板渲染为 02-architecture/views/_manifest.md。每个适用的跨所有者
     问题保留一行。合并或不适用的视图必须说明原因并指定叙事所有者。 -->

## 跨所有者问题覆盖

| 问题类别 | 叙事所有者 | 覆盖 | 证据或闭合 |
|---|---|---|---|
| 压力、优先级、取舍与技术非目标 | [运行模型](./operating-model.md) | gap | 对照产品约束、决策与领域验证 |
| 当前请求到结果路径及可见结果 | [关键旅程](./critical-journeys.md) | gap | 跨所有者追踪关键当前旅程 |
| 状态所有权、转移、保留、重建与恢复 | [状态与数据生命周期](./state-and-data-lifecycle.md) | gap | 验证模式、存储、投影与恢复 |
| 契约、认证、权限、秘密与脱敏 | [契约与信任边界](./contracts-and-trust-boundaries.md) | gap | 验证对外与内部信任边界 |
| 检测、重试、取消、重启、降级与诊断 | [失败与恢复](./failure-and-recovery.md) | gap | 运行有代表性的跨所有者失败 |
| 当前实现、预期设计与具名缺口 | [当前、目标与缺口](./current-target-gap.md) | gap | 链接当前证据、决策与闭合所有者 |

## 视图与领域一致性

| 抽样视图结论 | 唯一领域所有者 | 一致性结果 | 证据 |
|---|---|---|---|
| 尚未抽样结论 | unresolved | needs-review | 声称 covered 前抽样每个视图 |

## 冷读证据

| 评审 | 状态 | 分数 | 证据 |
|---|---|---|---|
| 隐藏表格后的跨所有者视图复述 | needs-review | not-scored | 所有适用问题类别填充后评审 |
