# Audit — Semantic Exhaustive Dialogue Quality Sweep

## Post-implementation acceptance audit

Audit baseline: ProjectHoomans `5af171b079b9652fd1b8c2ef64c18b5bfd07ccab`.

The implementation is substantial and preserves the old semantic system, but the prior developer-complete claim is not supported by real acceptance evidence.

## Verified healthy foundation

The audit reran:

- new sweep suite: **32/32 PASS**;
- Lua semantic regression: **144/144 PASS**;
- focused Semantic Test Subsystem/parity set: **27/27 PASS**;
- Response Observatory set: **30/30 PASS**;
- Quality Sweep Tk/Xvfb test file: **4/4 PASS**.

This establishes that the agent added real code without obviously regressing existing semantics.

## Verified acceptance defects

### A. Stale hard-coded interaction surfaces

Current planner default root-choice names do not match the current live root projection.

A real conversation projection showed choices such as `ask_name`, `recruit`, `goodbye`, `whats_up`, and `companion.orders:open`.

A real smoke sweep nevertheless counted stale `wellbeing`, `orders`, `companion_status`, and `trade` cases as completed after they fell into clarification.

**Impact:** the harness can report green coverage without exercising the target semantic feature.

### B. Full plan is badly distributed

A 256-case full plan contained:

- 240 parameterized root-choice cases;
- 0 parameterized utterance cases;
- 221 cases on `scenario.rootChoice:wellbeing`.

Because that surface is stale in the observed root menu, this makes the main broad-combination strategy misleading.

### C. Evidence projection reads outdated paths

Real Conversation Inspector data exposes relationship/personality/traits/situation under `personaChoices.actorConversationContext` and related social-context structures.

The compact evidence row for a real `how are you?` turn returned empty persona/state and missing relationship values.

**Impact:** exactly the parameters needed to explain bad dialogue are absent from the output the LLM/user is supposed to review.

### D. Trait options are malformed

Production trait options are structured objects with canonical IDs. Current extraction stringifies the object.

**Impact:** trait sweep inputs are not trustworthy.

### E. Reachability covers only first 64 pools

Production reported:

- `total = 234`;
- `returned = 64`;
- `hasMore = true`.

Current reachability code does not paginate.

**Impact:** the reachability report covers only a minority of production pools while appearing comprehensive.

### F. Reachability does not perform the required frontier search

Non-selected variants are primarily checked against one baseline selection explanation.

**Impact:** `ELIGIBLE_NOT_SELECTED` / `TESTED_INELIGIBLE` classifications are not a systematic search over approved context buckets.

### G. Cancel/resume is broken

Direct reproduction:

- cancel before execution → manifest `CANCELLED`, batch `CANCELLED`;
- run again → still `CANCELLED`, 0 completed.

**Impact:** the restartable batch requirement is not met.

### H. Run-level repetition analysis is absent

Multiple real smoke cases rendered the same clarification fallback. Cluster report returned 0 flagged rows / 0 clusters.

**Impact:** one of the user's primary complaints—robotic/repetitive dialogue—can pass cleanly.

### I. Lazy inspector handle is non-functional

Evidence rows contain a marker but no service/UI resolver.

**Impact:** the user/LLM cannot expand a compact row into the promised full explanation.

### J. P7 demonstrations overclaim real evidence

Key family, perspective and clustering checks use synthetic row dictionaries. Other assertions check only existence rather than the claimed contrast/change.

**Impact:** the prior 10-scenario acceptance statement is not valid.

### K. UI is only a partial workbench

The current Simulation sub-tab exists and renders, but lacks the full promised scope/inventory browsing, rich filters, full-inspector/source navigation, and safe responsive long-run execution.

The controller runs sweeps synchronously from the Tk callback.

**Impact:** large runs can block the GUI and make cancel unreliable.

## User-directed architecture expansion

The user now explicitly wants a dedicated GUI for checking the broad sweep.

Approved direction:

- add a first-class **Quality Sweep** workspace inside the existing Semantic Harness;
- use the same shared services as CLI;
- browse surfaces, dimensions, pools/variants, coverage gaps, evidence and clusters;
- support plan/run/cancel/resume/filter/inspect/source/replay/export;
- keep Simulation for one-scenario/live testing;
- keep Studio for authoring;
- do not create a second semantic engine or runner.

See `GUI_WORKBENCH.md`.

## Correct next step

Fix evidence/surface truth first, then build the dedicated GUI on those corrected services.

The recovery sequence is:

`evidence join + option normalization → live surface discovery + reached-surface verification → resume repair → full registry/reachability → run-level quality → dedicated GUI → real P7 acceptance`.
