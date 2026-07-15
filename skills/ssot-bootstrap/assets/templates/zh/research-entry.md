---
id: RES-NNNN
record_status: draft
adoption_state: unpromoted
promotion_state: unpromoted
status: draft
kind: research
created_on: YYYY-MM-DD
owner: <owner-or-role>
promotion_targets:
  - SSOT/02-architecture/NN-<domain>/README.md
  - SSOT/03-process/benchmark/README.md
recheck_trigger: <dependency-change-or-new-evidence>
do_not_use_for: <current-production-authority-or-broader-claim>
---

# <NNNN> <标题>

<!-- 写作对象：implementation-delegator。先写决策压力、有界问题和可用结论，
     再写方法标签与证据。 -->

<!-- 完整性权威：reader-quality.md C01-C09、R01-R16 与适用 Q01-Q21。
     covered 记录使用精确的轻量条目/索引契约；明确事实/推测、双状态轴、来源、
     结论采纳与失效。 -->

> 研究、一次性基准研究或 POC（概念验证）记录。本文件保存问题、方法、证据、
> 可复用结论、没有成立的发现，以及提升到长期 SSOT 所有者的路径。单条结论被
> 提升前，本文件不是权威所有者。

## 记录定位

<说明记录类型、用途、范围、触发时间、生命周期、可能影响与所有者。区分观察
事实与推测，并写明限定新鲜度的源资料快照。>

`record_status` 表示证据包是草稿、已验证、已过时还是已被取代；
`adoption_state` 另行表示可复用结论尚未提升、部分提升、已经提升或被长期所有者
拒绝。兼容字段 `status` 只镜像 `record_status`；`promotion_state` 是
`adoption_state` 的兼容别名，保留时必须同值。

## 问题

这次研究要回答什么问题？用一到两段说明决策压力或不确定性。

## 结论

证据说明了什么？先写当前答案，再写置信程度和最重要的边界。

## 适用性与边界

这个结论适用于哪里，不适用于哪里？必要时写明受影响版本、平台、环境、租户或
工作区、数据类别、兼容窗口、工作负载、功能开关、服务提供方或仓库边界。指出安全/隐私/合规/客户暴露或
通知义务；不要在这里保留敏感证据。

`do_not_use_for` 表示“不能用于什么”：用正文重复最强的不适用边界，避免未来代理过度提升本记录。

## 候选方案

| 候选方案 | 为什么考虑 | 结果 | 边界或取舍 |
|-----------|------------|------|------------------|
| 方案 A | | `chosen`（采用）/ `rejected`（拒绝）/ `inconclusive`（无定论） | |
| 方案 B | | `chosen`（采用）/ `rejected`（拒绝）/ `inconclusive`（无定论） | |

## 方法 / 环境

- 仓库状态：`<commit-or-release-or-source-snapshot>`
- 输入：`<documents-datasets-fixtures-or-user-provided-material>`
- 环境：`<OS-runtime-tool-versions-or-not_applicable>`
- 示例路径：`src/myapp/`、`web/src/components/<feature>/`

## 验证步骤

列出支撑结论的可复现步骤。按需要包含命令、脚本、浏览器检查、一次性基准测试
准备、源码对比或人工评审流程。稳定的基准测试套件、工作负载、门槛和比较规则
被提升后写入 `SSOT/03-process/benchmark/README.md`。

```bash
<command>
```

## 证据

| 证据 | 指针 | 证明什么 | 限制 |
|----------|---------|----------|-------|
| | `path:src/myapp/example.py` | | |

## 没有成立的发现

记录没有成立的路径、选项或假设。它们的价值是防止重复探索。

| 发现 | 证据 | 为什么重要 |
|---------|----------|------------|
| | | |

## 可复用结论

每一行都是可提升到长期 SSOT 所有者的候选结论。结论要足够窄，未来代理才能
明确选择提升、拒绝或重新检查。

| 结论 | 证据 | 置信程度 | 候选所有者 | 提升状态 |
|-------|----------|------------|-----------------|------------------|
| | | `high`（高）/ `medium`（中）/ `low`（低） | `SSOT/...` | `pending`（待处理）/ `promoted`（已提升）/ `rejected`（已拒绝） |

## 已提升到的 SSOT 所有者

结论被提升后，准确记录权威表述现在在哪里。不要让被提升所有者变得含糊。

| 所有者 | 已提升的结论或动作 | 日期 | 证据 |
|-------|-----------------------|------|----------|
| `SSOT/...` | | YYYY-MM-DD | |

## 后续行动

列出具体下一项行动、所有者，以及让该行动再次相关的触发条件。
状态使用 `pending`（待处理）、`done`（已完成）或 `obsolete`（已失效）。

| 行动 | 所有者 | 触发条件 | 状态 |
|--------|-------|---------|--------|
| | | | pending / done / obsolete |

## 完成条件、取代与失效

<说明什么验证能关闭本记录、哪个已提升所有者会取代其当前用途、什么证据会使
它失效，以及适用时如何复现调查或防止重复探索。>
