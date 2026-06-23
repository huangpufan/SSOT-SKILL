<div align="center">

# SSOT Skill

**让代码仓库拥有可维护、可验证、跨会话延续的 Agent 长期记忆。**

[![Version](https://img.shields.io/github/v/tag/huangpufan/SSOT-SKILL?label=protocol&color=2ea44f)](./VERSION)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](./LICENSE)
[![CI](https://github.com/huangpufan/SSOT-SKILL/actions/workflows/ci.yml/badge.svg)](https://github.com/huangpufan/SSOT-SKILL/actions/workflows/ci.yml)
[![Agents](https://img.shields.io/badge/agents-70%2B-purple)](#支持的-agent)
[![Stars](https://img.shields.io/github/stars/huangpufan/SSOT-SKILL?style=social)](https://github.com/huangpufan/SSOT-SKILL/stargazers)

[English](./README.md) · [中文](./README.zh.md) · [Skill 参考](./AGENTS.md) · [更新日志](./CHANGELOG.md)

</div>

---

SSOT Skill 把仓库的长期事实——产品意图、架构边界、决策、陷阱、测试策略——整理成一份可审查的 Markdown `SSOT/` 目录。任何 Agent（Claude Code、Codex、Cursor、Windsurf、Gemini CLI 等）在开始工作前都先读同一份事实水位，而不是每次会话都重新猜测上下文。

> `SSOT/` 是 **Agent 长期记忆**，不是代码的替代品。代码、schema、测试和实际运行行为仍然是当前实现事实的证据来源；SSOT 记录围绕这些事实形成的持久结论。

## 快速开始

把这一行粘进你的 Agent 对话（Claude Code、Codex、Cursor、Gemini CLI 等均可）：

```
Read https://raw.githubusercontent.com/huangpufan/SSOT-SKILL/main/INSTALL.md and follow it.
```

Agent 会 fetch [`INSTALL.md`](./INSTALL.md)，跑安装器（默认装到项目本地），问你是否再装一份全局，然后读 `AGENTS.md`。

**没 Agent？自己跑：**

```bash
curl -fsSL https://raw.githubusercontent.com/huangpufan/SSOT-SKILL/main/install.sh | bash
```

交互式安装器用方向键选 Agent、范围、模板语言。装完后重启 Agent 会话，在仓库里跑 `$ssot-bootstrap` 创建 `SSOT/`。

## 把指令写进 agent-instructions 文件

安装 bundle 让 skill 可被**发现**，但大多数 Agent 在没有显式触发指令时**不会可靠地调用** `$ssot-preflight`。你需要在仓库的 agent-instructions 文件（`CLAUDE.md` / `AGENTS.md` / `.cursorrules` / `GEMINI.md` 等）里加一段触发块。

Agent 驱动的安装路径（[`INSTALL.md`](./INSTALL.md) 第 4 步）会自动做这件事。如果你是手动跑 `install.sh`，请把下面的块复制到你仓库的 agent-instructions 文件里。措辞按上下文调整；如果已有相同块，**不要重复粘贴**。

**中文**

```markdown
本仓库已安装 SSOT Skill。`SSOT/` 是 Agent 长期记忆；代码 / schema / 测试仍是事实证据源。

- `$ssot-preflight` — 实质性仓库任务开始前。
- `$ssot-bootstrap` — `SSOT/` 缺失或 bootstrap 未完成时。
- `$ssot-closeout` — 实质性变更批次的 final response / `claim_done` / commit 前。
- `$ssot-audit` — 同步 `tracked_commit` / `tracked_session` / `tracked_skill_version`。
- `$ssot-doctor` — 健康检查 / 停止审查 / CORE-REF / ADAPTER / CONSUMPTION。
```

**English**

```markdown
SSOT Skill is installed here. `SSOT/` is agent long-term memory; code, schema, and tests remain the source of truth.

- `$ssot-preflight` — before any substantive repository task.
- `$ssot-bootstrap` — when `SSOT/` is missing or bootstrap is incomplete.
- `$ssot-closeout` — before final response / `claim_done` / commit on a substantive change batch.
- `$ssot-audit` — to catch up `tracked_commit` / `tracked_session` / `tracked_skill_version`.
- `$ssot-doctor` — for health check, stop review, CORE-REF / ADAPTER / CONSUMPTION.
```

点代码块右上角的复制按钮，把内容粘到 agent-instructions 文件的 "Skills" / "Conventions" / "约定" 段落（若无则贴到文件末尾）。

## 环境要求

- **Bash 4+**。macOS 默认 bash 3.2，请先 `brew install bash`，然后用 `/opt/homebrew/bin/bash` 跑安装器。
- `git`、`curl`、`python3` 在 `PATH` 中可用。

## 卸载

```bash
bash install.sh --uninstall --agent <key> --scope <global|project> --yes
```

`<key>` 与安装时使用的 canonical Agent key 一致（例如 `claude-code`、`codex`、`cursor`）。安装器同时支持 `--upgrade`（扫描全部已安装位置并重装）和 `--version`。

## 六个 lifecycle Skill

| Skill | 何时使用 |
|---|---|
| `$ssot-preflight` | 任何实质性代码任务开始前——读取水位、未决裁决，路由到最小必读 SSOT 文件 |
| `$ssot-bootstrap` | 仓库首次没有 `SSOT/`，或 bootstrap 未完成 |
| `$ssot-closeout`  | 最终回复 / `claim_done` / commit 前——判断本批是否产生了需要吸收的持久事实 |
| `$ssot-audit`     | 分段补齐 commit、session 或协议升级 |
| `$ssot-doctor`    | 健康检查、停止审查、lint、CORE-REF / ADAPTER / CONSUMPTION 审计 |
| `$ssot-skill`     | 兼容 shim；把调用路由到上面五个之一（保留给旧 prompt） |

协议版本只在 [`skills/ssot-preflight/SKILL.md`](./skills/ssot-preflight/SKILL.md) 单点维护，并镜像到 [`VERSION`](./VERSION)。

## 三层结构

```
┌─────────────────────────┐    install.sh    ┌────────────────────────────────┐
│  SSOT-SKILL（本仓库）   │ ───────────────▶ │  PROJECT 范围（默认）：        │  ← Agent 启动时
│  installer · 6 skills   │                  │    .claude/skills/...          │     加载这些副本
│  protocol · templates   │                  │    .agents/skills/...（Codex、 │
│                         │                  │      Cursor、Gemini CLI、…）   │
│                         │                  │  GLOBAL 范围（可选）：         │
│                         │                  │    ~/.claude/skills/...        │
│                         │                  │    ~/.codex/skills/...         │
└─────────────────────────┘                  └──────────────┬─────────────────┘
                                                            │ skills 在你的仓库里
                                                            ▼
                                              ┌────────────────────────────────┐
                                              │  your-repo/SSOT/               │  ← 仓库的长期记忆
                                              │  product / architecture        │
                                              │  testing / development         │
                                              └────────────────────────────────┘
```

三层，一个目标：让 Agent 对仓库的记忆**可审查**、**可验证**、**跨工具可移植**。

## 常用流程

```text
# 开始一个代码任务
开始这个仓库任务前先用 $ssot-preflight。

# 收尾
最终回复前先用 $ssot-closeout。

# 全新仓库
用 $ssot-bootstrap 创建仓库 SSOT。

# 历史补齐
用 $ssot-audit 补齐 tracked_commit 和 tracked_session。

# 体检
用 $ssot-doctor 跑一次 SSOT 健康检查。
```

## 支持的 Agent

与 [vercel-labs/skills](https://github.com/vercel-labs/skills) 注册表对齐。主流 Agent 包括：**Claude Code · Cursor · Codex · Windsurf · Gemini CLI · GitHub Copilot · OpenCode · Cline · Roo Code · Continue · Augment · Zed · Goose · Aider · Junie · Trae · Crush · Warp · OpenHands · Replit · Devin · Droid · Qwen Code · Lingma · Kilo · ForgeCode · Tabnine**，外加 40+ 其他。交互式安装器会展示本机检测到的 Agent。

## 文档

- [`AGENTS.md`](./AGENTS.md) — 完整 skill 参考和路由规则
- [`CONTRIBUTING.md`](./CONTRIBUTING.md) — 贡献指南
- [`CHANGELOG.md`](./CHANGELOG.md) — 协议历史（Keep a Changelog）
- [`skills/ssot-audit/references/protocol-upgrades.md`](./skills/ssot-audit/references/protocol-upgrades.md) — 升级路由

## Star 趋势

<a href="https://www.star-history.com/#huangpufan/SSOT-SKILL&Date">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=huangpufan/SSOT-SKILL&type=Date&theme=dark" />
    <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=huangpufan/SSOT-SKILL&type=Date" />
    <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=huangpufan/SSOT-SKILL&type=Date" />
  </picture>
</a>

## 协议

[MIT](./LICENSE) © [huangpufan](https://github.com/huangpufan)
