# 关键旅程

> 行文风格：写给任何冷读者。详见 `ssot-bootstrap` §3.7。

> 跨域运行旅程视角。本文件解释应指导技术设计决策的端到端 runtime paths、lifecycle、failure/recovery 和 observability signals。它从 domain evidence 综合 journey，不拥有具体状态/契约/失败细节，也不重新定义 product journey 或 product acceptance。它必须包含叙述性的技术意图和恢复/观测信号，不能只有流程表。

## 范围

- **负责**：系统/runtime execution、阶段生命周期、跨域总览图、failure/recovery、observability signals 和技术验收信号。
- **链接但不拥有**：用户/操作者 journey、touchpoints、experience constraints 和 product acceptance；这些由 `product/journeys/` 或 product spine 拥有。
- **不负责**：具体状态/资源细节或 domain 内契约；这些应链接到 domains。
- **主要 源资料**：

## 为什么这个视角存在

用 1-3 段说明哪些 runtime journeys 决定系统是否可靠实现产品承诺。用户/操作者视角和系统视角不一致时，链接 product journey owner，并在本文件只描述系统执行路径。

## 叙述 / 模型

在列出 flows 之前，用自然语言解释旅程模型。说明哪个旅程是设计锚点，以及未来变更应如何据此判断。

## 设计意图 / 约束

| 意图或约束 | 适用旅程 | 为什么重要 | 证据 / 来源 |
|---|---|---|---|
| | | | |

## 旅程总览

- **Product journey owner links**：
- **主要 runtime journeys**：
- **次要 runtime journeys**：
- **关键 failure/recovery journeys**：
- **明确不在 architecture 范围内的 product journeys**：

## 旅程图

> Mermaid 代码块是权威内容。此处使用总览图；domain-specific subflows 放入 domain README。

### 外部旅程图候选

> 外部生成图、截图、IDE 依赖图和自动 dependency graph 只作为候选。吸收时必须重写为 current 或 target Mermaid 旅程图，并链接负责各阶段的 domains。

| 候选图来源 | 建议权威 Diagram ID | 旅程 / 阶段 | 需验证内容 | 候选状态 |
|---|---|---|---|---|
| | | | | pending / converted / rejected / obsolete |

### `<JOURNEY-...-CURRENT>`

- **状态**: `current`
- **覆盖内容**:
- **证据**:

```mermaid
sequenceDiagram
  participant Actor
  participant System
  participant Domain
  Actor->>System: <intent>
  System->>Domain: <cross-domain step>
  Domain-->>System: <state/result>
  System-->>Actor: <visible outcome>
```

## 主要旅程

| 旅程 | Product intent / runtime intent | 被触发的设计约束 | 技术验收 / 恢复 / 观测信号 | Product owner / Domain owners |
|---|---|---|---|---|
| | | | | |

## 失败 / 恢复旅程

| 失败旅程 | 检测信号 | 预期恢复 / 降级 | 必须可观测的内容 | Domain recovery owner / tests |
|---|---|---|---|---|
| | | | | |

## 验收标准

| 标准 | 适用对象 | 所需证据 | 频率 / 触发条件 |
|---|---|---|---|
| | | | |

## 相关 Domains

| Domain owner | 负责的旅程阶段 | 负责的状态 / 契约 / 恢复 |
|---|---|---|
| | | |

## 当前 / 目标 / 差距

| 旅程 | 当前行为 | 目标旅程 | Gap / 下一步验证 | 证据 |
|---|---|---|---|---|
| | | | | |

## 证据

| 断言 | 源资料 / 代码 / 运行证据 | 置信度 | 后续动作 |
|---|---|---|---|
| | | verified / documented / inferred / unknown | |
