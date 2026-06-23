# <runtime owner> Playbook（维护 / 上手 / 验证）

> Architecture-domain 操作 playbook。仅当本 domain 拥有 ≥3 个机械任务分支（如"接入新 SDK adapter"、"迁移一个 schema 列"）时使用。README 拥有契约真相；本文件拥有*流程*。样例见 `SSOT/02-architecture/sdk-agent-runtime/playbook.md`。

## 0. 启动检查（每次执行）

- `$ssot-preflight`，确认 `documentation_language`。
- `git status -s` — 记录不相关的脏路径，禁止 stage。
- 动手前先读 [`README.md`](./README.md) 的"拥有的状态与资源"与"契约面"；本 playbook 假设你已理解契约。

## 1. 任务分支 A：<列出最常见的机械任务>

前置条件：
- ...

实施顺序（每步必须完成才能进入下一步）：

1. ...
2. ...

## 2. 任务分支 B：<下一个常见任务>

（参照 §1 结构；随着 domain 累积更多机械任务分支再追加 §3、§4。）

## 3. 提交前 gate

按顺序执行；任一失败即阻断 commit：

1. 定向测试选择：...
2. Suite 级 fast suite：...
3. SSOT lint：...

## 4. Debug 阶梯

自顶向下走；每一步证明上一步已干净：

1. ...
2. ...

## 5. 完成定义

- 当前任务分支所有步骤完成。
- §3 gate 全绿；任何 skip 必须显式说明缺失的前置条件。
- 同一个 commit 同步更新 SSOT（README 契约真相、必要的 gotchas / bugs）。
- Commit message 写明：选用的分支、运行的 gate 与结果、更新的 SSOT 文件。

## 6. 禁令

- ❌ ...
- ❌ ...
- ❌ 跳过 §3 gate 后把 skip 当成通过。
