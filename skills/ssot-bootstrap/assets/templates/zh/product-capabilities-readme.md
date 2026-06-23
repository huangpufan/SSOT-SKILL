# Product capability 索引

> 行文风格：写给任何冷读者。详见 `ssot-bootstrap` §3.7。

> Capability owner 索引。不要在本文件复制 capability 事实正文。

## 拆分标准

创建 `capabilities/<capability>.md` 前必须满足至少一个稳定产品边界信号：

- 持久用户价值和独立产品边界。
- 独立非目标、acceptance meaning 或 roadmap state。
- 继续留在 `prd.md` 或 `product-model.md` 会让 spine 难以阅读。

不要为一次性 feature、ticket、UI script、测试用例或 implementation flow 创建 capability 文件。

## Capability owner 索引

| Capability | Owner | Why separate | Product status | Acceptance link | Architecture link |
|---|---|---|---|---|---|
| | `<capability>.md` | | current / target / gap / obsolete | [../roadmap-and-acceptance.md](../roadmap-and-acceptance.md) | [../../architecture/README.md](../../architecture/README.md) |

## 已拒绝拆分

| Candidate | Why not separate | Current owner |
|---|---|---|
| | | [../prd.md](../prd.md) / [../product-model.md](../product-model.md) |
