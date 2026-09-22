<div align="center">

# SSOT Skill

**用 Markdown 维护仓库记忆，让不同会话、不同 Agent 共享项目上下文。**

[![CI](https://github.com/huangpufan/SSOT-SKILL/actions/workflows/ci.yml/badge.svg)](https://github.com/huangpufan/SSOT-SKILL/actions/workflows/ci.yml) [![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](./LICENSE) [![Agents](https://img.shields.io/badge/agents-70%2B-purple)](#支持的-agent) [![Stars](https://img.shields.io/github/stars/huangpufan/SSOT-SKILL?style=social)](https://github.com/huangpufan/SSOT-SKILL/stargazers)

[English](./README.md) · [中文](./README.zh.md) · [安装指南](./INSTALL.md) · [协议版本](./VERSION) · [更新日志](./CHANGELOG.md)

</div>

新开一个编程会话，常常又要解释同一批问题：项目要实现什么、为什么这样设计、哪些修过的问题不能再犯。SSOT Skill 帮助 Agent 把这些答案保存在随代码一起版本管理的 `SSOT/` 目录里，让下一次会话有据可循。

**SSOT** 是 **Single Source of Truth（单一事实源）**：每条长期事实只在一个位置维护，其他文档通过链接引用。本项目提供六个 Skill、Markdown 模板和本地检查脚本，在你已有的编程 Agent 中使用。

- **跨会话延续上下文。** 把产品意图、架构边界、决策和已知陷阱留在代码旁边。
- **跨工具共享上下文。** 在同一仓库工作的 Agent 可以读取和更新同一组文件。
- **看清哪些内容经过检查。** 记录已审查的提交、尚存的缺口，以及仍需人来决定的事项。

它尤其适合持续维护的仓库，以及需要在人与 Agent、不同 Agent 之间交接工作的项目。

## 快速开始

### 1. 安装到你想整理的项目中

用编程 Agent 打开那个项目，把下面这句话发给它：

```text
请阅读 https://raw.githubusercontent.com/huangpufan/SSOT-SKILL/main/INSTALL.md 并按照指南安装。
```

Agent 会按[安装指南](./INSTALL.md)识别安装位置，安装并验证全部六个 Skill，再把日常触发指令合并到项目的 `AGENTS.md`、`CLAUDE.md` 等文件中。默认**只安装到当前项目**，沿用已有模板语言；首次安装时根据对话语言选择 `en` 或 `zh`。你也可以在同一句话里指定其他语言，或明确要求全局安装。

<details>
<summary>希望在终端里手动安装？</summary>

环境需要 **Bash 4+**、`git`、`curl` 和 `python3`。macOS 用户先运行 `brew install bash`，再把下面命令里的 `bash` 换成 `"$(brew --prefix)/bin/bash"`；系统自带的 Bash 版本过旧。

在你想整理的项目根目录执行：

```bash
set -o pipefail
curl -fsSL https://raw.githubusercontent.com/huangpufan/SSOT-SKILL/main/install.sh | bash -s -- --quickstart --scope project --lang zh
```

需要英文模板时改用 `--lang en`。`--quickstart` 会识别 Agent 并跳过交互选择。如果识别结果不唯一，或你希望明确指定安装对象，可以追加 `--agent codex`、`--agent claude-code` 或其他[支持的标识](#支持的-agent)。

脚本会安装 Skill 并输出建议的指令块，**不会修改项目的 Agent 指令文件，也不会创建 `SSOT/`**。请按[安装指南第 4 步](./INSTALL.md#4-wire-the-skills-into-the-repos-agent-instructions-file)合并指令块；已有 SSOT 指令时原地更新，避免重复。随后继续下一步。

</details>

### 2. 重启 Agent，再创建仓库记忆

重启 Agent 会话，让新安装的 Skill 被发现。如果项目还没有 `SSOT/`，发送：

```text
用 $ssot-bootstrap 根据这个仓库现有的代码和文档创建 SSOT。
```

初始化会探索仓库、整理长期事实、记录缺口，并审查结果。生成后从 `SSOT/README.md` 开始阅读，在 `SSOT/STATUS.md` 查看哪些内容已审查、哪些仍未解决。大型仓库可能需要多个会话，可以继续尚未完成的初始化工作。

如果项目已经有 `SSOT/`，先用 `$ssot-preflight`；遇到初始化未完成或项目追踪的协议版本落后，它会转到对应 Skill。

### 3. 在日常工作中使用

```text
开始这个仓库任务前先用 $ssot-preflight：[描述你的任务]。
最终回复或提交前用 $ssot-closeout 收尾。
```

开始前，preflight 检查文档状态并定位与任务相关的文件；收尾时，closeout 检查本次工作是否改变了长期事实，并按需更新其维护位置。安装时写入的指令会为后续会话建立这些触发约定，你也可以显式调用 Skill。

上面的 `$ssot-…` 示例是**发给 Agent 的提示词**，不是终端命令。不同 Agent 的 Skill 调用语法可能不同。

## 该用哪个 Skill？

五个 Skill 负责生命周期，第六个兼容旧提示词。点击名称可以查看对应协议及详细参考文档。

| 场景 | Skill | 作用 |
|---|---|---|
| 开始实质性的仓库任务 | [`$ssot-preflight`](./skills/ssot-preflight/SKILL.md) | 检查已审查状态、未决事项、语言和版本，定位必读文档 |
| 创建 `SSOT/` 或继续初始化 | [`$ssot-bootstrap`](./skills/ssot-bootstrap/SKILL.md) | 根据证据建立仓库记忆，并审查覆盖情况 |
| 结束一批实质性变更 | [`$ssot-closeout`](./skills/ssot-closeout/SKILL.md) | 在最终回复或提交前，让长期事实与本次变更对齐 |
| 补齐提交、会话或协议变更 | [`$ssot-audit`](./skills/ssot-audit/SKILL.md) | 分段审查历史，更新追踪基线 |
| 检查文档健康度或审查完成声明 | [`$ssot-doctor`](./skills/ssot-doctor/SKILL.md) | 运行结构检查，审查证据、一致性与可读性 |
| 使用旧的 `$ssot-skill` 提示词 | [`$ssot-skill`](./skills/ssot-skill/SKILL.md) | 转到上面五个 Skill 之一 |

**追踪基线**记录文档审查到了哪个提交、会话和协议版本。它不代表每条事实都是最新的，也不代表所有领域已经完整覆盖。

## 项目里会生成什么？

安装后的 Skill 提供工作指令和工具；项目里的 `SSOT/` 保存它们帮助维护的记忆：

```text
SSOT-SKILL → 安装到 Agent 的 Skill 目录 → 在你的项目中使用 Skill → SSOT/
```

主要阅读入口如下：

```text
 your-repo/SSOT/
 ├── README.md           项目做什么，各类问题去哪里找答案
 ├── STATUS.md           已审查状态、未决事项、缺口与追踪基线
 ├── HISTORY.md          SSOT 更新批次及所涉及文件的简要记录
 ├── 01-product/         用户、能力、使用流程与验收标准
 ├── 02-architecture/    系统怎样运行、管理状态和处理失败
 │   ├── views/          跨系统边界的整体解释
 │   └── NN-domain/      按仓库实际职责划分的领域细节
 ├── 03-process/         怎样开发、测试、做基准评估、部署和发布
 ├── 04-records/         决策、研究、陷阱、缺陷与技术债
 ├── glossary/           项目专用术语及其含义
 └── .bootstrap/         初始化期间的进度与审查证据
```

架构领域按仓库的实际职责划分；运维、安全与合规流程在适用时纳入。完整结构见[模板索引](./skills/ssot-bootstrap/references/templates-index.md)。

现有 README、设计文档和决策记录是整理过程的输入。长期事实会归入各自的维护位置，导航通过链接指向它们；具体处理方式见[已有资料处理规则](./skills/ssot-preflight/references/source-material.md)。

## 怎样让这份记忆持续有用？

**让委托实施的人也能读懂。** 写作规则要求文档讲清用户场景、当前行为、边界、失败与恢复，以及验收结果所需的证据。读者应该能据此决定让 Agent 做什么，而不必先通读代码。详细验收要求见[读者质量协议](./skills/ssot-preflight/references/reader-quality.md)。

**让结论有证据可查。** 代码、数据结构、测试和实际运行行为仍是当前实现的证据来源。SSOT 保存围绕它们形成的解释与决策，并区分现状、目标和未知事项。

**明确检查能证明什么。** [本地检查脚本](./skills/ssot-doctor/assets/scripts/ssot-lint.sh)检查结构、链接、追踪一致性等可机械判断的属性，Doctor 再进行 Agent 审查。仅通过脚本检查，不能证明文档真实、易懂或完整；初始化完成还需要独立审查。

**通过工作流程维护。** 安装只让 Skill 可用，需要在工作中调用它们，文档才能随仓库变化更新。安装本身不会提供自动同步，也不能保证 Agent 每次都遵守全部规则。

## 支持的 Agent

安装器登记了 **70 多种 Agent** 的安装路径，包括 Claude Code、Codex、Cursor、Windsurf、Gemini CLI、GitHub Copilot、OpenCode 和 Cline。常用的项目级安装位置如下：

| Agent | 安装器标识 | 项目 Skill 目录 |
|---|---|---|
| Claude Code | `claude-code` | `.claude/skills/` |
| Codex | `codex` | `.agents/skills/` |
| Cursor | `cursor` | `.agents/skills/` |
| Windsurf | `windsurf` | `.windsurf/skills/` |
| Gemini CLI | `gemini-cli` | `.agents/skills/` |

查看全部标识与安装路径，不执行安装：

```bash
set -o pipefail
curl -fsSL https://raw.githubusercontent.com/huangpufan/SSOT-SKILL/main/install.sh | bash -s -- --list-agents
```

登记了安装路径，不等于已经证明各 Agent 版本的 Skill 发现机制和执行行为完全一致。安装后请重启 Agent，并确认它能发现这些 Skill。

## 更新与卸载

更新时，也让 Agent 按同一份指南处理：

```text
请阅读 https://raw.githubusercontent.com/huangpufan/SSOT-SKILL/main/INSTALL.md，为当前 Agent 更新本项目的 SSOT Skill，保留原模板语言。
```

更新后重启 Agent。如果项目追踪的协议版本较旧，用 `$ssot-audit` 审查升级；替换安装后的 Skill 不会自行迁移 `SSOT/`。卸载时，让 Agent 按指南移除指定范围的安装，并检查是否还有过时的触发指令。

<details>
<summary>手动更新与卸载命令</summary>

例如，在使用 SSOT Skill 的项目根目录更新项目级 Codex 安装：

```bash
set -o pipefail
curl -fsSL https://raw.githubusercontent.com/huangpufan/SSOT-SKILL/main/install.sh | bash -s -- --upgrade --agent codex --scope project
```

移除这份安装：

```bash
set -o pipefail
curl -fsSL https://raw.githubusercontent.com/huangpufan/SSOT-SKILL/main/install.sh | bash -s -- --uninstall --agent codex --scope project --yes
```

请使用安装时对应的 Agent 标识和范围。共享同一 Skill 目录的 Agent 也共享这份安装，卸载会影响该共享位置。命令会保留 `SSOT/` 文档和 Agent 指令文件；停止使用本 Skill 包时，请自行移除不再适用的 SSOT 触发指令。

不带范围的 `--upgrade` 会更新当前项目和全局检测到的所有安装；只想更新一处时，请使用上面限定 Agent 和范围的写法。

</details>

## 文档与贡献

- [安装指南](./INSTALL.md)：由 Agent 完成安装、写入触发指令，以及网络异常时的备用方式。
- [更新日志](./CHANGELOG.md)与[当前协议版本](./VERSION)：Skill 包的变更记录。
- [协议升级指南](./skills/ssot-audit/references/protocol-upgrades.md)：已有项目的文档怎样跟进升级。
- [贡献指南](./CONTRIBUTING.md)：怎样提交改进，以及运行本地检查。
- [AGENTS.md](./AGENTS.md)：Agent 维护**本 Skill 包源仓库**时应遵循的指令。
- [安全政策](./SECURITY.md)：怎样报告安全漏洞。

## 许可证

[MIT](./LICENSE) © [huangpufan](https://github.com/huangpufan)
