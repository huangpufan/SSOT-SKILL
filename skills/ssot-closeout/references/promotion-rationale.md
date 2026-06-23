# Promotion Rationale

You are deciding the altitude of a rule under PLTL v3. Read this when `$ssot-closeout` or `$ssot-audit` is about to emit a move block, or when `$ssot-doctor` is reviewing one. The three altitudes are fixed: `apex` (AGENTS.md, each `SKILL.md`, or a consumer's `SSOT/README.md`), `authority` (every other SSOT artifact, no sub-rank), and `inbox` (`## Pending Captures` in consumer STATUS.md, `## Bundle Captures` in `protocol-upgrades.md`). Movement is driven by judgement, not thresholds.

## The two evidence streams

Every move block must cite at least one stream; if both are silent, do not move the rule.

**Stream A — repo and conversation reality.** Signals you read off the work itself:

- A commit just violated or invoked a long-lived rule (`commit:<sha>` + path).
- The same incident class recurs across recent batches in one area (recurring gotcha files, repeated revert pattern).
- An apex rule is no longer cited anywhere in the diff, tests, or transcripts over the freshness window (demote candidate).
- An authority-level rule is being paraphrased or hand-rolled in multiple places (promote candidate).
- A conversation thread names the same constraint by different words across sessions.

**Stream B — user interactive directives, analysed.** Signals you read off the user's prompts, not just literal quotes:

- Explicit lift or kill: "promote this", "never again", "this belongs at the top".
- Repeated user corrections of the same kind across turns — implies a rule the SSOT has not yet codified.
- Business-focus drift: recent prompts cluster in one domain, so that domain's rules rise in salience.
- User-identified complexity centres ("the X area keeps biting us") — signals a promote candidate even without a literal directive.

## The five self-check questions

Answer all five in order before writing a move block. The questions exist to force you out of incremental thinking.

1. **What does Stream A say about this rule right now?** Cite the concrete anchors (`commit:<sha>`, `path:<rel>`, `leaf:<R-...>`) or state that Stream A is silent.
2. **What does Stream B say?** Quote the user directive or describe the directive pattern. If silent, say so.
3. **Which altitude does the combined evidence actually justify — apex, authority, or inbox?** Consider all three. Do not default to "one step up from where it lives".
4. **Should this rule jump or be demoted instead?** Inbox→apex and apex→inbox in one move are both legal. If you are tempted to move one step, explain why the bigger move is wrong.
5. **What is the cost of the move?** Apex carries activation cost on every read; authority dilutes when over-promoted; inbox is cheap but invisible. Name the cost the chosen altitude imposes and why it is worth paying.

If any answer is "I am not sure", the move is not ready. Park a CAP- row instead and let the next batch see more evidence.

## Schemas

Use these literally. The HTML comment form is required so the blocks survive inside markdown tables.

**Rule block** — attached to every apex or authority rule:

```text
<!-- rule:
  id: R-YYYYMMDD-NN
  altitude: apex | authority
  about: agent-method | product
  target_universe: bundle | consumer
  evidence: [commit:<sha>, path:<rel>, leaf:<R-...>]
  promoted_from: [R-...]
-->
```

**Move block** — written every time a rule changes altitude, placed beside the rule at its new location:

```text
<!-- move:
  rule_id: R-...
  from: inbox | authority | apex
  to: inbox | authority | apex
  decided_by: ssot-closeout | ssot-audit
  decided_at: YYYY-MM-DD
  stream_a: ["<short evidence quote with anchor>", ...]
  stream_b: ["<short evidence quote with anchor>", ...]
  reasoning: "<2-3 sentences: why this altitude, why now, why not the other direction>"
  reviewer: ssot-doctor | none
-->
```

At least one of `stream_a` or `stream_b` must be non-empty. `reasoning` must explicitly address the rejected direction — promotion blocks say why not demote, demotion blocks say why not promote.

Keep rule, move, and CAP metadata sparse. These blocks are indexes for future
audit, not the audit narrative itself: use short anchored evidence strings and
2-3 reasoning sentences. If the rationale needs more space, put the longer
explanation in the authoritative owner or review artifact and cite it from the
block.

**CAP- row** — one line in `STATUS.md ## Pending Captures` (consumer) or `protocol-upgrades.md ## Bundle Captures` (bundle):

```text
| id | captured_at | about | altitude_guess | rule | evidence | signal_source | status |
```

- `id`: `CAP-YYYYMMDD-NN`.
- `about`: `agent-method | product`.
- `altitude_guess`: `apex | authority | inbox`.
- `signal_source`: `user-directive | repo-signal | transcript | tier4-rollup`.
- `status`: `open | routed | deferred | deferred-export | expired`.

## When to invoke doctor stop-review

`reviewer: ssot-doctor` is mandatory on any move where `from: apex` or `to: apex`; for moves entirely within `inbox` and `authority`, `reviewer: none` is acceptable.

## Migration of pre-v2.28 rules

Rules that pre-date v2.28 do not need a one-shot rewrite. Altitude is inferred from current location: anything in AGENTS.md or in a `SKILL.md` body sits at apex; anything else under `SSOT/` sits at authority; inbox is empty until the first capture. Wrap rules with the `<!-- rule: -->` block opportunistically as `$ssot-closeout` or `$ssot-audit` touches them — not as a back-fill pass.

## Worked examples

**Promote to apex.** The "commit and push every turn" rule kept being hand-rolled in successive batches because nothing in AGENTS.md named it; the user finally typed "lift this to AGENTS.md".

```text
<!-- move:
  rule_id: R-20260611-01
  from: inbox
  to: apex
  decided_by: ssot-closeout
  decided_at: 2026-06-11
  stream_a: ["commit:3e68389 codifies the rule after repeat misses across recent batches"]
  stream_b: ["user prompt 2026-06-11: 'lift this to AGENTS.md'"]
  reasoning: "Rule binds every batch end and its absence is causing repeat misses. Apex over authority because every skill reads AGENTS.md; not demote because the pattern is recurring, not fading."
  reviewer: ssot-doctor
-->
```

**Demote from apex.** An apex rule about a deprecated lint script has not been cited in 40 commits and the script no longer exists.

```text
<!-- move:
  rule_id: R-20250812-04
  from: apex
  to: inbox
  decided_by: ssot-audit
  decided_at: 2026-06-11
  stream_a: ["path:scripts/ssot-lint.sh deleted in commit:a91f02c; zero apex citations across last 40 commits"]
  reasoning: "Binding has fully drifted; keeping it at apex taxes every read for no benefit. Inbox not authority because re-promotion is unlikely; not deletion yet because the rationale still wants one freshness-window review."
  reviewer: ssot-doctor
-->
```
