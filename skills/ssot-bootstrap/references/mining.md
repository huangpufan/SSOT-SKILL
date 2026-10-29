# Mining protected rules

This file says how to find the architecture and product rules a repository protects, and how to admit them to the invariants register. `ssot-bootstrap` uses it during setup, and `ssot-doctor` uses it for an area or history scope. What a rule must contain to be admitted is in [`memory-model.md` §5](../../ssot-preflight/references/memory-model.md#5-invariants).

## Why this is its own step

A registered rule gets kept or asked about almost every time; an unregistered one gets crossed about as often as it is kept. A large repository protects hundreds of behaviors, most written down only in its tests and history. So the register is the main product of setup, built in rounds by several agents.

Never let one agent in one pass decide what is protected. Different agents with fresh contexts mine, challenge, and check. If helpers cannot be started, stop and tell the user rather than doing it alone.

## 1. Declare the scope before mining

List the main areas. For this round, choose the areas to mine, the sources in each (test directories, history range), and a budget in time or commits, and write this plan to a working file. Setup mines every main area. A small or medium repository is mined whole in this round, with every area given its first pass before any area gets a second; in a large one, areas not mined this round go to a later `$ssot-doctor` area scope.

Then list each area's sources item by item in a working file: every test file with its test names, every fix or revert commit that touches the area, the bug-fix entries of its changelog, and the guards whose comments say why they exist. It makes the round complete rather than a sample: split it among the miners so every item has one.

Keep the working files in `.ssot-work/` at the repository root, and first put a `.gitignore` containing `*` in it, so nothing there is ever committed. Not outside the repository: sandboxed agents can often write only inside it, and every helper must be able to read these files.

## 2. Mine each area from more than one source

Start at least two miners per area, each with a fresh context and a different source:

- **Tests and contracts.** Read the area's test names first; they often state a protected outcome almost word for word. Then read the assertions, fixtures, and code behind the ones that assert an outcome for its own sake. Start from what users, clients, and integrations rely on staying the same: public promises, APIs, CLI behavior, saved data, import and export formats, and upgrades. Cover failure, permission, repeated-request, and recovery paths, not only the normal one. Test names are leads, not rules.
- **History.** Read the area's commit subjects oldest first, then the diffs of fix and revert commits, starting with the places fixed most often. A fix or revert that restored a behavior is strong evidence that people protect it. When a later commit deliberately changed what an earlier one established, the later one wins for the part it changed; the rest of the earlier rule still stands. A place fixed again and again deserves a closer look, but the count alone does not show a common cause.
- **Guards and comments**, where tests are sparse: checks whose comment or history says why they exist, and shims or migrations that exist to keep old behavior working.

Each miner works through every item on its part of the checklist and marks it: the protected outcome it supports, as a new or existing proposal, or why it supports none (an incidental detail, a refactor, a duplicate). A part is finished only when every item is marked. Keep each proposal short at first: outcome, conditions, evidence. There is no target count; a test-rich area may hold dozens of rules.

If a helper fails, read its error before acting. After a rate-limit error, wait and start it again, fewer at a time; do not replace it with a narrower task, which silently shrinks the round.

## 3. Challenge

Give each area's proposals to a fresh helper that did not mine them. For each proposal it looks for legitimate exceptions, other paths that bypass the rule, and later decisions that replaced it, citing evidence for every correction, and it tells a supported exception apart from a current violation. It proposes one request that would cross the rule and one nearby change that would not. It also checks a sample of the items the miners marked as supporting no outcome, and reports protected outcomes they missed.

## 4. Revise and admit

Send the challenger's findings back to the miners for one more round, then decide each proposal yourself by memory-model §5: admit, narrow, or reject, and record the reason in the working file. Every outcome the challenge did not refute ends up in `SSOT/`: as a register row when it meets §5, or else as a plain statement of what the code does, with its evidence, in its area's owner. When you narrow a proposal, keep each supported part, in its own row if needed. Defer only what needs evidence this round cannot get, such as running the code, and list it in the report. Ask another fresh helper only where the evidence is disputed. Do not weaken a protection only because the current code violates it; report the violation instead. Write each admitted rule as a register row and explain it in the owner of its area. State it as the behavior a user or caller sees, as far as the code applies it: the inputs or settings, the outcome, and the exceptions, in the row itself. A rule that only restates a test's fixture protects nothing beyond it. Where the code treats untested cases differently, name the cases the rule covers. Give separate outcomes separate rows, so each keeps its own conditions.

Then give the rows you wrote, with their explanations, to a fresh helper that did not write them. It checks each against the code at HEAD and gives one verdict: protected as written; too broad (a condition or exception is missing); not protected on purpose; wrong; or not a rule. Fix every row it flags, by narrowing, moving it to its owner as plain description, or dropping it, and have the fixed rows checked again.

## 5. Check the result with a fresh reader

Give a fresh helper that reads only `SSOT/` a sample of the challenger's requests: some that cross an admitted rule, some nearby that do not, and some where the user explicitly accepts giving up the protection. It must keep or ask about the first, just do the second, and do the third without asking again. Fix what fails.

Once every area has had its first pass, give another fresh helper a random sample of checklist items from each area; for each, it says whether the outcome the item protects is in `SSOT/`. Where it finds outcomes missing, mine that part of the checklist again, once; then report what the sample found rather than sampling again.

## 6. Report

Report, per area: the sources read, the number of proposals and how each was decided (admitted, narrowed, rejected, deferred), the admitted rules by kind, what the challenger found missing, and which areas and history remain for a later Doctor scope. These numbers describe the round; they are not quotas, and a passing checker does not replace them. Leave `.ssot-work/` in place so a later round can continue; losing it means repeating work, not skipping it.
