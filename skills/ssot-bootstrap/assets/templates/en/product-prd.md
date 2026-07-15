---
intent_recovery: gap
---
# Product brief

<!-- Writing style: implementation-delegator. Start with a person's situation,
     decision, and visible result; explain labels before surfaces and evidence. -->

<!-- This is the durable product spine, not a compressed copy of an external
     requirements document. Start with plain prose, one concrete scene, and the
     user-visible result. Define local terms when first used. -->

## Why this product exists

<!-- Describe the people and setting, the frustrating job they face today, and
     why the problem is worth solving. Name the primary user and any secondary
     operator whose needs materially shape the product. -->

## The experience available now

<!-- Tell a current end-to-end scene: where someone enters, what they can do,
     what they see while work is in progress, what a successful result looks
     like, and how blocked or failed work is presented. Do not mix target steps
     into this current story. -->

## Promise and scope

<!-- State the few user-visible results the team keeps stable, then explain the
     boundary around each promise in connected prose. A promise is not an
     implementation component. Include deployment or organisational assumptions
     only when they change what the user receives. -->

## Surfaces and ways in

<!-- Describe how people actually reach and control the product. Mention the
     primary pages, navigation, creation modes, controls, settings, diagnostics,
     integrations, external channels, commands, public interfaces, output
     artifacts, notifications, and help/onboarding in the current story.
     Do not maintain a second inventory here. Link important claims to stable
     IDs in the [product surface inventory](./_manifest.md#product-surface-inventory),
     where maturity and evidence are tracked once. -->

## What success and an incomplete result mean

<!-- Explain the observable outcome and quality bar. Also say what the person
     sees after partial completion, cancellation, blocking, or failure, which
     state remains safe, and whether the next action belongs to the person or
     an operator. Put detailed gates in roadmap-and-acceptance.md. -->

## Sustained value and feedback loop

<!-- Explain how repeated real tasks reveal whether the product remains useful,
     not only whether one output completed. Name the current outcome signal and
     counter-metric, where users or operators can give feedback, how that
     feedback reaches the roadmap, what measurement data may be collected and
     its privacy boundary, and who reviews the signal or which event triggers
     review. If the repository has no trustworthy measure or feedback loop,
     state that honest gap and its closure owner. Never invent usage numbers. -->

<!-- Route every applicable Q01-Q21 item from STATUS to the product owner that
     explains its user meaning. Weave the condition into the relevant promise,
     surface, outcome, or boundary; do not create twenty-one mechanical headings. -->

## Deliberate non-goals

<!-- Explain each meaningful exclusion in prose: why it sits outside the
     promise, what people should do instead today, and what evidence would
     justify reconsidering it. Avoid bare labels. -->

## Direction and unresolved questions

<!-- Separate the intended direction from current truth. For every important
     limitation, state current behaviour, user impact, the desired posture,
     and the unique closure owner. Do not repeat roadmap status rows. -->

## Authority hand-off

<!-- Close with a short reading route, not a reference matrix. Add only links
     that answer a question this page intentionally delegates. -->

- [Product model](./product-model.md) owns people, objects, lifecycle, access, language, and durable trade-offs.
- [Capabilities](./capabilities/README.md) and [journeys](./journeys/README.md) own detailed outcomes and experiences.
- [Roadmap and acceptance](./roadmap-and-acceptance.md) owns delivery gates and product-level gaps.
- [Architecture](../02-architecture/README.md) owns the runtime response, enforcement, and implementation gaps.
