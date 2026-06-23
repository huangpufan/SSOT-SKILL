# 架构视角

> 行文风格：写给任何冷读者。详见 `ssot-bootstrap` §3.7。

> 跨域架构视角。Views 从 domains 进行跨域综合，并吸收源资料中的技术系统目标、运行哲学、runtime journeys 和 implementation current/target/gap；具体所有权、契约、状态和恢复细节必须路由到 domains。产品承诺、capability、journey 和 product acceptance 由 `product/` 拥有，views 只链接 product owner 并记录实现设计或 gap。
>
> Views 是 SSOT 的设计意图层，必须包含叙述性的设计思考，不能只有表格。

## 视角索引

| 视角 | 路径 | 权威职责 | 源资料输入 | 证据 / 状态 |
|---|---|---|---|---|
| 运行模型 | [operating-model.md](./operating-model.md) | 技术使命、运行哲学、原则、实现优先级、技术非目标、technical actors、主要运行路径 | product owner links、设计文档、root README、高层架构文档 | |
| 关键旅程 | [critical-journeys.md](./critical-journeys.md) | runtime journeys、阶段生命周期、failure/recovery、observability signals | product journey links、设计 walkthrough、runbook、源码轨迹 | |
| Current / Target / Gap | [current-target-gap.md](./current-target-gap.md) | 已实现状态与目标设计、迁移立场、implementation gaps、product acceptance 实现差距、裁决指针 | product roadmap/acceptance links、ADR、设计文档、源资料、代码证据 | |

## 跨域快速理解地图 / Reader Map

> Views 的入口地图只做路由，不承载独立长期事实。具体设计意图、旅程和 gap 必须进入对应 view 正文；状态/资源/契约/恢复细节继续下钻到 domains。

| 读者问题 | First stop | Authoritative owner | Evidence direction | Stop condition / risk |
|---|---|---|---|---|
| 理解产品约束如何影响技术设计，技术上优先优化什么 | [operating-model.md](./operating-model.md) | operating-model view + product owner | domains / decisions / product | 原则已链接执行它的 domain owners，产品事实仍在 product |
| 理解哪些端到端路径决定系统是否可用 | [critical-journeys.md](./critical-journeys.md) | critical-journeys view | domains / tests | 每个阶段都有负责状态/契约/恢复的 domain owner |
| 区分当前实现、目标设计和迁移 gap | [current-target-gap.md](./current-target-gap.md) | current-target-gap view | domains / decisions / tech-debt | 每个 concrete gap 都链接 domain/decision/debt/adjudication owner |

## 视角规则

- View 不能只有表格。必须有 `为什么这个视角存在` / 叙述章节解释设计意图。
- Views 回答跨域问题，并从 domain evidence 综合系统意图、旅程和 gap；domains 负责详细状态/资源、契约、不变量、失败恢复和验证。
- 当总览 Mermaid 图能澄清全系统旅程时，view 可以包含这些图。
- View 必须链接到负责具体状态/资源/契约/失败细节的 domain owners。
- Views 必须分离 当前事实 与 目标设计。Current claim 需要代码/配置/schema/test/runtime 证据；target claim 需要 decision、ADR、issue 或 conversation 证据。
- 当 PRD/产品资料包含当前产品优先级、产品非目标和 product acceptance 时，product 必须先吸收；operating-model 只记录技术响应。
- Critical-journeys 必须吸收 runtime execution、failure/recovery 与 observability signals，而不是只列 happy-path flow 名称；用户 touchpoints 和 product acceptance 链接 product journey owner。
- Current-target-gap 必须解释迁移立场和部分落地的意图，而不是只列 gap 行。
- Reader Map、主题候选和 evidence links 必须来自架构分解、读者问题和仓库证据；每个 view 必须补上设计意图、why、约束、风险和 authoritative owner；Reader Map 不承载独立长期事实，不要把外部主题树当成 view 结构本身。

## 源资料路由

| 源资料内容 | 目标视角 | Domain / 卫星区域后续 |
|---|---|---|
| 产品定位、产品目标、产品优先级、产品非目标、产品验收 | `../product/` owner | architecture view 链接 product owner，不复制事实 |
| 技术系统定位、实现优先级、技术非目标、运行哲学、主要 technical actor、非功能成功标准 | [operating-model.md](./operating-model.md) | 链接执行这些原则的 domains 和相关 product owner |
| Runtime 主路径、阶段生命周期、failure/recovery、observability signals | [critical-journeys.md](./critical-journeys.md) | 链接负责各阶段/状态/资源/恢复的 domains |
| Implementation current/target/gap、迁移目标、设计缺口、product acceptance 实现差距 | [current-target-gap.md](./current-target-gap.md) | 链接 product owner、decisions、domains、开放裁决项 |
| 外部生成图、截图、dependency graph 或自动摘要中的候选线索 | 仅在交叉验证后按语义拆入 operating-model / critical-journeys / current-target-gap | 脚本清单默认来自仓库脚本、manifest、CI 和配置；架构行为再链接 domains |

## 开放视角缺口

| 视角 | Gap / unknown | 所需证据 | 阻塞级别 |
|---|---|---|---|
| | | | blocking / non-blocking |
