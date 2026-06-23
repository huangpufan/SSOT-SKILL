<!-- SSOT-generated | generated_at: <date> -->
<!-- SSOT-source: SSOT/README.md@<hash> SSOT/02-architecture/README.md@<hash> -->
<!-- 本文件由 SSOT 生成，请勿在此维护独立长期事实。编辑长期知识请到 SSOT/ 目录。 -->

# <project-name>

<repo-positioning-one-liner>

## SSOT 入口

本项目使用 SSOT Skill bundle，`SSOT/` 是长期记忆的唯一权威位置。

- 实质性任务开始前使用 `$ssot-preflight`。
- 仓库缺少 `SSOT/` 或 bootstrap 未完成时使用 `$ssot-bootstrap`。
- final response、`claim_done` 或 commit 前使用 `$ssot-closeout`。
- 用户要求同步 commit/session/protocol 时使用 `$ssot-audit`。
- 健康检查、停止审查、CORE-REF、ADAPTER 或 CONSUMPTION 时使用 `$ssot-doctor`。

## 核心不变量

<!-- 从 SSOT/02-architecture/ 的核心不变量中选取最重要的 3-5 条 -->

- <invariant-1>
- <invariant-2>
- <invariant-3>

<!-- OPTIONAL: keep when the adapter file is read proactively on startup (e.g. CLAUDE.md, GEMINI.md). Drop the whole section for files only read on demand (e.g. AGENTS.md). -->
## 关键提醒

<!-- 可选：最高风险的 1-3 条 active gotcha 一句话摘要，指向 SSOT/04-records/gotchas/ -->
