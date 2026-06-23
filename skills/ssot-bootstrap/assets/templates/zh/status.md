# SSOT 状态

> KISS register rule：本文件是状态寄存器，不是叙事 owner。
> 单元格只放状态、owner、日期、结论和证据指针。段落级理由、命令输出、
> checklist 和 review transcript 应写入权威 owner 或证据 artifact。

## 事件源覆盖

| 字段 | 值 |
|---|---|
| tracked_commit | `<commit-sha>` |
| tracked_session | `<ISO-timestamp-or-session-id>` |
| tracked_skill_version | `<ssot-preflight-protocol-version>` |
| documentation_language | `<locked-natural-language-or-BCP47-tag>` |
| documentation_language_evidence | `<source-path-or-user-decision>` |
| coverage_result | `bootstrap` / `catching_up` / `in_progress` / `converged` |
| last_stop_review | `<review-pointer>` |

## 区域状态

| 区域 | 状态 | 备注 |
|---|---|---|
| product | | |
| architecture | | |
| glossary | | |
| development | | |
| testing | | |
| deployment | | |
| release | | |
| decisions | | |
| gotchas | | |
| bugs | | |
| tech-debt | | |

> 状态值与 covered 前置条件：见 `$ssot-preflight references/status-protocol.md`。
> 备注只放一条短指针，不维护子项状态流水账。

## 源资料吸收

| 源资料 | 路径/来源 | Lifecycle | Classification | Authority | Owner / absorbed_to | Do not use for | Review |
|---|---|---|---|---|---|---|---|
| | path or `pattern=docs/*` | working/research / working/draft / working/proposal / working/experiment / working/poc / working/prototype / working/execution-log / working/closure / working/report / working/handoff / historical/superseded / historical/deprecated / external/source-material / public/thin-entry | absorb / link-only / stale/conflict / obsolete | current / downgraded / external / historical | owner=SSOT/...; absorbed_to=SSOT/... | do_not_use_for=... | review_on=YYYY-MM-DD; status=pending / absorbed / linked / conflict-recorded / obsolete; conflict=none |

## 源资料 Inventory Exclusions

| pattern | reason | owner | last_checked | review_trigger |
|---|---|---|---|---|
| | | | YYYY-MM-DD | |

## 核心参考文档审查

| 文档 | 角色 | 权威关系 | 状态 | 证据/动作 |
|---|---|---|---|---|
| AGENTS.md / CLAUDE.md / Cursor rules | startup / agent-rules / reference / none | thin-adapter / source-material / mixed | covered / stale / conflict / missing / not_applicable | |

> 只有 startup/reference 文件需要更宽字段时，才新增 appendix 记录检查范围、最后检查、详细动作或冲突链接。

## 停止审查闸门

| scope | stop_claim | reviewer | reviewed_at | result | evidence | remaining_changes |
|---|---|---|---|---|---|---|
| | converged / covered / no-op / tracked_commit / tracked_session / tracked_skill_version / protocol-upgrade / documentation_language | | | no-more-required-changes / needs-fix | | |

## 开放裁决项

| id | status | scope | question | next trigger |
|---|---|---|---|---|
| | pending / deferred / resolved / superseded | | | |

## 待捕获项

| id | captured_at | about | altitude_guess | rule | evidence | signal_source | status |
|---|---|---|---|---|---|---|---|
| CAP-YYYYMMDD-NN | | agent-method / product | apex / authority / inbox | | | user-directive / repo-signal / transcript / tier4-rollup | open / routed / deferred / deferred-export / expired |

## 开放缺口

| 区域 | 状态 | 缺口描述 | 阻塞程度 |
|---|---|---|---|
| | gap / unknown | | |

## 可选附录

仅在需要时创建：

- `## Appendix: core-reference details`：记录更宽的 startup-file 审查字段。
- `## Appendix: adjudication details`：记录 source、needed_by、resolution 与 links。
- `## Appendix: stop-review evidence`：记录详细审查 artifact 指针。
