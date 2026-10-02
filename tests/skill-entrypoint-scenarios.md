# Skill entrypoint completeness checks

The contribution standard judges whether a skill exposes the decisions needed
for its task. A structural validator can check presence and links, but it
cannot infer that every useful branch was preserved.

On 2026-10-03 the bundle-shape command ran against two isolated copies of
v2.64. One retained the old checker; one used the candidate checker. The same
Doctor entrypoint gained an explicit scope/recovery paragraph and a four-row
routing table to existing references, making its body 142 words.

- Old checker: failed both the 60-word ceiling and the table prohibition.
- Candidate checker: passed the expanded entrypoint and resolving references.
- Candidate checker with the body removed: failed with `SKILL.md body is empty`.

The candidate standard also retains useful non-obvious sequences, forbids
losing knowledge merely to compress, and treats direct skill invocation as a
real entrypoint. These points were reviewed in prose; the shell checks above
prove the removed mechanical restriction, not general model quality.

Installer regression coverage uses a frozen pre-marker companion signature,
not today's style text with its first line stripped. That lets current style
wording evolve while continuing to test safe historical ownership adoption.
