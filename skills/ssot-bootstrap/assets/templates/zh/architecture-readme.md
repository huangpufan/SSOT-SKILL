# 架构

> 行文风格：写给任何冷读者。详见 `ssot-bootstrap` §3.7。

> 架构 root 是 Runtime Owner Map。它建立技术心智模型、核心不变量、跨 owner 视角路由、runtime owner domain 路由和证据方向。产品承诺、用户、路线图、非目标和验收语义归 `product/`；architecture 只链接这些 owner，并记录实现响应或实现 gap。

## 设计简报

用 1-3 段说明这个系统是什么、最关键的运行路径是什么、哪些约束让架构可安全演进，以及未来 Agent 必须保持什么。可以命名主要 product owner 链接，但不要在这里重新定义产品承诺。

## 设计意图与设计真相

在任何密集 owner map 或恢复清单前写 2-5 段短散文，从第一性原理解释：为什么选择当前 runtime-owner 拆分轴、今天哪些设计真相已经被执行、哪些仍是 design/debt/Out、哪些近似但非核心的实现清单被刻意排除，以及需要细节时先读哪个 view/domain。

本节只综合 owner，不替代 view/domain 正文。

## Runtime Owner Map

每行把读者路由到状态、资源、契约、生命周期、失败/恢复或验证的 owner。行只做路由，不维护正文事实。

| 读者问题 | Runtime owner | First stop | Evidence direction | Stop condition / risk |
|---|---|---|---|---|
| 哪个进程拥有写入和生命周期？ | `<owner>` | [domains/<owner>/README.md](./domains/<owner>/README.md) | code / config / schema / tests | 读者能定位写入 owner 与生命周期边界 |
| `<surface>` 的契约由谁维护？ | `<owner>` | [domains/<owner>/README.md](./domains/<owner>/README.md) | API / SDK / protocol / schema / tests | 读者能定位兼容语义 |

## 核心不变量

只列跨 runtime owner 生效的不变量。Domain 本地不变量写在 domain README。

| 不变量 | Owner | 为什么存在 | 证据 |
|---|---|---|---|
| | [domains/<owner>/README.md](./domains/<owner>/README.md) | | |

## 视角

只有真正跨 runtime owner 的问题才保留为 view。常见有效 view：critical runtime flows、contract map、failure/recovery map、global current/target/gap index。

| 视角 | 路径 | 跨 owner 问题 | 状态 | 证据 |
|---|---|---|---|---|
| 运行模型 | [views/operating-model.md](./views/operating-model.md) | 跨 owner 的技术运行约束 | gap / covered / stale / unknown | |
| 关键运行流 | [views/critical-journeys.md](./views/critical-journeys.md) | 承重 flow 如何跨 owner | gap / covered / stale / unknown | |
| 契约地图 | `views/contract-map.md` when needed | 哪些 owner 暴露哪些 contract | gap / covered / stale / unknown | |
| 失败 / 恢复地图 | `views/failure-recovery-map.md` when needed | failure 如何跨 owner 并恢复 | gap / covered / stale / unknown | |
| Current / Target / Gap | [views/current-target-gap.md](./views/current-target-gap.md) | 全局迁移姿态和 gap index | gap / covered / stale / unknown | |

## Domains

Domain 拥有详细 runtime 事实。Domain 名称应对齐 runtime owner 边界，不按源码目录机械命名。

| Domain | 路径 | 为什么独立 | 拥有的事实 | Owns surfaces | 状态 | 证据 |
|---|---|---|---|---|---|---|
| `<owner>` | [domains/<owner>/README.md](./domains/<owner>/README.md) | | state / resource / contract / lifecycle / failure / verification | routes / SQL identifiers / DOM selectors / CLI commands handled by this owner | gap / covered / stale / unknown | |

`Owns surfaces` 列出本 domain 拥有的 route 前缀、SQL identifier、DOM selector root 或 CLI command；doctor `[FORK]` (14W) 把跨行重叠视为 fork 信号。

## 架构图

Mermaid fenced block 是权威图。导出的图片只是派生产物。Root 图停留在 owner-map 层；详细 flow/state/failure 图归 views 或 domains。

### 图索引

| Diagram ID | 状态 | 覆盖范围 | 权威位置 | 证据 |
|---|---|---|---|---|
| `<ARCH-OWNER-MAP-CURRENT>` | current / target / stale | runtime owners and cross-owner edges | this file | |

### Current Runtime Owner Map

- **Diagram ID**: `<ARCH-OWNER-MAP-CURRENT>`
- **状态**: `current`
- **覆盖范围**: runtime owners and cross-owner edges。
- **证据**:

```mermaid
flowchart LR
  caller["<caller>"] --> ownerA["<runtime owner A>"]
  ownerA --> ownerB["<runtime owner B>"]
```

## Current / Target / Gap

Root 只保留全局迁移姿态和 gap index 链接。详细 CTG 归相关 view 或 domain。

| Gap | Owner | Current | Target | Next evidence |
|---|---|---|---|---|
| | [views/current-target-gap.md](./views/current-target-gap.md) | | | |

## decomposition_basis

- **选择的拆分轴**: `runtime-owner-map` / `single-level`
- **为什么选择此轴**:
- **Runtime owners**:
- **被拒绝的轴**:
- **Owner anchor**: root 只做路由；domains 拥有 runtime 事实；views 拥有跨 owner 综合。
- **覆盖深度**: `deep` / `sampled` / `inferred` / `unknown`
- **覆盖范围**:
- **停止审查**: `<reviewer>` 返回 `no-more-required-changes` / `needs-fix`。

## Source Material Pointers

完整 inventory 在 `SSOT/STATUS.md`。本 root 只链接已拥有 architecture durable technical fact 的 source。

| Source material | Lifecycle / classification | Authoritative owner | Status / conflict |
|---|---|---|---|
| | working/* / historical/* / external/source-material / public/thin-entry; absorb / link-only / stale/conflict / obsolete | | |
