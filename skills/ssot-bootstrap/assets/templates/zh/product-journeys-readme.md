# Product journey 索引

> 行文风格：写给任何冷读者。详见 `ssot-bootstrap` §3.7。

> Product journey owner 索引。不要在本文件复制 journey 事实正文。Architecture critical journeys 拥有 runtime execution、lifecycle、failure/recovery、observability 和 diagrams。

## 拆分标准

创建 `journeys/<journey>.md` 前必须满足至少一个稳定产品边界信号：

- Journey 跨多个 capabilities。
- Journey 影响 roadmap/release decisions。
- Journey 拥有独立 product acceptance。
- Journey 反复驱动 priority tradeoffs。

不要为实现 flow、测试脚本、单个 UI path 或一次性 ticket 创建 journey 文件。

## Journey owner 索引

| Journey | Owner | Why separate | Product acceptance | Capability links | Architecture runtime link |
|---|---|---|---|---|---|
| | `<journey>.md` | | [../roadmap-and-acceptance.md](../roadmap-and-acceptance.md) | | [../../architecture/views/critical-journeys.md](../../architecture/views/critical-journeys.md) |

## 已拒绝拆分

| Candidate | Why not separate | Current owner |
|---|---|---|
| | | [../prd.md](../prd.md) / [../product-model.md](../product-model.md) |
