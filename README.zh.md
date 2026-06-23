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

**有 Agent？把这段贴进你的仓库对话：**

> 把 `https://github.com/huangpufan/SSOT-SKILL` 的 SSOT Skill bundle 装到这个项目，使用 README 里的一行命令，然后读 `AGENTS.md`。

Agent 会跑安装器、读 `AGENTS.md`，并为你 bootstrap `SSOT/`。

**或自己跑交互式安装器：**

```bash
curl -fsSL https://raw.githubusercontent.com/huangpufan/SSOT-SKILL/main/install.sh | bash
```

安装器会用选择器确认 Agent、安装范围和模板语言。重启 Agent 会话后，在你的仓库里跑 `$ssot-bootstrap` 创建 `SSOT/` 并接好 adapter。

## 环境要求

- **Bash 4+**。macOS 默认 bash 3.2，请先 `brew install bash`，然后用 `/opt/homebrew/bin/bash` 跑安装器。
- `git`、`curl`、`python3` 在 `PATH` 中可用。

## 卸载

```bash
bash install.sh --uninstall <target>
```

`<target>` 与安装时使用的 Agent 一致（例如 `claude-code`、`codex`）。安装器同时支持 `--upgrade` 和 `--version`。

## 五个 lifecycle Skill

| Skill | 何时使用 |
|---|---|
| `$ssot-preflight` | 任何实质性代码任务开始前——读取水位、未决裁决，路由到最小必读 SSOT 文件 |
| `$ssot-bootstrap` | 仓库首次没有 `SSOT/`，或 bootstrap 未完成 |
| `$ssot-closeout`  | 最终回复 / `claim_done` / commit 前——判断本批是否产生了需要吸收的持久事实 |
| `$ssot-audit`     | 分段补齐 commit、session 或协议升级 |
| `$ssot-doctor`    | 健康检查、停止审查、lint、CORE-REF / ADAPTER / CONSUMPTION 审计 |

协议版本只在 [`skills/ssot-preflight/SKILL.md`](./skills/ssot-preflight/SKILL.md) 单点维护，并镜像到 [`VERSION`](./VERSION)。

## 三层结构

```
┌─────────────────────────┐    install.sh    ┌──────────────────────────┐
│  SSOT-SKILL（本仓库）   │ ───────────────▶ │  .claude/skills/...      │  ← Agent 启动时
│  installer · 6 skills   │                  │  .codex/skills/...       │     加载这些副本
│  protocol · templates   │                  │  .cursor/skills/...      │
└─────────────────────────┘                  └────────────┬─────────────┘
                                                          │ skills 在你的仓库里
                                                          ▼
                                             ┌──────────────────────────┐
                                             │  your-repo/SSOT/         │  ← 仓库的长期记忆
                                             │  product / architecture  │
                                             │  testing / development   │
                                             └──────────────────────────┘
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
