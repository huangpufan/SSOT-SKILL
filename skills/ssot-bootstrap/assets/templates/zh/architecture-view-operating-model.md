# 运行模型

> 行文风格：写给任何冷读者。详见 `ssot-bootstrap` §3.7。

> 跨域技术设计意图视角。本文件解释系统如何响应 product owners、技术上优化什么、拒绝优化什么，以及未来工作必须保持哪些设计约束。它不能只有表格。产品承诺和 product acceptance 不在本文件重新定义。

## 范围

- **负责**：技术系统使命、主要 technical actor/caller、运行哲学、实现优先级、技术非目标、非功能成功标准、product constraints 的技术含义和跨域设计约束。
- **链接但不拥有**：产品使命、产品承诺、用户/操作者、产品非目标、roadmap 和 product acceptance；这些由 `product/` 拥有。
- **不负责**：具体状态/资源所有权、API/schema 字段细节或 domain 内失败恢复；这些应链接到 domains。
- **主要 源资料**：

## 为什么这个视角存在

用 1-3 段在组件表格之前告诉新 Agent 技术设计立场。说明产品 owner 对系统施加的约束、服务的 technical actor/caller，以及未来变更必须面对的设计压力。

## 叙述 / 模型

用自然语言描述运行模型：工作如何进入系统、谁信任系统、哪些结果最重要，以及哪些捷径会破坏设计。

## 设计简报

- **Product owner links**：
- **技术使命 / 承诺**：
- **主要 technical actor / caller**：
- **主要 actor / caller**：
- **优化优先级**：
- **非目标**：
- **当前实现优先级**：
- **成功标准**：

## 设计原则

> 把原则记录为决策指导。每条原则都应说明为什么存在，以及未来工作遇到诱人的捷径时应该怎么处理。

| 原则 | 为什么重要 | 由什么保持 | 证据 / 来源 |
|---|---|---|---|
| | | domain / decision / test / runtime evidence | |

## 设计约束

| 约束 | 范围 | 违反后果 | 权威执行点 / 证据 |
|---|---|---|---|
| | | | |

## 主要路径

| 路径 | Product intent / runtime intent | 技术成功信号 | 权威 product journey / architecture domain |
|---|---|---|---|
| | | | product journey owner + [critical-journeys.md](./critical-journeys.md) |

## 相关 Domains

| Domain | 为什么它执行此运行模型 | 约束 / 旅程链接 |
|---|---|---|
| | | |

## 被拒绝的优化 / 非目标

| 非目标或被拒绝的优化 | 为什么拒绝 | 替代做法 | 证据 / 决策 |
|---|---|---|---|
| | | | |

## 当前 / 目标 / 差距

| 区域 | 当前运行模型 | 目标意图 | Gap / 裁决 | 证据 |
|---|---|---|---|---|
| | | | | [current-target-gap.md](./current-target-gap.md) |

## 证据

| 断言 | 源资料 / 代码 / 运行证据 | 置信度 | 后续动作 |
|---|---|---|---|
| | | verified / documented / inferred / unknown | |
