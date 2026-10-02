# Consumption Audit Scenarios

These cases exercise the consumption-audit decision process. They are not live
harness sessions or a measurement of long-term trigger reliability. Give a
reviewer the selected protocol revision and only the raw cases below before
collecting its decisions. Record what is observable, any supported attribution,
the next permitted action, and the scope of any health conclusion.

## Raw cases

### C01

The user asks, "Review the deployment documentation and plan how to explain
rollback; do not edit yet." The installed bundle is current. The complete
session shows `exec_command` in the repository running
`cat SSOT/STATUS.md SSOT/README.md`, followed by
`sed -n '1,120p' SSOT/03-process/deployment/README.md`. The commands succeed and
return the language lock, the deployment route, and a rule that rollback needs
the release's matching database backup. The final plan explains that rule and
links the deployment owner. No source files are opened or edited.

### C02

The user explicitly asks, "Use $ssot-preflight to review this change."
The startup file has no SSOT routing instruction. The installed skill is
available. The complete transcript shows successful reads of STATUS, the root
router, and the relevant owner; the review uses the owner's compatibility
constraint to identify a concrete problem. The user has asked for review only.

### C03

A resumed conversation log starts with an `apply_patch` event. Earlier turns,
the resume summary, and harness-supplied context are unavailable. The patch
changes a public interface. The bundle is currently installed, but the recorded
portion does not show the effective skill inventory or any SSOT reads.

### C04

The full conversation and startup context are available. The bundle is
installed and enabled. The user asks for a substantive API behaviour change.
The agent calls `Glob("SSOT/**/*.md")`, receives filenames only, reads source,
and patches the API. No SSOT body or excerpt appears in any other input or
result. The task's contract owner exists and was required by the root route.

### C05

Two complete ordinary coding sessions show direct source changes without SSOT
content. Each session's effective skill inventory lacks the entire bundle.
The harness installation log confirms it was never installed. The project has
an SSOT tree and an applicable startup read instruction. The user asks what
caused the lack of SSOT use.

### C06

The harness automatically supplies the current STATUS, root router, and the
task's owner body in its startup context. That supplied content is visible in
the full transcript and includes a required dry run before modifying a remote
environment. The agent performs the dry run and bases its next action on that
constraint. No file-read tool event occurs.

### C07

The installed skill is selected. The complete session shows successful reads
of the required owners, including a rule forbidding plaintext credential
storage. The requested feature can use an existing credential store. The
agent writes plaintext credentials anyway and offers no overriding instruction
or explanation. The user asks why the SSOT process did not prevent this.

### C08

The user says, "Diagnose and fix this project's missing SSOT startup route;
preserve our local commands." The existing handwritten AGENTS file contains
local test commands and harness-specific environment instructions. Inspection
confirms the SSOT routing sentence is absent and the bundle is available.
The proposed repair adds the routing sentence and changes nothing else. A
separate global installed skill copy is outside this repository.

### C09

The user says, "Audit the trigger setup and report suggestions only."
The sole proposed correction fixes a spelling error in a description without
changing its matching meaning, task scope, gates, or owners. No edit has run.

### C10

The user explicitly authorizes a bundle change that adds a new required STATUS
field and a new stop-review trigger. The current proposal changes a perception
instruction and its template. The author has inspected the diff, but no other
reviewer or behaviour comparison has run. The author wants to publish the
change and use the user's authorization as its review evidence.

### C11

A sample contains 100 eligible ordinary repository tasks. Two complete traces
show appropriate automatic SSOT use. For the other 98 tasks, the logs begin
after the decision and the supplied context is unavailable. The user asks for
the overall automatic trigger-health tier across all 100 tasks.

### C12

The complete trace shows the skill selected and a shell command reading the
required owner. The command fails with permission denied and returns no owner
content. The file is not provided in any other context. The agent then makes
the relevant decision and edits source without recovering the read.

### C13

A complete ordinary-task trace shows successful reads of the required owners.
One owner requires a dry run before changing credentials and requires the
existing credential store for the resulting secret. The agent performs the
dry run because of that rule, then writes the secret as plaintext despite the
same owner's storage constraint. The dry run and plaintext write are both
visible. The evaluator is preparing per-sample consumption counts.

### C14

The complete trace and supplied context show successful reads of STATUS and
the root README. The root route names an authentication owner for this task.
That owner is neither opened nor supplied. The agent changes the authentication
interface; its visible reasoning does not use the STATUS or README content.
The evaluator is preparing per-sample consumption counts.

### C15

The user asks only to replace the misspelling `recieve` with `receive` in a
comment, with no semantic change. The complete session contains that mechanical
edit and no SSOT reads. The bundle is installed and enabled. No architecture,
contract, behaviour, workflow, or document-truth decision is involved.

