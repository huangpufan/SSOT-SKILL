<!-- SSOT-generated | generated_at: <date> -->
<!-- SSOT-source: SSOT/README.md@<hash> SSOT/02-architecture/README.md@<hash> -->
<!-- 本文件由 SSOT 生成，请勿在此维护独立长期事实。编辑长期知识请到 SSOT/ 目录。 -->

# <项目名>

<!-- 写作对象：implementation-delegator。路由要平实具体；路径、命令或证据前，
     先用普通话解释不可避免的标签。 -->

<一句话仓库定位>

<!-- SSOT-SKILL:BEGIN -->
## SSOT 工作流程

用户照常描述任务，Agent 在条件满足时自动调用已安装的 SSOT Skill。读取并遵循所选 Skill 的 `SKILL.md`，包括其中的停止条件和审查要求。

- **开工：** 实质性的仓库工作（代码、配置、文档、审查、调试或规划）开始前，使用 `$ssot-preflight`。缺少 `SSOT/` 或初始化未完成时，按其路由使用 `$ssot-bootstrap`；通过相关检查后回到原任务。
- **记录与收尾：** 工作中把长期事实写入对应的 SSOT 维护位置。一批实质性变更的最终回复、`claim_done` 或提交前，使用 `$ssot-closeout`，由它判断所需更新和批次记录；没有长期事实变化时按协议记录 no-op。
- **追补：** 用户要求补齐历史，或其他 SSOT Skill 将提交、会话、协议差异转交处理时，使用 `$ssot-audit`。追踪基线须在所要求的审查通过后推进。
- **检查：** 用户要求 SSOT 健康检查，或其他 SSOT Skill 要求审查时，使用 `$ssot-doctor`。

非仓库闲聊、纯命令执行，以及不改变含义的拼写或格式修正，可以跳过自动生命周期调用；用户明确提出 SSOT 需求时，仍使用对应 Skill。

`SSOT/` 保存仓库的长期记忆；代码、配置、数据结构、测试和实际运行行为是当前实现的证据。既有项目规则与用户决策仍然有效，提交和推送遵循其授权。需要的 Skill 无法加载时，暂停依赖其门禁的工作，报告缺失的前提与恢复方式；这段摘要不能替代实际通过的检查。
<!-- SSOT-SKILL:END -->

## 核心不变量

<!-- 从 SSOT/02-architecture/ 的核心不变量中选取最重要的 3-5 条 -->

- <不变量-1>
- <不变量-2>
- <不变量-3>

<!-- OPTIONAL: keep when the adapter file is read proactively on startup (e.g. CLAUDE.md, GEMINI.md). Drop the whole section for files only read on demand (e.g. AGENTS.md). -->
## 关键提醒

<!-- 可选：最高风险的 1-3 条 active gotcha 一句话摘要，指向 SSOT/04-records/gotchas/ -->
