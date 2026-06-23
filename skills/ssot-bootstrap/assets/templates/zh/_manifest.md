## Core recovery manifest

> 本文件是 SSOT 自维护机器的容器，不承载产品/架构叙事。产品/架构叙事在 `README.md` / `prd.md` / `product-model.md` / 对应 capability / journey / domain 等散文文件中。

### Core completeness argument

<!-- 在此说明为什么以下集合是核心集，哪些 near-miss 项被排除，遗漏会导致什么错误结论。 -->

### 核心项

| 核心项 | 所属 owner | 必需 pillar | 当前真相状态 | 证据 / closure owner |
|---|---|---|---|---|
| <!-- 项名称，链接到散文 owner --> | <!-- path 或 anchor --> | `product_intent` / `product_truth` / `not_applicable + 原因` | `contract` / `mixed` / `design` / `debt` / `Out` / `not_applicable` | <!-- evidence 指针或 closure owner --> |

## Apex / Maxim → Owner 索引

<!-- 仅 architecture/_manifest.md 承载。product/ 不包含此节。 -->

| Maxim | 所有者 | DISC / capability / invariant 锚点 |
|---|---|---|
| <!-- 如 CLAUDE-MAXIM-N --> | <!-- 唯一 owner 路径 --> | `[CORE-REF: ...]` |

## Capability → Surface registry

<!-- 仅 architecture/_manifest.md 承载。 -->

| Capability | 路由 + handler | 组件路径 | 测试 |
|---|---|---|---|
| <!-- 名称 + owner 链接 --> | `path:LNN` | `path` | `tests/...` |

## README-self failure modes

<!-- 仅当本 manifest 自身的检测与恢复属"文档漂移"时才存在。 -->

| 失败模式 | 检测 | 恢复 |
|---|---|---|
| <!-- 本 manifest 可能失效的方式 --> | <!-- 自动/人工检测手段 --> | <!-- 恢复操作 --> |

## intent_recovery evidence

| 区域 | 状态 | 最近 cycle | 证据 |
|---|---|---|---|
| <!-- 对应 area --> | `covered` / `partial` / `gap` | `cycle-N` | <!-- trial verdict / cold read date --> |

## adoption-cycle log

| 版本 | 日期 | 范围 | 注释 |
|---|---|---|---|
| v2.48 | 2026-06 | product/ + architecture/ manifest separation | <!-- 记录纳入范围与拓补 --> |