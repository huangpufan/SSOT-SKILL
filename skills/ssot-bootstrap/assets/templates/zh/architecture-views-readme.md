---
intent_recovery: gap
---
# 架构视图

<!-- 解释本系统为什么需要跨所有者视图。先给出一个任何单个运行时所有者都无法
     独立回答的问题，再说明这些视图怎样让读者追踪流程、状态、信任、恢复与
     演进，同时不复制领域细节。 -->

本目录包含默认的跨所有者解释：

```text
├── operating-model.md
├── critical-journeys.md
├── state-and-data-lifecycle.md
├── contracts-and-trust-boundaries.md
├── failure-and-recovery.md
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
| 哪些设计已落地或仍在移动？ | [当前、目标与缺口](./current-target-gap.md) | 跨所有者实现演进 | 决策、技术债与运行时所有者 |

## 覆盖与例外

<!-- 若合并或增加视图，写出支撑该选择的反复出现的跨所有者问题。沉默不能
     支持“覆盖完整”的结论。 -->

| 问题类别 | 覆盖状态 | 原因或闭合所有者 |
|---|---|---|
| 运行压力与取舍 | covered / gap / not_applicable | |
| 关键端到端旅程 | covered / gap / not_applicable | |
| 状态与数据生命周期 | covered / gap / not_applicable | |
| 契约与信任边界 | covered / gap / not_applicable | |
| 失败与恢复 | covered / gap / not_applicable | |
| 当前、目标与缺口 | covered / gap / not_applicable | |

## 证据方向

<!-- 视图只做综合：当前结论链接领域证据，产品含义链接产品所有者，未来意图
     链接决策。 -->
