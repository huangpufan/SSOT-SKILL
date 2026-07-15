# SSOT 状态

<!-- 写作对象：implementation-delegator。本登记表保持简短；每个标签都路由到
     平实语言 owner 正文与具体下一项检查。 -->

> 保持简单清晰（KISS）的登记表规则：本文件只登记状态，不拥有解释正文。
> 单元格只放状态、所有者、日期、结论和证据指针。成段理由、命令输出、
> 检查清单和评审记录应写入权威所有者或证据产物。

<!-- 完整性权威：reader-quality.md 的 STATUS S01-S11。v2.60 普通数据单元格
     最多 180 字符，源资料吸收单元格可用 320；生命周期/权威/owner/review 应拆列。 -->

## 事件源覆盖

字段名是协议固定 token：依次记录已追踪提交、会话、技能版本、文档语言、语言
证据、总体覆盖结果和最近一次停止审查。

| 字段 | 值 |
|---|---|
| tracked_commit | `<commit-sha>` |
| tracked_session | `<ISO-timestamp-or-session-id>` |
| tracked_skill_version | `<ssot-preflight-protocol-version>` |
| documentation_language | `<locked-natural-language-or-BCP47-tag>` |
| documentation_language_evidence | `<source-path-or-user-decision>` |
| coverage_result | `bootstrap` / `catching_up` / `in_progress` / `converged` |
| last_stop_review | `<review-pointer>` |

## 区域状态

| 区域 | 状态 | 备注 |
|---|---|---|
| product | | |
| architecture | | |
| process | | 聚合路由；只有所有适用子流程均为 `covered` 或 `not_applicable` 时才能标为 `covered`。 |
| development | | |
| testing | | |
| benchmark | | |
| deployment | | |
| release | | |
| operations | | 条件所有者；只有服务生命周期确实没有运维问题时才用 `not_applicable`。缺少所有者目录属于 `gap`，不能证明不适用。 |
| security-and-compliance | | 条件所有者；只有仓库生命周期确实没有安全或合规问题时才用 `not_applicable`。缺少所有者目录属于 `gap`，不能证明不适用。 |
| records | | 聚合路由；只有所有适用记录子域均为 `covered` 或 `not_applicable` 时才能标为 `covered`。 |
| decisions | | |
| research records | | `04-records/research/` |
| gotchas | | |
| bugs | | |
| tech-debt | | |
| glossary | | |

> 第一列保留协议规定的区域 token，例如 `product` 表示产品、`architecture`
> 表示架构、`process` 表示流程聚合页、`records` 表示记录聚合页。基线行必须完整；
> 状态值与 `covered`（已覆盖）的前置条件：见
> `$ssot-preflight references/status-protocol.md`。
> 备注只放一条短指针，不维护子项状态流水账。

## 质量、风险与治理

<!-- 这是 Q01-Q21 的处置登记表，不是二十一篇叙事。每个单元格保持指针大小。
     适用性只写 `applicable` 或
     `not_applicable: <具体理由>; [证据](<owner-path>)`。适用行的三个
     事实/证据所有者单元格分别放可解析 Markdown 链接，或写
     `not_applicable: <该层不适用的理由>; [证据](<owner-path>)`；缺口所有者
     放可闭合缺口的链接，或 `none: <没有缺口的理由>; [证据](<owner-path>)`。
     未实现属于 gap，不能写 not_applicable。全局不适用行的其余格可写 `—`。
     解释正文写入链接指向的 owner。 -->

<!-- Q01-Q21 的精确含义由
     `$ssot-preflight references/reader-quality.md` 唯一维护；填写本登记表时读取
     那份完整画像，不在本模板另建摘要。 -->

| Q ID | 适用性 | 产品事实所有者 | 架构事实所有者 | 流程/证据所有者 | 缺口所有者 |
|---|---|---|---|---|---|
| Q01 | applicable / not_applicable: `<具体理由>; [证据](<owner-path>)` | | | | |
| Q02 | applicable / not_applicable: `<具体理由>; [证据](<owner-path>)` | | | | |
| Q03 | applicable / not_applicable: `<具体理由>; [证据](<owner-path>)` | | | | |
| Q04 | applicable / not_applicable: `<具体理由>; [证据](<owner-path>)` | | | | |
| Q05 | applicable / not_applicable: `<具体理由>; [证据](<owner-path>)` | | | | |
| Q06 | applicable / not_applicable: `<具体理由>; [证据](<owner-path>)` | | | | |
| Q07 | applicable / not_applicable: `<具体理由>; [证据](<owner-path>)` | | | | |
| Q08 | applicable / not_applicable: `<具体理由>; [证据](<owner-path>)` | | | | |
| Q09 | applicable / not_applicable: `<具体理由>; [证据](<owner-path>)` | | | | |
| Q10 | applicable / not_applicable: `<具体理由>; [证据](<owner-path>)` | | | | |
| Q11 | applicable / not_applicable: `<具体理由>; [证据](<owner-path>)` | | | | |
| Q12 | applicable / not_applicable: `<具体理由>; [证据](<owner-path>)` | | | | |
| Q13 | applicable / not_applicable: `<具体理由>; [证据](<owner-path>)` | | | | |
| Q14 | applicable / not_applicable: `<具体理由>; [证据](<owner-path>)` | | | | |
| Q15 | applicable / not_applicable: `<具体理由>; [证据](<owner-path>)` | | | | |
| Q16 | applicable / not_applicable: `<具体理由>; [证据](<owner-path>)` | | | | |
| Q17 | applicable / not_applicable: `<具体理由>; [证据](<owner-path>)` | | | | |
| Q18 | applicable / not_applicable: `<具体理由>; [证据](<owner-path>)` | | | | |
| Q19 | applicable / not_applicable: `<具体理由>; [证据](<owner-path>)` | | | | |
| Q20 | applicable / not_applicable: `<具体理由>; [证据](<owner-path>)` | | | | |
| Q21 | applicable / not_applicable: `<具体理由>; [证据](<owner-path>)` | | | | |

