---
intent_recovery: gap
---
# 架构视图

<!-- 写作对象：implementation-delegator。从具体跨 owner 问题路由到平实语言
     故事，再使用图、标签或证据。 -->

<!-- 解释本系统为什么需要跨所有者视图。先给出一个任何单个运行时所有者都无法
     独立回答的问题，再说明这些视图怎样让读者追踪流程、状态、信任、恢复与
     演进，同时不复制领域细节。 -->

所有者（owner）是一类事实唯一被解释和维护的位置，不一定指某个人。
运行时所有者（runtime owner）是实际处理请求或持有状态的系统部分。“跨所有者视图”
把多个系统部分之间的流程、状态、信任或恢复关系串起来，但不复制各部分内部
细节。下面的 `_manifest.md` 是供 Agent 恢复和校验使用的机器清单，普通读者可跳过。

本目录包含默认的跨所有者解释：

```text
├── operating-model.md
├── critical-journeys.md
├── state-and-data-lifecycle.md
├── contracts-and-trust-boundaries.md
├── failure-and-recovery.md
├── deployment-and-observability.md
├── current-target-gap.md
└── _manifest.md
```

## 这些视图怎样配合

<!-- 给出一个简短阅读例子：先沿关键旅程理解请求，再去状态与数据视图查看写入，
     去契约视图确认信任边界，最后核对失败恢复与当前目标姿态。 -->

| 读者的问题 | 视图 | 综合什么 | 细节仍由谁负责 |
|---|---|---|---|
| 设计为什么这样优化？ | [运行模型](./operating-model.md) | 压力、优先级、取舍与技术非目标 | 决策与运行时所有者 |
| 结果怎样跨所有者产生？ | [关键旅程](./critical-journeys.md) | 当前端到端路径及可见结果 | 产品旅程与运行时所有者 |
| 信息怎样变化并存续？ | [状态与数据生命周期](./state-and-data-lifecycle.md) | 写入所有权、转移、保留、重建与恢复 | 持久化与运行时所有者 |
| 谁能调用什么，受怎样保护？ | [契约与信任边界](./contracts-and-trust-boundaries.md) | 对外/内部契约、身份、权限、秘密与脱敏 | 契约与政策所有者 |
| 工作无法继续时会发生什么？ | [失败与恢复](./failure-and-recovery.md) | 检测、重试、取消、重启、降级与诊断 | 运行时所有者与运维记录 |
| 系统运行在哪里，操作者怎样知道它的状态？ | [部署与可观测性](./deployment-and-observability.md) | 运行拓扑、改动交付、配置、健康、日志、指标、追踪与回滚 | 运行时所有者与发布/部署所有者 |
| 哪些设计已落地或仍在移动？ | [当前、目标与缺口](./current-target-gap.md) | 跨所有者实现演进 | 决策、技术债与运行时所有者 |

## 覆盖与例外

<!-- 若合并或增加视图，写出支撑该选择的反复出现的跨所有者问题。用 STATUS
     Q01-Q21 把适用跨 owner 关注点路由到最近的已有视图与 domain owner；
     不要固定创建二十一个视图。沉默不能支持“覆盖完整”的结论。 -->

表中的 `covered` 表示该问题已有可信解释与评审，`gap` 表示仍缺答案或证据，
`not_applicable` 表示确实不适用并且同一行写明理由。目录或实现缺失本身是缺口，
不能当成不适用。

| 问题类别 | 覆盖状态 | 原因或闭合所有者 |
|---|---|---|
| 运行压力与取舍 | covered / gap / not_applicable | |
| 关键端到端旅程 | covered / gap / not_applicable | |
| 状态与数据生命周期 | covered / gap / not_applicable | |
| 契约与信任边界 | covered / gap / not_applicable | |
| 失败与恢复 | covered / gap / not_applicable | |
| 部署与可观测性 | covered / gap / not_applicable | |
| 当前、目标与缺口 | covered / gap / not_applicable | |

## 证据方向

<!-- 视图只做综合：当前结论链接领域证据，产品含义链接产品所有者，未来意图
     链接决策。每项适用 Q 综合都要回链 STATUS owner 路由。 -->
