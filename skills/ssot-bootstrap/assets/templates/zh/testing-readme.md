# 测试策略

> 行文风格：写给任何冷读者。详见 `ssot-bootstrap` §3.7。

> 本区域记录稳定的测试策略、选择规则、质量闸门、fixture 约束、当前基线、已知缺口和高风险回归保护。测试运行结果是 evidence，不是 testing fact；不要在这里维护逐批验证历史。

## 测试一眼看懂 / Reader Map

| 读者问题 | First stop | Authoritative owner | Evidence direction | Stop condition / risk |
|---|---|---|---|---|
| 改动后先跑什么测试？ | [测试命令](#测试命令) | this file | package.json / CI / Makefile / test config | |
| 测试层级为什么这样划分？ | [测试策略](#测试策略) | this file | test config / CI / fixture | |
| 哪些检查会阻塞 merge、release 或 claim_done？ | [质量闸门](#质量闸门) | this file | CI / release workflow / startup instructions | |
| 当前预期基线是什么？ | [当前基线](#当前基线) | this file | CI / lint config / benchmark fixture / latest baseline-changing commit | |
| 哪些测试保护历史 bug？ | [防御性测试来源](#防御性测试来源) | this file | linked bug / gotcha / test code | |

## 测试策略

用短叙述说明测试层级、边界和取舍。若无测试，写 `not_applicable`、原因和风险。

| Test level | 覆盖内容 | 为什么这样划分 | Evidence | Known risk |
|---|---|---|---|---|
| unit / integration / e2e / performance / manual | | | test config / CI / fixture | |

## 测试选择矩阵

记录每类长期改动应运行什么测试。不要为一次性任务批次新增行；只有稳定选择规则变化时才更新本矩阵。

| Change family | Required checks | 为什么跑这些检查 | Required setup | Evidence | Escalation trigger |
|---|---|---|---|---|---|
| source / API / schema / UI / docs / release | | | | package manifest / CI / test config | |

## 质量闸门

记录会阻塞 merge、release、claim_done 或其它长期工作流闸门的检查。一次成功运行只是该闸门的 evidence，不是新行。

| Gate | Blocking condition | Required checks | Evidence owner | Known bypass / risk |
|---|---|---|---|---|
| PR / release / claim_done / manual approval | | | CI / release workflow / startup instruction | |

## 当前基线

记录稳定的测试预期状态，例如 lint warning 数、benchmark floor、snapshot baseline 或已知 flaky suite 状态。只有基线本身变化时才更新。

| Baseline | Current value | Evidence | Last baseline-changing change | Risk |
|---|---|---|---|---|
| | | CI / config / benchmark fixture / commit | | |

## 测试命令

> 若命令来自脚本清单、外部资料或自动摘要，仍需回到 package manifest、CI、测试配置或实际运行验证。

| Command | Purpose | Test level | Required setup | Evidence | Known risk |
|---|---|---|---|---|---|
| | | unit / integration / e2e / performance / manual | | package.json / CI / Makefile / test config | |

## Fixtures / 测试数据

| Fixture / 数据源 | 用途 | Owner | 更新风险 | Evidence |
|---|---|---|---|---|
| | | | | |

## 防御性测试来源

> 只记录删除后会让历史 critical / major / recurred bug 复发的关键测试；不要求穷尽。

| 测试 | 防御的 failure mode | 关联 bug / gotcha | Evidence | 删除风险 |
|---|---|---|---|---|
| | | | | |

## 开放缺口

| Gap / unknown | 所需证据 | 阻塞级别 |
|---|---|---|
| | | blocking / non-blocking |

## 不是验证流水账

不要把单次任务的命令转录、pass/fail 日期、耗时或“最近验证”列表写进本文件。必要时把这些事实保存在最终回复、commit/release note、bug 条目或 stop-review evidence；本区域只保存稳定的测试策略、基线、缺口、fixture、闸门和防御性映射事实。
