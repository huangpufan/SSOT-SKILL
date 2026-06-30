# 研究与 POC 记录

> 写作姿态：面向任意陌生读者。见 `ssot-bootstrap` §3.7。

研究记录保存 investigation 中可复用的结论，直到这些结论被提升到 product、architecture、testing、decision、gotcha、bug 或 tech-debt owner。这个目录保存证据与边界，不保存没有问题或没有可复现方法的零散猜测。

## 目录地图

```
04-records/research/
├── README.md              本索引。
└── NNNN-<slug>.md         每个 research、spike、benchmark 或 POC 一份记录。
```

Bootstrap 骨架不会创建编号条目。只有存在具体问题、方法、证据和可能的 promotion target 时，才创建条目。

## 何时创建条目

当一个发现将来可能复用，但还不足以成为 product、architecture、testing、decisions、gotchas、bugs 或 tech-debt 的权威正文时，创建 research 条目。常见情况包括 proof-of-concept、benchmark 对比、外部来源核验、设计 spike、可行性研究，以及能阻止未来 agent 重走旧路的 negative finding。

普通任务笔记、会议纪要或一次性命令输出不要放入本目录，除非记录中包含可复用 claim 和清晰证据。

## 研究索引

| 编号 | 标题 | 状态 | Kind | Owner | 创建日期 | Promotion targets | Recheck trigger |
|------|------|------|------|-------|---------|-------------------|-----------------|
| | | draft / validated / promoted / stale / superseded | research / poc / spike / benchmark / experiment | | YYYY-MM-DD | | |

`promotion_targets` 写可能接收被提升结论的 SSOT owner，例如 `SSOT/02-architecture/domains/<domain>/README.md` 或 `SSOT/03-process/testing/README.md`。

## 提升规则

Research 记录本身不是权威。只有证据足够支撑 durable owner 的 claim row 才能被提升；提升后同步更新条目中的 `Promoted SSOT owners`。未提升的 claim 留在 research 记录中，保留边界和 recheck trigger。

如果被提升 owner 后来与 research 记录冲突，以被提升 owner 的 current truth 为准。回头重检本记录，把状态标为 stale 或 superseded，并保留历史证据，不要把它重写成新的结论。
