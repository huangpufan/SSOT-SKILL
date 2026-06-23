# 产品

> 行文风格：写给任何冷读者。每节先散文后表格；表格是索引而非段落。
> Walkthrough / Easily confused with / Out of scope / See also 是面向读者的结构槽位 ——
> 要么填写，要么显式 `not_applicable: <原因>`。详见 `ssot-bootstrap` §3.7
> 以及 `SKILL_STYLE.md` reader-scaffolds 章节。

> 产品事实入口。本区域拥有 PRD、产品承诺、用户/操作者、产品边界、capability、journey、roadmap 和 product acceptance。Architecture 只链接本区域 owner，并记录实现设计或 gap。
>
> 本文件先建立产品心智模型，再路由到 owner；不复制详细产品事实正文。

## 产品意图与产品真相

在任何表格前写 2-5 段短散文。冷读者应先理解：产品服务谁、解决什么问题、当前承诺是什么、目标姿态或缺口在哪里、明确不做什么、验收在产品语境下意味着什么，以及需要细节时先读哪个 owner。

本节只综合已有 owner，不创建第二事实源。细节归 `prd.md`、`product-model.md`、`roadmap-and-acceptance.md`、capability owner 与 journey owner。

## Product Reader Map（产品阅读地图）

| 读者问题 | First stop | Authoritative owner | Evidence direction | Stop condition / risk |
|---|---|---|---|---|
| 产品当前承诺什么、目标姿态是什么、不做什么？ | [prd.md](./prd.md) | PRD spine | PRD / README / user-provided product source | 能定位每个核心承诺的 owner |
| 谁是用户/操作者，问题和产品语言是什么？ | [product-model.md](./product-model.md) | Product model | user research / support docs / product source | 用户、问题、promise、边界不重复维护 |
| 产品 roadmap、phase 和验收 gate 是什么？ | [roadmap-and-acceptance.md](./roadmap-and-acceptance.md) | Roadmap and acceptance | roadmap / issue / release / acceptance evidence | Product acceptance 与 technical tests 分离但可互链 |
| 某个 capability 是否有独立长期产品边界？ | [capabilities/README.md](./capabilities/README.md) | Capability owner index | PRD / roadmap / acceptance / support source | 不为一次性 ticket 或实现 flow 建 capability |
| 某个 journey 是否跨 capability 并影响优先级？ | [journeys/README.md](./journeys/README.md) | Journey owner index | journey map / product source / acceptance | 用户意图和 touchpoints 在 product，runtime flow 在 architecture |

## Owner 索引

| 产品事实类型 | Owner | 备注 |
|---|---|---|
| PRD spine / product posture | [prd.md](./prd.md) | 简洁主线，不做全文 PRD 镜像 |
| Users / problems / promises / boundaries | [product-model.md](./product-model.md) | 负责产品语言和长期取舍 |
| Roadmap / acceptance / product gaps | [roadmap-and-acceptance.md](./roadmap-and-acceptance.md) | 负责产品验收 gate |
| Capability details | [capabilities/](./capabilities/README.md) | 只收稳定 capability owner |
| Journey details | [journeys/](./journeys/README.md) | 只收跨 capability 或独立验收 journey |

## 能力 ↔ 旅程关系图（Capabilities ↔ Journeys）

> 可选。小型产品主干写 `not_applicable` 和原因。该图只展示 capability /
> journey 关系一览，把读者路由到 owner，不承载独立产品事实。

```mermaid
<!-- diagram_type: component -->
flowchart LR
  prd["PRD spine"] --> cap1["capability A"]
  prd --> cap2["capability B"]
  cap1 --> j1["journey 1"]
  cap2 --> j1
```

## 拆分规则

- 保持事实在最高稳定 owner。不要为一次性 feature、ticket、UI script、测试用例或 implementation flow 创建 product 文件。
- 当 capability 具有持久用户价值、边界、非目标、acceptance meaning 或 roadmap state，且继续放在 spine 会膨胀时，拆到 `capabilities/<capability>.md`。
- 当 journey 跨多个 capabilities、影响 roadmap/release 决策、拥有独立 product acceptance，或反复驱动 priority tradeoff 时，拆到 `journeys/<journey>.md`。
- 产品事实由 product 拥有；architecture 只记录实现设计、runtime execution、lifecycle、failure/recovery、observability 和 technical gap。

## 走查（Walkthrough）
<!-- 用一段完整的散文描述本 owner 端到端的一次具体工作；不要用表格。
     若 owner 本质是索引（如 SSOT/README.md 不是系统而是索引），显式写
     `not_applicable: <原因>` 跳过。 -->

## 容易混淆（Easily confused with）
<!-- 1-3 个最容易被冷读者混淆的兄弟 owner；每条一行：
     `**[兄弟 owner]** — [区分边界的一句话]`。 -->

## 不回答（Out of scope）
<!-- 一句话说明本 owner 不回答什么，指向回答它的 owner。
     即便没有也必须显式写（如 `none — covers complete intent`）。 -->

## 延伸阅读（See also）
<!-- 3-7 条向外的链接花束；本节存在后，正文中不应再出现纯导航链接。
     每条链接附一句话说明读者为什么要去那里。 -->

## 源资料

| 源资料 | 分类 | Product owner | Architecture / testing cascade |
|---|---|---|---|
| | absorb / link-only / stale/conflict / obsolete | | |
