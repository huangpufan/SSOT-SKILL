# <runtime owner>

> 行文风格：写给任何冷读者。每节先散文后表格；表格是索引而非段落。
> Walkthrough / Easily confused with / Out of scope / See also 是面向读者的结构槽位 ——
> 要么填写，要么显式 `not_applicable: <原因>`。详见 `ssot-bootstrap` §3.7
> 以及 `SKILL_STYLE.md` reader-scaffolds 章节。

> Architecture domain README。用于一个 runtime owner：拥有独立状态/资源、契约、生命周期、失败/恢复、验证或实现 gap 的边界。不要把本文件当通用 checklist。不适用的可选章节直接删除。

## 为什么这个 Owner 独立

用 1-3 段说明边界、拥有的 runtime responsibility，以及如果并入其他 owner 会导致什么变得不安全或不清楚。

- **包含**：
- **不包含**：
- **主要证据**：

## 拥有的状态与资源

说明这个 owner 写入、持久化、派生或保护的 state/resource。若没有状态/资源职责，用散文说明原因，不要留下空表。

| State / resource | Write owner | Readers / derived users | Lifecycle / persistence | Evidence |
|---|---|---|---|---|
| | this owner | | | |

## 契约面

只列这个 owner 维护兼容语义的 contract：API、SDK、protocol、event、schema、file format、CLI 或 external integration。每行内联携带 `state: contract | design | poc | debt`（`ssot-bootstrap` §3.7）与 surface anchor（`ssot-preflight/references/architecture.md` §16）。doctor `[SURFACE-PIN]` (14T) 与 `[STATE-TAG]` (14V) 校验本表。

| Contract | Compatibility promise | Callers / consumers | Surface anchor | state | Evidence / tests |
|---|---|---|---|---|---|
| | | | GET /api/foo (`src/.../routes.py:42`) / `frontend/.../Component.tsx` / Playwright `frontend/e2e/foo.spec.ts::name` | contract / design / poc / debt | |

## 生命周期与失败边界

仅在这个 owner 具有独立边界时说明 startup/shutdown、concurrency、retry、rollback、demotion 或 recovery。

| Boundary | Normal lifecycle | Failure / recovery | Evidence |
|---|---|---|---|
| | | | |

## Failure trace

doctor `[FAILURE-TRACE]` (14U) 校验已发生失败模式的回归覆盖；每行对应一个咬过本 owner 的失败模式。

| Failure mode | Detection | Recovery | Regression test or bug | state |
|---|---|---|---|---|

### 走查（canonical flow）
<!-- 当本 domain 在下方 Runtime Flows 表中至少有一条关键流时必填。
     用 ≤ 200 字散文走一条典型流的端到端：触发 → owner 调用序列 → 最终状态。
     surface/symbol pin 引用下表，不要把表格数据复制成散文。 -->

## Runtime Flows

只保留承重 flow：跨边界调用、持久写入、资源生命周期、user/ops/API 行为、locks/transactions/retries、trust boundary 或高风险 dense algorithm。

| Flow | Diagram ID | Why included | State / contract touched | Evidence |
|---|---|---|---|---|
| | `<DOMAIN-FLOW-...-CURRENT>` | | | |

## 不变量

列出让这个 owner 可安全修改的不变量。不要复制 product acceptance 或 root-level invariants。

| Invariant | Why it exists | Consequence if violated | Evidence |
|---|---|---|---|
| | | | |

## Symbols

每个 invariant / contract 行至少携带一个 `path:src/...:LNN` 或 `tests/...::test_*` anchor，让冷读 Agent 一跳即可定位（doctor `[SYMBOL-PIN]` / 14S）。

| Symbol | Kind | Owner anchor | state | Evidence |
|---|---|---|---|---|
| `<symbol name>` | function / class / route / SQL identifier / DOM selector | `path:src/...:LNN` or `tests/...::test_*` | contract / design / poc / debt | |

## 验证与证据

给出修改这个 owner 时的最小充分检查或 runtime evidence。

| Change family | Minimal sufficient verification | Evidence owner |
|---|---|---|
| | | |

## Capability → Surface registry

只维护 runtime authority 属于本 domain 的 row。若产品 capability 拥有聚合
surface row，则本处链接到 capability owner，不复制该行。

| Capability link | Route or module | Component | Test |
|---|---|---|---|

## Playbook

机械任务分支（≥3 个有序操作）写在 [`./playbook.md`](./playbook.md)，模板见 `ssot-bootstrap/assets/templates/{en,zh}/architecture-domain-playbook.md`。若本 domain 没有这类任务分支，写 `not_applicable` 与原因即可。

## Local Current / Target / Gap

这个 owner 拥有其边界内的详细实现姿态。Global CTG 只索引本行，不复制细节。

| Topic | Current | Target | Gap / next evidence |
|---|---|---|---|
| | | | |

## 图

Mermaid fenced block 是权威图。Current 和 target 图必须分开。只在边界、flow、state/resource lifecycle、lifecycle/concurrency、failure/recovery 或 trust/config 不明显时加图。

### 图索引

| Diagram ID | Status | Coverage | Evidence |
|---|---|---|---|
| `<DOMAIN-CTX-CURRENT>` | current / target / stale | boundary/context | |
| `<DOMAIN-FLOW-...-CURRENT>` | current / target / stale | runtime flow | |

<!-- 图类型标注（v2.51）：本文件每个 Mermaid 块 SHOULD 携带
     `<!-- diagram_type: component|sequence|state|flow -->` 注释，且一块一类
     不混用。子系统页面 SHOULD 在第一屏（任何表格之前）出现 component 图。
     Doctor 15U / 15V 检查这条。 -->

### Current Boundary / Context

- **Diagram ID**: `<DOMAIN-CTX-CURRENT>`
- **Status**: `current`
- **Coverage**: boundary and external dependencies。
- **Evidence**:

```mermaid
<!-- diagram_type: component -->
flowchart LR
  caller["<caller>"] --> owner["<runtime owner>"]
  owner --> dependency["<dependency>"]
```

## decomposition_basis

- **选择的拆分轴**: `runtime owner` / `single-level`
- **为什么这个 owner 独立**:
- **Independence signals**: state / resource / contract / lifecycle / failure / invariant / verification / current-target-gap
- **Rejected false friends**: source directory / package name / team / external topic tree
- **Owner anchor**: 本文件拥有 `<runtime owner>` 的 runtime facts；非 owner facts 链接出去。
- **覆盖深度**: `deep` / `sampled` / `inferred` / `unknown`
- **覆盖范围**:
- **停止审查**: `<reviewer>` 返回 `no-more-required-changes` / `needs-fix`。

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

## Source Material Pointers

| Source material | Lifecycle / classification | Absorbed fact | Status / conflict |
|---|---|---|---|
| | working/* / historical/* / external/source-material / public/thin-entry; absorb / link-only / stale/conflict / obsolete | | |