## 源资料吸收

下表登记外部或仓库内材料如何被 SSOT 使用。生命周期、分类和权威性栏保留协议
固定值；填写时必须同时给出所有者、不能用于什么，以及何时复核。
`working/*` 表示工作材料，`historical/*` 表示历史材料；`absorb` 表示吸收，
`link-only` 表示只链接，`stale/conflict` 表示过时或冲突，`obsolete` 表示失效。

<!-- 真实 ID 使用 SRC-YYYYMMDD-NN。生命周期、分类、权威性和复核状态使用
     status-protocol.md 的固定值；持久所有者只放一条可解析 Markdown 链接。
     完全空白的起始行可以保留。 -->

| 源资料 ID | 源资料 | 路径/来源 | 生命周期 | 分类 | 权威性 | 持久所有者或吸收位置 | 不能用于 | 复核 |
|---|---|---|---|---|---|---|---|---|
| | | | | | | | | |

## 不纳入源资料清单的范围

| 路径模式 | 原因 | 决策所有者 | 最近检查日期 | 复核触发条件 |
|---|---|---|---|---|
| | | | | |

## 核心参考文档审查

<!-- 角色：startup / agent-rules / reference / none。权威关系：thin-adapter /
     source-material / mixed。状态：covered / stale / conflict / missing /
     not_applicable。审查基线写 commit=<sha>; session=<id-or-none>；持久所有者/
     范围与缺口/冲突格都放可解析路由。 -->

| 文档 | 角色 | 权威关系 | 状态 | 审查基线 | 持久所有者或范围 | 缺口或冲突路由 |
|---|---|---|---|---|---|---|
| | | | | | | |

## 停止审查闸门

结果使用 `no-more-required-changes`（无需再改）或 `needs-fix`（需要修改）。

<!-- 停止结论：converged / covered / no-op / tracked_commit / tracked_session /
     tracked_skill_version / protocol-upgrade / documentation_language。评审者
     角色：scoped-self-review / independent-reviewer /
     independent-cold-reader。产品或架构的高影响采用使用
     independent-cold-reader；其他独立评审例外使用 independent-reviewer。结果：
     no-more-required-changes / needs-fix。证据只放一条 Markdown 产物链接；
     授权对象写本次评审真正授权的区域或追踪基线。 -->

| 范围 | 停止结论 | 评审者 | 评审者角色 | 评审时间 | 结果 | 证据 | 剩余改动 | 授权对象 |
|---|---|---|---|---|---|---|---|---|
| | | | | | | | | |

## 开放裁决项

状态使用 `pending`（待处理）、`deferred`（延期）、`resolved`（已解决）或
`superseded`（已取代）。

<!-- 真实 ID 使用 ADJ-YYYYMMDD-NN。状态：pending / deferred / resolved /
     superseded；未闭合行的闭合证据写 `none: open`。 -->

| ID | 状态 | 受影响范围或任务 | 问题或缺失证据 | 责任所有者 | 阻断或复核触发条件 | 解决路由 | 闭合或取代证据 |
|---|---|---|---|---|---|---|---|
| | | | | | | | |

## 待捕获项

<!-- 真实 ID 使用 CAP-YYYYMMDD-NN。状态：pending / routed / absorbed / deferred /
     expired；未闭合行的闭合证据写 `none: open`。 -->

| ID | 来源 | 建议所有者 | 原因 | 优先级或触发条件 | 责任所有者 | 状态 | 闭合证据 |
|---|---|---|---|---|---|---|---|
| | | | | | | | |

## 开放缺口

<!-- 真实 ID 使用 GAP-YYYYMMDD-NN。状态：gap / unknown / resolved /
     superseded；未闭合行的闭合证据写 `none: open`。 -->

| ID | 状态 | 受影响范围或任务 | 问题或缺失证据 | 责任所有者 | 阻断或复核触发条件 | 解决路由 | 闭合或取代证据 |
|---|---|---|---|---|---|---|---|
| | | | | | | | |

## 可选附录

仅在需要时创建：

- `## Appendix: core-reference details`：记录更宽的启动文件审查字段。
- `## Appendix: adjudication details`：记录来源、使用方、解决结果与链接。
- `## Appendix: stop-review evidence`：记录详细评审证据产物的指针。
