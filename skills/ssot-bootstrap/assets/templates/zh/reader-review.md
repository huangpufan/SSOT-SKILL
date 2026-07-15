---
review_id: "review:<product|architecture>:<YYYYMMDD>:<slug>"
review_scope: "<SSOT/01-product | SSOT/02-architecture>"
review_type: "<high-impact-adoption | routine>"
reader_profile: implementation-delegator
completeness_profile: "<product | architecture>"
protocol_version: "<tracked_skill_version>"
reviewed_on: "<YYYY-MM-DD>"
reviewer: "<稳定的人或 Agent ID>"
reviewer_role: "<independent-cold-reader | scoped-self-review>"
repository_commit: "<可解析且为 HEAD 祖先或 HEAD 本身的 commit>"
content_fingerprint: "<共享读者表面的 sha256 小写摘要>"
quality_disposition_fingerprint: "<lowercase-sha256>"
sample_seed: "<稳定抽样种子>"
rotation_id: "<稳定轮换 ID>"
task_count: 6
passed_task_count: "<数量>"
failed_task_count: "<数量>"
entrypoint: SSOT/README.md
tables_hidden: true
bounded_read_set: true
route_probe: "<passed | failed>"
truth_consistency: "<passed | failed>"
evidence_sample: "<passed | failed>"
scored_dimensions: 16
score: "<得分>/32"
critical_truth_errors: "<数量>"
unresolved_required_changes: "<数量>"
authorises: "<area:product:covered | area:architecture:covered>"
verdict: "<needs-fix | no-more-required-changes>"
---
# 冷读评审

<!-- 渲染后的产物必须且只能包含上面 29 个标量 frontmatter 字段，每个字段恰好
     一次，不使用别名，也不增加额外键。reviewer 是跨轮次稳定的身份 ID，不能
     使用每次都可能变化的显示名称。authorises 必须与 review_scope 和
     completeness_profile 精确匹配。 -->

<!-- 渲染后的评审保存在 SSOT/.bootstrap/，并替换全部占位符。
     high-impact-adoption 必须由独立冷读者执行；routine 按 status-protocol §6
     选择 reviewer_role。评审者角色与 implementation-delegator 读者画像分开。 -->

<!-- 面向 implementation-delegator 写评审：每项任务先给具体情境与决定，再记录
     委托动作、可见成功、失败/恢复与合适证据，最后才使用路径和内部标签。 -->

<!-- 渲染后，所有事实所有者或证据链接都必须使用相对路径，并解析到当前消费方
     SSOT 内真实、普通、非符号链接的 Markdown 文件。禁止绝对路径、URL、工作区
     之外的路径、SSOT/.bootstrap/ 下的评审产物，以及指向本评审的自链接；链接
     带锚点时，锚点必须真实存在。只有可见 Markdown 才能满足协议，藏在 HTML
     注释或代码围栏里的标题、表格、证据和结论都不算。写出通过结论前，删除全部
     作者注释和占位符。 -->

## 有界阅读集

<!-- 每个任务从 SSOT/README.md 开始，记录实际打开文件与最多四次 owner 链接
     跳转。首次复述前不读源码、manifest、旧评审、作者计划或预期答案。
     路由探针放在本节，不新增第七个 H2。 -->

| 步骤 | 页面 | 原因 | 跳数 | 摩擦 |
|---|---|---|---:|---|
| 1 | SSOT/README.md | 初始读者路线 | 0 | |

### 必做任务矩阵

<!-- 产品范围逐一使用 reader-quality §7.2 的六个 product-* 类别；架构范围
     逐一使用六个 architecture-* 类别。不能合并、改名、遗漏或凑数。“打开的
     文件”记录实际打开的消费方 SSOT Markdown 文件。“证据与限制”先放一条指向
     消费方 SSOT 事实所有者或锚点的相对 Markdown 链接；裸路径和 SSOT 外链接
     不能作为证据。 -->

| 任务类别 | 读者与决策 | 委托动作 | 预期可见结果 | 停止或升级条件 | 入口 | 打开的文件 | 实际跳数 | 观察结果 | 隐藏表格结果 | 证据与限制 | 结论 |
|---|---|---|---|---|---|---|---:|---|---|---|---|
| <精确任务类别> | | | | | SSOT/README.md | | | | pass / fail | | pass / fail |

结果栏使用协议值：`pass` 表示通过，`fail` 表示未通过；未通过时必须在必改项中
给出具体修复和所有者。

### 任务到叶维度适用关系

<!-- 评分前，把 RF1-RF2、LA1-LA3、CT1-CT4、BC1-BC4、RP1-RP3 每个叶维度
     映射到一个或多个必做任务。 -->

| 任务类别 | 适用叶维度 ID | 适用原因 |
|---|---|---|
| <精确任务类别> | <逗号分隔的叶维度 ID> | |

### 有限所有者与目标覆盖

