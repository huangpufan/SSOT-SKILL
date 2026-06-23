# <目录名>

> 一句话定位：本目录承担什么职责、面向谁、停止下钻条件。

## 目录地图

```
<dir-name>/                         <一句话功能注释>
├── <child-or-file-1>               <这一项做什么；用朴素语言；冷读者读得懂>
├── <child-or-file-2>               <这一项做什么；如果是 jargon 文件名，这里翻译成朴素描述>
├── ...
├── README.md                       本文件
└── _manifest.md                    SSOT 自维护用，跳过
```

推荐阅读顺序：先 `<child-A>`（建立基线），再 `<child-B>`（深入主线），最后视任务读 `<child-C>`。
（如果子项已用 `NN-` 数字前缀，这一行可省略。）

## 为什么这样拆

<一段话，不超过 5 句：本目录为什么作为独立 facet 存在；按什么轴拆；拒绝了什么轴；冷读者最容易误以为重叠的兄弟边界在哪里。>

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

## 进一步阅读

- 上一层入口：[`../README.md`](../README.md)
- 跨域视角：[`<cross-cutting-view>`](<path>)（可选）
- 任务路由：见 [STATUS.md](<path-to-status>)

<!--
模板使用须知：

1. 目录地图必须是本 README 第一屏内容（H1 + 一句话定位之后立刻出现）。
2. 每个子项的注释列写一句话，用朴素语言，不出现未在 map 内定义的 jargon。
3. `_manifest.md` 行必须显式写 "SSOT 自维护用，跳过"。
4. 如果子项数量很多（>10），可按 facet 分组，每组前加一行小标题。
5. Doctor 15N/15O/15P/15Q 守这四条；详见 doctor.md。
6. 维护清单、能力注册、stop-review 笔记等机器侧元数据，归 `_manifest.md`，不放本 README 第一屏。
-->
