# 初始化总纲

> 临时协调登记表。初始化完成且停止审查通过后删除 `.bootstrap/`。
> 仅协调者更新此文件；执行子代理不直接编辑。
>
> 本总纲追踪工作进度：`pending`（待处理）、`active`（进行中）、`done`（已完成）、
> `blocked`（受阻）。
> `STATUS.md` 追踪内容质量：`covered`（已覆盖）、`gap`（有缺口）、`stale`
> （已过时）、`unknown`（未知）、`not_applicable`（不适用）、`conflict`（冲突）。
> 总纲中的 `done` 不会自动等于 STATUS 的 `covered`。

## 仓库概况

| 字段 | 值 |
|---|---|
| 规模等级 | `S` / `M` / `L` / `XL` |
| 侦察报告 | [recon.md](./recon.md) |
| 文档语言锁 | `<documentation_language>` |
| 语言证据 | `<documentation_language_evidence>` |
| 累计会话数 | 1 |

## 阶段进度

| 阶段 | 状态 | 所有者或会话 | 闸门或结果 | 下一步或阻塞点 |
|---|---|---|---|---|
| 0 侦察 | pending | | | |
| 1 骨架 | pending | | | |
| 2 填充 | pending | | | |
| 3 收敛 | pending | | | |
| 4 清理 | pending | | | |

> `done` 是停止结论。只有所需评审者返回 `no-more-required-changes`（无需再改）
> 后才能写；否则保持 `active` / `pending` 并写明阻塞点。

## 区域进度

| 区域 | 状态 | 所有者或会话 | 闸门或结果 | 下一步或阻塞点 |
|---|---|---|---|---|
| product | pending | | | |
| architecture | pending | | | |
| process | pending | 流程聚合页综合/评审所有者 | | 子流程完成后收口根路由；这里不复制子项状态。 |
| glossary | pending | | | |
| development | pending | | | |
| testing | pending | | | |
| benchmark | pending | | | |
| operations | pending | | | |
| security and compliance | pending | | | |
| deployment | pending | | | |
| release | pending | | | |
| records | pending | 记录聚合页综合/评审所有者 | | 子记录完成后收口根路由；这里不复制子项状态。 |
| decisions | pending | | | |
| research records | pending | `04-records/research/` | | |
| gotchas | pending | | | |
| bugs | pending | | | |
| tech-debt | pending | | | |

> 第一列保留协议规定的区域 token；例如 `product` 表示产品，`architecture` 表示架构，
> `tech-debt` 表示技术债。

## 产品主干

| 项目 | 状态 | 所有者或会话 | 下一步或阻塞点 |
|---|---|---|---|
| PRD 主干 | pending | | |
| 产品模型 | pending | | |
| 路线图与验收 | pending | | |
| 能力索引 | pending | | |
| 旅程索引 | pending | | |

## 产品表面恢复

<!-- 这里只协调进度。具体清单与稳定 Surface ID 在 `01-product/_manifest.md`；
     不要在此复制。每个适用类别必须列出真实表面；不适用类别必须说明理由。 -->

| 表面类别 | 清单状态 | 所有者或会话 | 清单位置 | 下一步或阻塞点 |
|---|---|---|---|---|
| `page` | pending | | `01-product/_manifest.md` | |
| `navigation` | pending | | `01-product/_manifest.md` | |
| `entry-mode` | pending | | `01-product/_manifest.md` | |
| `control` | pending | | `01-product/_manifest.md` | |
| `settings` | pending | | `01-product/_manifest.md` | |
| `diagnostic` | pending | | `01-product/_manifest.md` | |
| `external-channel` | pending | | `01-product/_manifest.md` | |
| `command` | pending | | `01-product/_manifest.md` | |
| `public-interface` | pending | | `01-product/_manifest.md` | |
| `output-artifact` | pending | | `01-product/_manifest.md` | |
| `notification` | pending | | `01-product/_manifest.md` | |
| `help-onboarding` | pending | | `01-product/_manifest.md` | |

## 质量、风险与治理恢复

<!-- 这里只协调进度。STATUS 拥有精确 Q01-Q21 处置行，不要在这里复制行或
     正文。只有每个适用 Q 项都路由到产品、架构、流程/证据与缺口 owner，且
     每个不适用项都有具体理由，Bootstrap 才算完成。 -->

| 登记表 | 状态 | 所有者或会话 | 剩余决定 |
|---|---|---|---|
| `STATUS.md#质量风险与治理` | pending | | 给 Q01-Q21 分类并完成路由 |

## 架构形状

| 字段 | 值 |
|---|---|
| 选择的拆分轴 | |
| 为什么选择 | |
| 覆盖深度或范围 | `deep`（深入）/ `sampled`（抽样）/ `inferred`（推断）/ `unknown`（未知） |
| 已创建所有者 | |
| 开放缺口 | |
| 停止审查 | 评审者 + 结果 + 范围 |

## 架构所有者与表面恢复

<!-- 每个有充分理由的直接编号架构目录一行。领域 manifest 列出局部技术表面；
     `02-architecture/_manifest.md` 是唯一全局清单，并映射回产品 Surface ID。 -->

所有者类别使用 `runtime`（当前运行时）、`support`（支撑）或 `target`（目标）。

| 所有者 ID | 所有者类别 | 叙事所有者或会话 | 根清单状态 | 关联产品表面 ID | 下一步或阻塞点 |
|---|---|---|---|---|---|
| `owner:<slug>` | runtime / support / target | `02-architecture/NN-<domain>/README.md` | pending | | |

## 收敛

大仓库可按层级、视图、领域或其它明确分段收敛。默认登记表保持简短：

| 分段 | 评审者 | 结果 | 下一步或阻塞点 |
|---|---|---|---|
| | | `pending`（待评审）/ `passed`（通过）/ `needs-fix`（需要修改） | |

## 可选附录

仅在仓库确实需要额外细节时创建：

- `## Appendix: area scope`：记录已覆盖/剩余范围和置信说明。
- `## Appendix: architecture decomposition`：记录完整信号矩阵、被拒绝的误导信号、图清单与评审挑战。
- `## Appendix: source material`：记录详细的源资料吸收行。
- `## Appendix: tier-4 roll-up`：在写入所有者前汇总陷阱、缺陷、决策、研究与债务发现。