<!-- 对完整的冻结目标清单逐项核对，不能只挑方便的样本。产品范围包括每个产品
     主干、能力和旅程所有者，每个产品表面清单行，以及每个产品到架构桥接行。
     架构范围包括根、视图和领域读者页，每个直接所有者分类，每个适用视图或有
     理由的合并/不适用处置，每个技术表面行，以及每个桥接行。有理由的
     not_applicable 或合并处置也必须列入。每个稳定目标 ID 恰好出现一次，至少
     分配给一个必做任务，并用平实语言写清决定、委托动作和可见结果。通过的产物
     不能有遗漏、重复、未分配、延后或失败目标。深入源码/运行时证据可以轮换，
     所有者和目标覆盖不能轮换省略。完整清点放在首次隐藏表格复述之后，不能用
     后续清点修补失败的有界路由，也不能改写当时的复述。下表列出的每个适用
     冻结清单类别各写一行；删除选项串，不能把多个类别合成一个数量。 -->

| 冻结清单类别 | 来源清单 | 应有目标数 | 已列目标数 | 对账结果 |
|---|---|---:|---:|---|
| product-reader-owner / product-surface / product-bridge / architecture-reader-owner / architecture-direct-owner / architecture-view / technical-surface / architecture-bridge | [冻结来源清单](<SSOT-内相对-Markdown-路径或锚点>) | <数量> | <数量> | pass / fail |

| 目标 ID | 目标类别 | 冻结处置 | 所有者正文 | 分配到的必做任务 | 决定、委托动作与可见结果 | 结果 | 证据与限制 |
|---|---|---|---|---|---|---|---|
| <稳定目标 ID> | 读者所有者 / 产品表面 / 技术表面 / 跨所有者视图 / 桥接 | <来源清单中的精确处置> | [所有者正文](<SSOT-内相对-Markdown-路径或锚点>) | <精确任务类别> | | pass / fail | [合适的所有者或证据](<SSOT-内相对-Markdown-路径或锚点>)；<它不能证明什么> |

### 路由探针

<记录错误路径、缺失所有者和超出跳数预算的任务。>

## 复述

<!-- 隐藏 Markdown 表格。implementation-delegator 不读源码也必须讲清当前因果
     故事、可见结果、边界、失败恢复与下一项决策；还必须知道该委托什么，
     以及怎样验收结果。 -->

### 隐藏表格后的复述

<写出冷读者自己的复述。>

### 不清楚或无法恢复的内容

<写出问题及最应该讲清它的所有者。>

## 一致性与证据抽样

### 跨所有者事实一致性

<!-- 所有者和对照所有者单元格使用相对 Markdown 链接，精确指向消费方 SSOT 内
     正在比较的正文或锚点。 -->

| 结论 | 所有者 | 对照所有者 | 结果 | 说明 |
|---|---|---|---|---|
| | | | pass / fail | |

### STATUS 覆盖结论闭环

<!-- 产品或架构以 no-more-required-changes 写 covered 前，停止审查闸门必须且只能
     有一条当前行。该行的评审者、评审者角色、评审日期、结果、证据产物和
     authorises 必须与本评审一致。STATUS 的证据单元格解析到本评审产物；这里
     不要反向添加自链接。高影响采用在两处都使用 independent-cold-reader。
     needs-fix 产物可以没有 STATUS 行——缺行本身可能正是失败原因。此时精确填写
     `none: needs-fix does not authorise covered`，证据填 no，匹配结果填
     not-authorised。绝不能保留一条仍在授权失败 covered 结论的当前通过行。 -->

