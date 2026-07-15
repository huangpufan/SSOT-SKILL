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

SSOT Skill 把仓库的长期事实——产品意图、架构边界、决策、陷阱、测试策略——整理成一份可审查的 Markdown `SSOT/` 目录。任何 Agent（Claude Code、Codex、Cursor、Windsurf、Gemini CLI 等）在开始工作前都先读同一份追踪基线，也就是文档追踪到哪个提交、会话和协议版本，而不是每次会话都重新猜测上下文。

> `SSOT/` 是 **Agent 长期记忆**，不是代码的替代品。代码、schema、测试和实际运行行为仍然是当前实现事实的证据来源；SSOT 记录围绕这些事实形成的持久结论。

## 什么是 SSOT？

**SSOT** 是 **Single Source of Truth**（单一事实源）的缩写——一条经典的软件工程原则：每一条重要事实只在**一个**权威位置存在，不允许有第二份散落的副本。任何人（或任何工具）需要这条事实时，都从同一个位置读，而不是猜测、复制或重新推导。

本 Skill 把同样的思路套到 **Agent 对仓库的记忆**上：

- **一条事实一个位置。** 产品意图、架构边界、关键决策、已知陷阱、测试策略，每一项都落在 `SSOT/` 下的一个 Markdown 文件，而不是散落在对话记录、PR 描述和不同 Agent 的私有缓存里。
- **可审查。** 全是纯 Markdown，随仓库一起进版本控制——可 diff、可在 PR 里 review、可回滚。
- **跨工具。** Claude Code、Codex、Cursor、Windsurf、Gemini CLI 等读的是**同一份** `SSOT/`，不会出现某个 Agent 维护一份跑偏的私有记忆。
- **可验证。** 五个生命周期 Skill（`$ssot-preflight` / `$ssot-bootstrap` / `$ssot-closeout` / `$ssot-audit` / `$ssot-doctor`）、一个旧提示兼容入口（`$ssot-skill`）和自带的静态检查，共同防止 `SSOT/` 随仓库演化而失真。

**SSOT 不是代码的替代品。** 代码、schema、测试和运行时行为仍然是 *当前实现* 事实的来源；`SSOT/` 记录的是围绕代码的**持久结论**——那些一旦会话结束或换了 Agent 就会丢失的东西。

## 即使不读代码，也能看懂全部 SSOT

只有新人能读懂，SSOT 才真正有用。因此，所有面向读者的正文都先帮助读者建立
方向，再用一个具体的当前流程解释因果关系、边界、失败与恢复，以及当前状态和
目标状态的区别，最后才给出紧凑的参考表和证据。这里的 KISS 是“抵达理解的
最短可靠路径”，不是“字数越少越好”。“事实权威位置”是唯一解释和维护一条
事实的文件或小节；“运行时责任边界”是实际处理请求或持有状态的系统部分；
“责任人或批准角色”是有权执行、决定或批准的人，不能从前两者自动推断。

默认读者是**实施委托者**：他们可能已经不亲自写或读代码，但仍要能告诉 Agent 应交付什么结果、识别可见结果与合适证据，并知道何时停止或升级处理。因此，SSOT 先用平实语言讲清场景与因果，再引入不可避免的仓库术语、命令和符号。

产品主干覆盖用户、真实可见界面、核心对象生命周期、能力、选择/控制/恢复旅程、
验收以及当前与目标的区别。“产品表面”是人能看到、调用或收到的入口、动作和
结果。架构主干从运行时责任边界出发，回答七类跨边界问题：运行模式、关键旅程、状态与数据、
契约与信任、失败与恢复、部署与可观测性、当前/目标/缺口。供 Agent 恢复和校验
使用的清单（manifest）是机器索引，不是让读者反推答案的正文。

静态检查会拦住只有标题、占位符或链接清单的“看起来完整”。产品和架构各要求
一位没有预备背景的新读者完成 6 个真实任务；同时还要分别逐项处理 53 个产品
完整性问题和 48 个架构完整性问题，避免一段顺畅的故事掩盖缺失边界。流程、记录、
术语表、根导航和 STATUS 使用与自身内容相配的较小评审。批准一项委托工作前，
所有评审都会帮助读者问四个白话问题：

1. 谁可能看不懂、用不了、受到不公平对待或遭受伤害？
2. 压力、并发、失败、断网、升级或恢复时会发生什么？
3. 数据、身份、权限、钱和外部规则由谁负责？
4. 什么证据能证明结果有效、成本可控、可以维护并且能够恢复？

每项适用关注点都要链接事实权威位置、运行时责任边界、流程证据、已知责任角色，
或一个明确缺口；不能靠沉默表示“不适用”，链接能打开也不能单独证明正文符合
仓库事实。精确评审编号、数量和停止规则见
[读者质量协议](./skills/ssot-preflight/references/reader-quality.md)。

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

## 六个 SSOT Skill

其中五个负责生命周期；`$ssot-skill` 只负责把旧提示转到正确 Skill。

| Skill | 何时使用 |
|---|---|
| `$ssot-preflight` | 任何实质性代码任务开始前——读取追踪基线和未决裁决，路由到最小必读 SSOT 文件 |
| `$ssot-bootstrap` | 仓库首次没有 `SSOT/`，或 bootstrap 未完成 |
| `$ssot-closeout`  | 最终回复 / `claim_done` / commit 前——判断本批是否产生了需要吸收的持久事实 |
| `$ssot-audit`     | 分段补齐 commit、session 或协议升级 |
| `$ssot-doctor`    | 健康检查、停止审查、lint、CORE-REF / ADAPTER / CONSUMPTION 审计 |
| `$ssot-skill`     | 兼容 shim；把调用路由到上面五个之一（保留给旧 prompt） |

协议版本只在 [`skills/ssot-preflight/SKILL.md`](./skills/ssot-preflight/SKILL.md) 单点维护，并镜像到 [`VERSION`](./VERSION)。

## 三层结构

```text
SSOT-SKILL --install.sh--> Agent 本地 Skill --在仓库中运行--> SSOT/
```

安装后的 Skill 创建并维护下面这套完整仓库记忆：

```text
your-repo/SSOT/
├── README.md                    从这里开始：仓库做什么，各类问题去哪里找
├── STATUS.md                    哪些事实可信、缺失、过时或仍待决定
├── 01-product/                  用户、当前承诺、可见结果与验收
│   ├── prd.md
│   ├── product-model.md
│   ├── roadmap-and-acceptance.md
│   ├── capabilities/
│   └── journeys/
├── 02-architecture/             系统怎样产出结果，以及怎样处理状态、信任与失败
│   ├── views/                   七类跨系统部分的问题
│   └── NN-domain/               每个领域只有一个清楚的运行时、状态或契约所有者
├── 03-process/                  工作怎样开发、检查、交付和长期运行
│   ├── development/
│   ├── testing/
│   ├── benchmark/
│   ├── deployment/
│   ├── release/
│   ├── operations/              适用于需要长期运行的仓库
│   └── security-and-compliance/ 适用于存在相应生命周期的仓库
├── 04-records/                  为什么这样选择，哪些历史事实仍会影响行动
│   ├── decisions/
│   ├── research/
│   ├── gotchas/
│   ├── bugs/
│   └── tech-debt/
├── glossary/                    仓库专用词、别名和统一含义
└── .bootstrap/                  评审与恢复证据；普通读者可以跳过
```

源包、安装后的 Skill、仓库里的 `SSOT/` 三层只服务一个目标：让 Agent 对仓库的
记忆**可审查**、**可验证**、**跨工具可移植**。

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
