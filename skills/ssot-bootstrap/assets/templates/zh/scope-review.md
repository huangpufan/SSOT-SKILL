---
review_id: scope-review:<process|records|glossary|root|status>:YYYYMMDD:<slug>
review_scope: <process|records|glossary|root|status>
completeness_profile: <same-scope-token>
protocol_version: "<tracked-skill-version>"
reviewed_on: YYYY-MM-DD
reviewer: <stable-human-or-agent-id>
reviewer_role: <scoped-self-review|independent-reviewer>
repository_commit: <resolvable-full-or-short-commit>
entrypoint: <canonical-scope-entrypoint>
scope_fingerprint: <lowercase-sha256>
area_disposition_fingerprint: <lowercase-sha256>
quality_disposition_fingerprint: <lowercase-sha256>
profile_item_count: <46|46|38|37|32>
covered_item_count: <integer>
not_applicable_item_count: <integer>
unresolved_required_changes: <integer>
authorises: <area:process:covered|area:records:covered|area:glossary:covered|scope:root:covered|scope:status:covered|coverage_result:converged>
verdict: <needs-fix|no-more-required-changes>
---

# 精确范围评审：<范围>

<!-- 本轻量产物只用于 process、records、glossary、root 或 STATUS。
     产品和架构使用 reader-review.md；这里不复制十六叶评分。产物通过并从
     STATUS 链接前，删除所有作者注释。 -->

## 评审基线

说明冻结了什么、谁完成评审、本产物授权哪项当前结论，以及证据的适用边界。
按区域评审时，区域状态与停止审查闸门的对应行必须解析到同一个文件；root 与
STATUS 只使用各自的停止审查闸门行。

| 检查 | 结果 | 证据与限制 |
|---|---|---|
| 范围身份与当前指纹 | pass / needs-fix | <证据与限制> |
| 所有者与路由可解析 | pass / needs-fix | <证据与限制> |
| STATUS 结论与产物一致 | pass / needs-fix | <证据与限制> |

除了检查路由，还要抽样核对语义真实性。每个画像家族至少抽一条（例如 process
要覆盖 C、PR、Q）。如果精确画像同时使用 `covered` 与 `not_applicable`，两种
处置各抽至少一条。通过的产物中，每条真实性结果都只能是 `pass`。

| 项目 ID | 所有者正文结论 | 仓库或证据样本 | 真实性结果 | 限制 |
|---|---|---|---|---|
| <抽样画像-ID> | <在链接所有者正文中核对的具体结论> | [仓库或证据样本](<可解析路径>) | pass / needs-fix | <本样本不能证明什么> |

把这个范围中每个真实读者目标恰好列一次。同一目标上实际核对的画像 ID
放在一个逗号分隔的单元格里；整张表的 ID 并集必须覆盖完整精确画像。

| 目标 ID | 目标所有者 | 已核验画像 ID | 仓库或证据样本 | 真实性结果 | 限制 |
|---|---|---|---|---|---|
| <稳定目标-ID> | <白话所有者名称> | <逗号分隔的精确画像 ID> | [精确目标所有者](<可解析路径或锚点>) | pass / needs-fix | <本目标检查不能证明什么> |

## 精确画像

<!-- 只使用一个画像：process=C01-C09+PR01-PR16+Q01-Q21（46），
     records=C01-C09+R01-R16+Q01-Q21（46），
     glossary=C01-C09+G01-G08+Q01-Q21（38），
     root=C01-C09+RT01-RT07+Q01-Q21（37），或
     status=S01-S11+Q01-Q21（32）。每个所有者/证据单元格只放一条可解析
     Markdown 链接。白话结论要写当前真实结论，不能复读画像问题或协议 ID。 -->

| 项目 ID | 处置 | 白话结论 | 所有者或证据 |
|---|---|---|---|
| <精确画像-ID> | covered / not_applicable: <具体理由> | <用平实语言写明具体当前结论> | [所有者或证据](<可解析路径>) |

## 必改项与结论

| 必改项 ID | 状态 | 必改内容 | 所有者 | 闭合证据 |
|---|---|---|---|---|
| 无 | none | 本轮评审后没有剩余必改项。 | — | 未闭合项数量为零，最终结论为 no-more-required-changes。 |

最终结论：`<needs-fix|no-more-required-changes>`。
