# Capability：<Capability Name>

<!-- 可选模板。仅当某个 capability 具有持久产品价值、边界、非目标、acceptance meaning 或 roadmap state，且继续放在 product spine 中会使其膨胀时，再实例化本模板。 -->

> 行文风格：写给任何冷读者。详见 `ssot-bootstrap` §3.7。

## 一句话讲清楚这个 capability [MUST]

依次写三层：

1. **一句话概述**：用一句平实的话讲清楚这个 capability 对用户意味着什么（"X 让某类用户在 Y 场景下能 Z"）。
2. **一个具体场景**：用 2–4 句话描述一个具体使用场景（"想象一个用户在 …"），让没接触过产品的读者立刻有画面。
3. **为什么独立 owner**：用 1–2 段说明它的产品边界为什么需要从 spine 拆出来独立维护（持久用户价值 / 独立非目标 / 独立 acceptance / 独立 roadmap 状态）；如果只是因为"想细写一下"，应当合并回 spine。

## Product boundary（产品边界）

| In scope | Out of scope | Why |
|---|---|---|
| | | |

## 用户价值

| User / operator | Value | Evidence |
|---|---|---|
| | | |

## Acceptance 含义

| Acceptance | Product meaning | Evidence / testing link |
|---|---|---|
| | | |

## Roadmap 状态

| Phase | Status | Notes |
|---|---|---|
| | planned / active / deferred / shipped / obsolete | |

## 架构 owner 链接

| Product constraint | Architecture owner | Implementation gap |
|---|---|---|
| | | |

## Capability → Surface registry

产品侧镜像 `ssot-preflight/references/architecture.md` §16；钉住该 capability 落地的每个 surface。`contract` 状态行若没有指向 Playwright 测试，会被 doctor 拦下（CLAUDE-MAXIM-2：jsdom 不算浏览器证据）。

| Surface | Route or module | Component | Test | state |
|---|---|---|---|---|
