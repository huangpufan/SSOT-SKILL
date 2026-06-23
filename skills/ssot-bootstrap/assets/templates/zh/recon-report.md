# 侦察报告

> Bootstrap 临时文件。Phase 0 只记录供后续阶段路由使用的观察。Bootstrap
> 完成且停止审查通过后随 `.bootstrap/` 一起清理。

## 文档语言

| 字段 | 值 |
|---|---|
| 探测结果 | `<documentation_language>` / `unknown` / `mixed` |
| 证据 | README / docs / ADR / runbook / 子系统 README / 用户资料 |
| 是否询问用户 | yes / no |
| 写入 STATUS 字段 | `documentation_language`, `documentation_language_evidence` |

> 语言证据混杂、不足或缺失时，先询问用户；不要用当前对话语言兜底。

## 仓库形状

| 字段 | 值 |
|---|---|
| 规模等级 | `S` / `M` / `L` / `XL` |
| 拓扑 | monolith / monorepo-workspaces / monorepo-services / library/tooling / kernel or infrastructure |
| 入口点 | |
| Workspaces/deployable units | |

## 观察

只记录后续阶段需要用来路由工作的内容。每行包含一个观察、证据指针、可能 owner、置信度/gap 和下一步检查。

| Observation | Evidence | Likely route | Confidence/gap | Next check |
|---|---|---|---|---|
| | | product / architecture / development / testing / release / deployment / decisions / gotchas / bugs / tech-debt / link-only | verified / documented / inferred / unknown | |

## Architecture 假设

| 字段 | 值 |
|---|---|
| Likely split axis | |
| Why | |
| Candidate owners | |
| Open risks/gaps | |
| Next architecture check | |

> 这不是正式 `decomposition_basis`。只有确实需要时，才在 appendix 写完整 signal matrix。

## Product 假设

| 字段 | 值 |
|---|---|
| Product posture / PRD spine | |
| Users/operators | |
| Promise / boundary | |
| Capability or journey splits that may be stable | |
| Open product gaps | |

## 推荐策略

- **区域顺序调整**：
- **需要特别关注的 architecture owners**：
- **可快速完成的区域**：
- **预计 sessions**：
- **其它说明**：

## 可选附录

仅在侦察确实需要时创建：

- `## Appendix: architecture candidates`：记录 candidate axes、signal matrix、predicted diagrams、stop/recursion challenge。
- `## Appendix: product candidates`：记录 product-dimension matrix。
- `## Appendix: design-intent candidates`：记录 technical mission、priorities、runtime journeys、migration stance 和 rejected alternatives。
- `## Appendix: source inventory`：记录详细 source-material lifecycle、降权字段、audited exclusions 与 classification。
- `## Appendix: readability/evidence candidates`：记录 Reader Map、script/tool、diagram 或 claim-to-evidence candidates。
