# 当前 / 目标 / 差距

> 行文风格：写给任何冷读者。详见 `ssot-bootstrap` §3.7。

> 跨域实现演进视角。本文件分离已实现事实和目标技术设计，并解释迁移立场。它从 domain evidence、decisions 和 product owners 综合 implementation gap，不拥有具体状态/契约/失败细节，也不重新定义 product roadmap 或 product acceptance。它不能把设计意图压平成只有状态表。

## 范围

- **负责**：全局 implementation current/target/gap、迁移优先级、部分落地的技术设计意图、product acceptance 的实现差距、过时/冲突的技术设计 源资料，以及开放设计裁决。
- **链接但不拥有**：product roadmap、phase intent、product-level gaps 和 product acceptance gates；这些由 `product/roadmap-and-acceptance.md` 或相关 product owner 拥有。
- **不负责**：domain 内实现细节。每个具体 gap 都应链接到 domain、decision、bug、gotcha、test 或 tech-debt 条目。
- **主要 源资料**：

## 为什么这个视角存在

用 1-3 段说明系统当前实现姿态：什么已经成立、目标技术状态是什么、哪些 product acceptance 仍有实现 gap，以及未来 Agent 应如何在实现便利、产品约束和设计方向之间取舍。

## 叙述 / 模型

用自然语言解释迁移模型：哪些当前实现是有意保留的，哪些是过渡态，未来工作应优先处理或避免什么。

## 设计意图 / 约束

| 意图或约束 | 当前关系 | 为什么重要 | 证据 / 决策 |
|---|---|---|---|
| | implemented / partial / diverged / pending | | |

## 迁移立场

- **当前基线**：
- **Product owner links**：
- **目标技术设计**：
- **最高优先级 gaps**：
- **当前阶段非目标**：
- **风险容忍 / 回滚立场**：

## 当前 / 目标 / 差距 矩阵

| 区域 | 当前实现事实 | 目标技术意图 / product constraint | Implementation gap / 阻塞项 | 权威 owner | 证据 |
|---|---|---|---|---|---|
| | | | | product / domain / decision / debt / adjudication | |

## 部分落地的设计意图

| 意图 | 落地状态 | 缺失部分 | 决策 / 来源 | 所需裁决 |
|---|---|---|---|---|
| | pending / partial / diverged / implemented | | | |

## 被拒绝的替代方案 / 不要复活

| 旧形态或被拒绝方案 | 为什么拒绝 | 替代方向 | 执行位置 |
|---|---|---|---|
| | | | decision / domain / gotcha / test |

## 开放设计问题

| 问题 | 为什么重要 | 何时需要 | 当前默认 | 链接 |
|---|---|---|---|---|
| | | | | |

## 相关 Domains

| Domain owner | Current / target 职责 | Gap / decision / debt 链接 |
|---|---|---|
| | | |

## 证据

| 断言 | 源资料 / 代码 / 运行证据 | 置信度 | 后续动作 |
|---|---|---|---|
| | | verified / documented / inferred / unknown | |
