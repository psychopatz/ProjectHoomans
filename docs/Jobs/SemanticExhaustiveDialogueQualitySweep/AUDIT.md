# Audit — Semantic Exhaustive Dialogue Quality Sweep

## Current audit baseline

Current accepted remediation baseline before this documentation update:

- ProjectHoomans HEAD: `dd9a6dc9a03103becbac2835b2fe85908e8429ca`;
- local `main` ahead of `origin/main`;
- worktree clean before this docs update;
- no native Project Zomboid, source save, or Workshop publication used.

## What the previous implementation got wrong

The earlier Quality Sweep exposed testing internals—strategy names, batches, coverage tabs and reachability tables—as the primary UI even though the user primarily wanted to review generated NPC dialogue.

The screenshot/runtime audit found a more serious bug:

- the sweep had completed and written evidence rows;
- the GUI showed `0 of 0`;
- loading those rows crashed because production `identityTrust` may be categorical (`"unknown"`) while the quality analyzer forced it through `float(...)`.

This proved that a green manifest was not sufficient acceptance.

## Verified remediation

### Sentence-first GUI

The normal Quality Sweep workflow is now:

`Generate Sentences → browse generated lines → filter suspicious/repeated lines → inspect one line`.

Default visible controls are limited to:

- Generate Sentences;
- Stop;
- Languages;
- Max examples;
- Reload Results;
- Advanced….

The primary table shows:

- NPC Sentence;
- Trigger;
- Context;
- Lang;
- Quality / Problem;
- Source.

### Real GUI display

A hermetic real-worker GUI run with 4 cases completed with:

- 4 evidence rows;
- 4 visible sentence-table rows.

Example real outputs included:

- `I'm Mara Vale. We already know each other.`
- `That is a serious promise. We have not built enough trust for me to make it.`
- `You too.`
- `Not much. I'm just trying to keep things together.`

The table also displayed the human-readable trigger and compact relationship/persona/state context.

### Evidence analyzer robustness

Categorical `identityTrust` is now tolerated instead of crashing sentence rendering.

A quality heuristic must never be allowed to erase otherwise valid evidence from the GUI.

### Balanced planning

The prior full planner heavily starved later surfaces.

A 128-case EN review plan after remediation distributed parameterized cases across all 9 current non-fallback surfaces, roughly 13–16 cases each.

### Production discovery

When no explicit surface scope is supplied, the service now uses current production surface discovery rather than only historical hard-coded defaults.

### Exact Full Inspector replay

The previous GUI reconstructed missing input as `"hello"`, causing a wellbeing row to reopen as a greeting.

The replay path now uses the evidence row's original `identity.input` and scenario parameter vector.

A real `how are you?` row replays as:

- intent: QUESTION;
- subject: WELLBEING;
- output: `I'm okay. How about you?`.

### Validation

After the remediation:

- sweep/service tests: **36/36 PASS**;
- Quality Sweep GUI tests under Xvfb/Tk: **5/5 PASS**;
- production Lua semantic regression: **144/144 PASS**;
- `git diff --check`: clean.

## Remaining actual product gap

The main remaining problem is no longer the basic GUI.

It is **sentence-space coverage**.

The harness needs to find more of the registered production dialogue variants rather than simply generate more combinations of already-observed responses.

The existing reachability code still has important gaps:

- declared context profiles are not all exercised;
- frontier exploration is too shallow/fixed;
- several P7 family/perspective/clustering demonstrations remain synthetic;
- the current “eligible-but-dominated” proof is actually an ineligible candidate;
- anti-repeat acceptance is not yet strong enough.

## Correct next phase

The next phase is **variant-guided sentence expansion**:

1. enumerate the full production response registry;
2. record which variants have appeared in real sentence rows;
3. target unobserved variants using production explain evidence and relevant context buckets;
4. execute real Lua;
5. feed newly reached sentences back into the same simple sentence table;
6. use those real outputs to close family/perspective/cluster/anti-repeat/eligible-dominated acceptance.

Do not re-expand the default GUI into a coverage dashboard.