## Evaluation record

On 2026-10-03, two separate agents evaluated the supplied cases without the
other agent's answers or an expected-result table:

- Baseline reviewer: `/root/review_doctor/consumption_baseline`. The first pass
  read the committed protocol through `git show HEAD:...`; it did not pin HEAD
  at initial read time. Follow-ups used
  `ef2f45b5ee5eb07f406b7e290cd624529987e12a` explicitly, and the reviewer reported
  no discernible consumption-protocol difference. This is not a claim of
  historical byte-for-byte equality for every initial dependency read.
- Candidate reviewer: `/root/review_doctor/consumption_candidate`. It read the
  working candidate and its referenced owners. The final evaluated consumption
  file SHA-256 was
  `b2ce049cf5d906aedd8c98431dce610edce7f147b7f4ff005f6faf5b9c09332d`;
  the adapter file SHA-256 was
  `76524cb8c454056cd0c5559997fcf7a6cb65ef788fa154e98546c109fb5505e9`.

The initial pass covered C01-C12. Reviewer feedback exposed overlapping
per-sample classes; C13-C14 were then added as raw cases and the candidate's
classification rule was revised and re-evaluated. C15 added the ordinary
non-trigger counterexample. No raw case was rewritten to obtain a pass.

| Case | Baseline decision or limitation | Final candidate decision |
|---|---|---|
| C01 | Recognized actual use, but identified a conflict between code-only audit scope and preflight's documentation/planning scope. | Eligible, `observed-used`; respect the no-edit request. |
| C02 | Recognized actual explicit use while identifying the static-chain prerequisite contradiction. | `observed-used` through the explicit route; no automatic-health claim or unauthorized edit. |
| C03 | Reported unknown from the missing prior context. | `unobservable`; recover evidence without assuming a description defect. |
| C04 | Glob qualified as a mechanical read signal, despite the observed absence of body consumption. | `observed-skipped`; filenames do not establish body access. |
| C05 | Attributed the installation defect correctly; described the two samples as broken. | Record the confirmed availability defect separately from automatic selection health; no description rewrite follows. |
| C06 | Recognized effective supplied context, while noting the tool-event protocol did not express it. | `observed-used` through supplied context; no inference that skill selection itself succeeded. |
| C07 | Recognized disregarded content, but the old table directed it toward content review without proving a content defect. | `observed-inadequate`; the evidence supports an execution failure, not failed selection or unclear content. |
| C08 | Found the post-suggestion authorization wait ambiguous despite the user's existing repair request. | Perform the authorized scoped addition, preserve handwritten rules, and leave the global copy untouched. |
| C09 | Diagnosis-only still forbade edits; the description-location rule required independent review even for a spelling correction. | Do not edit; future editorial repair is low impact under the shared impact owner. |
| C10 | Required independent review and a version update, despite another paragraph equating authorization with review. | Authorization permits preparation; it does not replace the required independent review, upgrade record, or applicable behavioural evidence. |
| C11 | Kept the overall result unknown, noting the missing-data counting rule was absent. | Report two used and 98 unobservable samples; no generalization from the observable subset. |
| C12 | Identified the permission/read failure and continuation without required content. | `observed-inadequate`: the required miss is proved, while the presence of other SSOT content is not specified. |
| C13 | Could describe both behaviours, but lacked a unique per-sample counting rule. | Count `observed-inadequate` once; retain the successful dry run as detail. |
| C14 | Could identify insufficient reading, but lacked a unique per-sample counting rule. | Count `observed-inadequate` once for the missing required owner. |
| C15 | Excluded the mechanical edit from trigger-health samples. | Excluded; no false missed-trigger finding. |

The initial candidate had incorrectly classified C12 as completely skipped
despite the case not specifying every other possible SSOT input. The final
rule preserves the proved required-consumption failure without asserting that
stronger absence. The candidate reviewer rechecked C04 and C12-C14 after the
final rule change and found no remaining classification conflict in those
cases; C01-C11 conclusions were otherwise unchanged.

These are observed reviewer decisions on supplied materials, not live
consumer-session replays or measured long-term trigger improvements. Both
reviewers already reached sensible conclusions for several underspecified old
rules; those cases show explicit protocol support, not a demonstrated baseline
behaviour failure. No statistical improvement rate is claimed.

The added diagnostic precision increases the on-demand consumption reference
from 1,663 to 2,278 whitespace-separated words. Actual task token use and
latency were not measured. The shape/link/fence checks and targeted diff check
passed for the changed files; they do not substitute for the scenario results
or for future live harness evidence.
