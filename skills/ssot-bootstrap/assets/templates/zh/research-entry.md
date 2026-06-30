---
status: draft
kind: research
created_on: YYYY-MM-DD
owner: <owner-or-role>
promotion_targets:
  - SSOT/02-architecture/domains/<domain>/README.md
recheck_trigger: <dependency-change-or-new-evidence>
do_not_use_for: <current-production-authority-or-broader-claim>
---

# <NNNN> <标题>

> 写作姿态：面向任意陌生读者。见 `ssot-bootstrap` §3.7。

> Research 或 POC 记录。本文件保存问题、方法、证据、可复用 claim、negative finding，以及提升到 durable SSOT owner 的路径。单条 claim 被提升前，本文件不是权威 owner。

## 问题

这次 research 要回答什么问题？用一到两段说明决策压力或不确定性。

## 结论

证据说明了什么？先写当前答案，再写 confidence 和最重要的边界。

## 适用性与边界

这个结论适用于哪里，不适用于哪里？必要时写明 version、environment、workload、feature flag、data shape、provider 或 repository boundary 限制。

`do_not_use_for`：用正文重复最强的不适用边界，避免未来 agent 过度提升本记录。

## Candidates / Options

| Candidate | 为什么考虑 | 结果 | 边界或 trade-off |
|-----------|------------|------|------------------|
| Option A | | chosen / rejected / inconclusive | |
| Option B | | chosen / rejected / inconclusive | |

## 方法 / 环境

- Repository state：`<commit-or-release-or-source-snapshot>`
- Inputs：`<documents-datasets-fixtures-or-user-provided-material>`
- Environment：`<OS-runtime-tool-versions-or-not_applicable>`
- Example paths：`src/myapp/`、`web/src/components/<feature>/`

## 验证步骤

列出支撑结论的可复现步骤。按需要包含 commands、scripts、browser checks、benchmark setup、source comparison 或 manual review procedure。

```bash
<command>
```

## 证据

| Evidence | Pointer | 证明什么 | Limit |
|----------|---------|----------|-------|
| | `path:src/myapp/example.py` | | |

## Negative Findings

记录没有成立的路径、选项或 hypothesis。它们的价值是防止重复探索。

| Finding | Evidence | 为什么重要 |
|---------|----------|------------|
| | | |

## Reusable Claim Rows

每一行都是可提升到 durable SSOT owner 的候选 claim。Claim 要足够窄，未来 agent 才能明确 promote、reject 或 recheck。

| Claim | Evidence | Confidence | Candidate owner | Promotion status |
|-------|----------|------------|-----------------|------------------|
| | | high / medium / low | `SSOT/...` | pending / promoted / rejected |

## Promoted SSOT Owners

Claim 被提升后，准确记录权威表述现在在哪里。不要让被提升 owner 变得含糊。

| Owner | Claim/action promoted | Date | Evidence |
|-------|-----------------------|------|----------|
| `SSOT/...` | | YYYY-MM-DD | |

## Follow-up Actions

列出具体 next action、owner，以及让该 action 变得相关的 trigger。

| Action | Owner | Trigger | Status |
|--------|-------|---------|--------|
| | | | pending / done / obsolete |
