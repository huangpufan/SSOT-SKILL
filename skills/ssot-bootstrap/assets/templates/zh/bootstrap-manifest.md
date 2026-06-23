# Bootstrap 总纲

> 临时协调者寄存器。Bootstrap 完成且停止审查通过后删除 `.bootstrap/`。
> 仅协调者更新此文件；worker agent 不直接编辑。
>
> Manifest 追踪工作进度（`pending` / `active` / `done` / `blocked`）。
> `STATUS.md` 追踪内容质量（`covered` / `gap` / `stale` / `unknown` /
> `not_applicable` / `conflict`）。Manifest `done` 不会自动等于 STATUS
> `covered`。

## 仓库概况

| 字段 | 值 |
|---|---|
| 规模等级 | `S` / `M` / `L` / `XL` |
| 侦察报告 | [recon.md](./recon.md) |
| 文档语言锁 | `<documentation_language>` |
| 语言证据 | `<documentation_language_evidence>` |
| 累计会话数 | 1 |

## Phase 进度

| Phase | 状态 | Owner/session | Gate/result | Next/blocker |
|---|---|---|---|---|
| 0 侦察 | pending | | | |
| 1 骨架 | pending | | | |
| 2 填充 | pending | | | |
| 3 收敛 | pending | | | |
| 4 清理 | pending | | | |

> `done` 是停止结论。只有所需 reviewer 返回 `no-more-required-changes`
> 后才能写；否则保持 `active` / `pending` 并写明 blocker。

## 区域进度

| 区域 | 状态 | Owner/session | Gate/result | Next/blocker |
|---|---|---|---|---|
| product | pending | | | |
| architecture | pending | | | |
| glossary | pending | | | |
| development | pending | | | |
| testing | pending | | | |
| deployment | pending | | | |
| release | pending | | | |
| decisions | pending | | | |
| gotchas | pending | | | |
| bugs | pending | | | |
| tech-debt | pending | | | |

## Product 主干

| Item | 状态 | Owner/session | Next/blocker |
|---|---|---|---|
| PRD spine | pending | | |
| Product model | pending | | |
| Roadmap and acceptance | pending | | |
| Capability index | pending | | |
| Journey index | pending | | |

## Architecture 形状

| 字段 | 值 |
|---|---|
| Chosen axis | |
| Why this axis | |
| Coverage depth / scope | `deep` / `sampled` / `inferred` / `unknown` |
| Created owners | |
| Open gaps | |
| Stop review | reviewer + result + scope |

## 收敛

大仓库可按 tier、view、domain 或其它明确 segment 收敛。默认寄存器保持简短：

| Segment | Reviewer | Result | Next/blocker |
|---|---|---|---|
| | | pending / passed / needs-fix | |

## 可选附录

仅在仓库确实需要额外细节时创建：

- `## Appendix: area scope`：记录 covered/remaining scope 与 confidence notes。
- `## Appendix: architecture decomposition`：记录完整 signal matrix、rejected false friends、diagram inventory 与 reviewer challenge。
- `## Appendix: source material`：记录详细 absorption rows。
- `## Appendix: tier-4 roll-up`：在写入 owner 前汇总 gotcha/bug/decision/debt findings。