| STATUS 行 | 范围 | 停止结论 | 评审者 | 评审者角色 | 评审日期 | 结果 | STATUS 证据解析到本产物 | authorises | 匹配结果 |
|---|---|---|---|---|---|---|---|---|---|
| <[当前停止审查闸门](../STATUS.md#停止审查闸门) 或 none: needs-fix does not authorise covered> | product / architecture | covered | <同一个稳定评审者 ID> | independent-cold-reader / scoped-self-review | <同一个 YYYY-MM-DD> | needs-fix / no-more-required-changes | yes / no | area:product:covered / area:architecture:covered | pass / not-authorised / fail |

### 证据抽样

<!-- 每个必做任务一行。路径存在不等于语义正确；记录结论、语义适配度、浏览器
     real-runtime 或 rendered-mocked 保真度、证据何时失效、观察结果与抽样限制。每个
     证据单元格恰好放一条指向消费方 SSOT 所有者或锚点的相对 Markdown 链接；
     实际检查的底层源码或运行时对象用平实文字写在适配度单元格。 -->

| 任务类别 | 结论 | 证据 | 适配度、保真度与证据是否仍有效 | 结果 | 限制 |
|---|---|---|---|---|---|
| <精确任务类别> | | | | pass / fail | |

### 冷读硬探针

| 探针 ID | 必做任务证据 | 结果 | 限制 |
|---|---|---|---|
| CP-D | | pass / fail | |
| CP-R | | pass / fail | |
| CP-T | | pass / fail | |
| CP-E | | pass / fail | |
| CP-C | | pass / fail | |

## 维度评分

<!-- 每个任务/叶维度给 0、1、2 分，叶维度取全部适用任务的最低分。通过要求
     >=29/32、无零分，族下限 RF>=3、LA>=5、CT>=7、BC>=7、RP>=5；
     implementation-delegator 还要求 RF1=2、LA2=2。每个“原因与页面”单元格
     放一条相对链接，指向消费方 SSOT 内真正支撑该得分的可见正文或锚点。 -->

| 族 | 叶维度 ID | 维度 | 适用任务得分 | 得分 /2 | 原因与页面 |
|---|---|---|---|---:|---|
| 读者适配 | RF1 | 读者、决策与行动适配 | <任务=得分;...> | | |
| 读者适配 | RF2 | 定位与可见结果 | <任务=得分;...> | | |
| 平实清晰与易懂性 | LA1 | 首次使用术语 | <任务=得分;...> | | |
| 平实清晰与易懂性 | LA2 | 平实语言与认知负担 | <任务=得分;...> | | |
| 平实清晰与易懂性 | LA3 | 具体场景落地 | <任务=得分;...> | | |
| 因果与事实叙事 | CT1 | 因果链 | <任务=得分;...> | | |
| 因果与事实叙事 | CT2 | 当前事实与跨所有者一致性 | <任务=得分;...> | | |
| 因果与事实叙事 | CT3 | 姿态、不确定性与变化 | <任务=得分;...> | | |
| 因果与事实叙事 | CT4 | 成功、失败与恢复 | <任务=得分;...> | | |
| 边界与覆盖 | BC1 | 边界与非目标 | <任务=得分;...> | | |
| 边界与覆盖 | BC2 | 唯一所有者与交接可达性 | <任务=得分;...> | | |
| 边界与覆盖 | BC3 | 证据适配度、保真度，以及何时失效 | <任务=得分;...> | | |
| 边界与覆盖 | BC4 | 范围完整性 | <任务=得分;...> | | |
| 阅读路径 | RP1 | 可扫描性与渐进披露 | <任务=得分;...> | | |
| 阅读路径 | RP2 | 有界路由与局部性 | <任务=得分;...> | | |
| 阅读路径 | RP3 | 脱离表格的叙事 | <任务=得分;...> | | |
| **总分** | | | | **/32** | |

## 完整性画像

<!-- 产品精确记录 53 行：C01-C09、P01-P23 与 Q01-Q21 各一次；架构精确记录
     48 行：C01-C09、A01-A18 与 Q01-Q21 各一次。处置只能是 covered 或
     not_applicable，每行都要写
     原因和证据/owner 方向。C08 检查不可避免的术语、假设、状态、命令或证据
     标签在首次使用前是否先用普通话解释；C09 要求具体情境能讲清决定、委托
     动作、可见结果与合适证据。P21 包含 command、public-interface、
     output-artifact、notification 与 help-onboarding 表面。P22 解释当前
     问题、价值与承诺；P23 负责持续价值和反馈回到路线图的真实学习闭环。
     A18 负责设计驱动、全局约束、取舍、技术非目标与拆分理由。运行时需要但
     缺少 metrics/traces 时应登记缺口，不能随意写 N/A。每个“原因与证据”
     单元格包含一条相对链接，指向消费方 SSOT 的事实所有者或精确边界锚点；
     所有者名词串和裸路径都不算。 -->

| 项目 ID | 处置 | 原因与证据 |
|---|---|---|
| <精确项目 ID> | covered / not_applicable | |

处置栏使用协议值：`covered` 表示已经讲清并有证据；`not_applicable` 表示确实不适用，
必须同时写出具体理由和证据方向。

## 必改项与结论

<!-- 每个真实必改项使用唯一 RC-NN ID；状态只用 resolved、pending、required
     或 open。pending/required/open 的行数必须等于
     unresolved_required_changes。通过且没有历史 resolved 行时，只保留下面
     这一行 none 哨兵；none 不能与真实必改项共存。真实行中的所有者和闭合证据
     链接也必须遵守“相对路径且只在消费方 SSOT 内”的边界。 -->

| 必改项 ID | 状态 | 必改内容 | 所有者 | 闭合证据 |
|---|---|---|---|---|
| none | none | 本轮复核后没有剩余必改项。 | — | 未解决项为零，最终结论为 no-more-required-changes。 |

<!-- no-more-required-changes 要求六个任务、五个硬探针、包括 Q01-Q21 在内的
     精确完整性画像、匹配的质量处置摘要、总分/族/persona 下限、事实与证据检查全部通过，且严重
     错误和未解决改动均为零，同时完整覆盖有限所有者/目标清单，并且只有一条匹配
     的 STATUS 停止审查行。否则使用 needs-fix。下面的可见结论、frontmatter
     verdict、未解决数量和必改项表必须始终一致。通过结论还必须与 STATUS result
     一致；needs-fix 在没有 stop row 时可以使用 not-authorised 哨兵。 -->

最终结论：`<needs-fix|no-more-required-changes>`。
