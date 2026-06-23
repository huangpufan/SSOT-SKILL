# 发布流程

> 行文风格：写给任何冷读者。详见 `ssot-bootstrap` §3.7。

> 本区域记录版本、发布和交付一致性。只记录长期不变量、失败模式和证据指针；CI、脚本和 changelog 的完整内容以代码仓库为准。

## 发布一眼看懂 / Reader Map

| 读者问题 | First stop | Authoritative owner | Evidence direction | Stop condition / risk |
|---|---|---|---|---|
| 怎么发布或打版本？ | [发布路径](#发布路径) | this file | CI / release script / version file | |
| 哪些脚本维护发布不变量？ | [发布脚本 / 工具目录](#发布脚本--工具目录) | scripts directory | scripts directory / CI / signing config | |
| 失败时会破坏什么一致性？ | [发布不变量与失败模式](#发布不变量与失败模式) | this file | CI logs / past incidents / detection signals | |

## 发布路径

用短叙述说明 release 的触发方式、版本策略、artifact / package / deployment 的关系，以及谁负责最终确认。

| Release path | Trigger | Artifact / target | Required setup | Evidence | Known risk |
|---|---|---|---|---|---|
| | tag / CI / manual / package publish | | | CI / release script / version file | |

## 发布脚本 / 工具目录

> 若存在 version sync、changelog generation、publish、artifact signing 或 import rewriting 等工具，记录这里。若脚本影响 architecture current/target/gap，链接到对应 architecture domain 或 decision。

| Filename | Purpose | Category | Release invariant | Evidence | Failure mode | Architecture link if any |
|---|---|---|---|---|---|---|
| | | version-sync / changelog / publish / signing / import-rewrite / other | | | | |

## 发布不变量与失败模式

| Invariant | 为什么重要 | Failure mode | 检测方式 | Evidence |
|---|---|---|---|---|
| | | | | |

## Current / Target / Gap

| 区域 | Current | Target | Gap / 下一步验证 | Evidence |
|---|---|---|---|---|
| | | | | |

## 开放缺口

| Gap / unknown | 所需证据 | 阻塞级别 |
|---|---|---|
| | | blocking / non-blocking |
