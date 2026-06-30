# PRD 主干

> 行文风格：写给任何冷读者。详见 `ssot-bootstrap` §3.7。

> 简洁产品主线。不要镜像完整外部 PRD；只保留长期产品事实、owner 链接和当前/目标产品姿态。

## 这个产品是什么 [MUST]

用 1–3 段平实的自然语言，回答"这是什么产品 / 谁在用 / 为他解决了什么问题"。至少包含一个具体使用场景或一句话用户故事（"想象一个用户在 X 时刻……"）。术语首次出现要给一句正向定义（"X 是 …"），不能用否定式开场。

## 当前阶段在做什么 / 不做什么 [MUST]

用 1–2 段散文把"当前姿态 → 目标姿态"的故事讲清楚：我们现在能交付什么、下一步要把哪个用户问题解决到什么程度、为什么是这个顺序。

非目标必须解释"为什么不做、什么时候会重新考虑"，不能只是 4 字短语或代号堆叠。下方"关键非目标"表是这段散文的索引。

## 产品姿态

- **当前产品姿态**：
- **目标产品姿态**：
- **主要用户 / 操作者**：
- **核心产品承诺**：
- **关键非目标**：
- **Product owner evidence**：

## 核心 capability 地图

`state` 标签（`contract | design | poc | debt`）告诉冷读 Agent 该 capability 是当下已强制还是愿景；详见 `ssot-bootstrap` §3.7。doctor `[STATE-TAG]` (14V)。

| Capability | 用户价值 | 当前状态 | state | Owner | Acceptance link |
|---|---|---|---|---|---|
| | | current / target / gap / not_applicable | contract / design / poc / debt | [capabilities/README.md](./capabilities/README.md) 或本文件 | [roadmap-and-acceptance.md](./roadmap-and-acceptance.md) |

## 产品范围

| 范围项 | In / Out / Later | 为什么 | Owner / evidence |
|---|---|---|---|
| | | | |

## 关键非目标

| Non-goal | 为什么不做 | 重新考虑条件 | Owner |
|---|---|---|---|
| | | | |

## Owner 链接

| 事实 | Owner | Notes |
|---|---|---|
| Users / problems / promises | [product-model.md](./product-model.md) | |
| Roadmap / product acceptance | [roadmap-and-acceptance.md](./roadmap-and-acceptance.md) | |
| Runtime implementation | [../architecture/README.md](../architecture/README.md) | Architecture 链接到这里；不要在 architecture 中重复维护产品事实 |

## Capability → Surface registry

只有当产品 capability 是该 surface 行的 owner 时才维护本表；否则只链接到
architecture owner，不在这里复制镜像。规则见
`ssot-preflight/references/architecture.md` §16。

| Capability | Route or module | Component | Test | state |
|---|---|---|---|---|

## 证据

| Claim | Source | Confidence | Next action |
|---|---|---|---|
| | PRD / README / user-provided source / release evidence | verified / documented / inferred / unknown | |
