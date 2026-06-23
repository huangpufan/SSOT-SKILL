---
intent_recovery: covered
---

# <术语>

> 行文风格：写给任何冷读者。每节先散文后表格；表格是索引而非段落。详见 `ssot-bootstrap` §3.7。

**一句话定义**：<不超过 25 字；正向定义；禁止以"X 不是 Y"开头>。

## 扩展定义

<一段；当一句话不足以涵盖术语的完整范围、生命周期或约束时必填>

## 用于（Used in）

- `<area>/<file>` § <section> — <一句话：本术语在此处为什么重要>
- `<area>/<file>` § <section> — <一句话>

## 容易混淆（Not to be confused with）

- **<兄弟术语>** — <一句话区分；用正向定义说明边界>
- **<兄弟术语>** — <一句话区分>

## 证据 pin（Source pin）

- `[CORE-REF: <area>/<file>.md#anchor]` — <原始权威 owner 在哪里>
- `path:src/myapp/...:LNN` 或 `tests/...::test_*` — <代码/测试 pin，若术语已在代码落地>

<!--
模板使用须知（v2.51）：

1. 一术语一文件；多术语索引保留在 `glossary/README.md` 作为目录地图。
2. 正向定义由 Doctor 14I（cell-is-not-a-paragraph）与 15F（`[VOCAB-PROSE-FORK]`）守。
   反向定义只能写在 `## 容易混淆`，不能写在标题。
3. `## 用于` 是反向索引：读者从这里跳到正在消费本术语的非 glossary owner。
4. KISS mini-card 允许形式（v2.51，详见 `SKILL_STYLE.md`）：在消费者 owner
   的散文中，本术语可以以
   `**术语** (def: <≤ 15 字的子句> → [CORE-REF: glossary/<term>.md])`
   形式首次出现，不违反 15F。
-->
