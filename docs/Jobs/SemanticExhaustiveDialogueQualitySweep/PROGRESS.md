# Semantic Exhaustive Dialogue Quality Sweep — current progress

**Parent goal status: IN PROGRESS.**

The prior `COMPLETE` claim at `628500dc` was rejected by independent runtime/UI audit. The implementation contains useful foundations, but completion evidence still overstates reachability and production defect coverage.

## Current accepted foundation

The Quality Sweep is now intentionally **sentence-first**.

The normal user workflow is:

`Generate Sentences → scan rendered NPC lines → search/filter suspicious lines → click a line to see its trigger/context → optionally open the full inspector`.

Testing-engine concepts such as smoke/full/pairwise strategy names, batch IDs, reachability internals and coverage diagnostics are no longer the primary interface. They remain Advanced developer tooling only.

### Verified fixes in the current remediation

- The dedicated top-level Quality Sweep workspace remains.
- The main screen now shows one generated-sentence table rather than five coverage/cluster/batch tabs.
- Primary action is **Generate Sentences**; resume/batching is handled internally.
- Sentence rows show:
  - rendered NPC sentence;
  - player/menu trigger;
  - compact persona/relationship/state context;
  - language;
  - quality/problem flags;
  - canonical source owner when available.
- Clicking a row shows its detailed trigger/context/semantic path.
- **Only suspicious / flagged lines** and duplicate/repetition filters are available directly.
- Engine/testing controls are hidden under **Advanced…**.
- Real evidence reload no longer automatically runs the expensive reachability scan on the Tk thread.
- The runtime bug that caused completed sweeps to show **0 rows** was reproduced and fixed:
  - production `identityTrust` may be categorical, e.g. `"unknown"`;
  - the analyzer incorrectly forced it through `float(...)`;
  - this raised `ValueError` inside the Tk callback after evidence had already been written.
- A real GUI run now completes with evidence visible in the sentence table.
- Full Inspector replay now uses the row's actual `identity.input` and scenario parameter vector rather than defaulting to `"hello"`.
- Production surface discovery is now used by the service when no explicit surface scope is supplied.
- Full/review planning is balanced round-robin across all selected surfaces instead of exhausting the case cap on the first one or two surfaces.

## Runtime evidence

### Balanced review plan

A 128-case EN review plan across the current production surface inventory distributed parameterized cases across all 9 non-fallback triggers:

- companion orders: 13 cases;
- what's-up landing: 15;
- ask-name: 16;
- goodbye: 16;
- recruit: 16;
- hello: 13;
- wellbeing: 13;
- typed what's-up: 13;
- typed identity: 13.

Every listed surface received parameterized context coverage.

### Real GUI sentence-table proof

A hermetic real-worker GUI run with 4 examples completed with:

- running state: false;
- evidence rows: 4;
- visible tree rows: 4.

The table displayed real outputs including:

- `I'm Mara Vale. We already know each other.`
- `That is a serious promise. We have not built enough trust for me to make it.`
- `You too.`
- `Not much. I'm just trying to keep things together.`

Each row also showed its triggering player/menu text and relationship/persona/state summary.

### Full Inspector replay proof

A real `how are you?` evidence row originally resolved to:

- intent: QUESTION;
- subject: WELLBEING;
- text: `I'm okay. How about you?`.

After the replay fix, Open Full Inspector reproduces the same QUESTION/WELLBEING route and the same rendered text instead of incorrectly replaying a greeting.

## Validation

Current remediation validation:

- sweep/service tests excluding GUI: **36/36 PASS**;
- sentence-first GUI tests under Xvfb/Tk: **5/5 PASS**;
- production Lua semantic regression: **144/144 PASS**;
- `git diff --check`: clean.

## Remaining mandatory gaps

Do not mark the parent goal complete yet.

Still unresolved from the independent audit:

1. Reachability declares neutral/friendly/rival/family frontier profiles but currently evaluates only the first two profiles.
2. Reachability is still a bounded small-profile probe rather than the intended context-guided frontier search.
3. Several P7 defect demonstrations remain synthetic:
   - unsupported family;
   - wrong perspective;
   - canonical defect clustering.
4. The P7 `ELIGIBLE_NOT_SELECTED` demonstration currently proves an ineligible variant instead.
5. Anti-repeat acceptance still needs to prove actual selection/phrase change or production penalty, not merely field presence.
6. Canonical source navigation is still metadata-only; direct Studio/source navigation is not yet implemented.
7. CLI filter parity remains incomplete.
8. Sentence generation must continue moving toward registered-variant coverage rather than merely increasing case count.

## Immediate Next Chunk

Keep the simplified sentence-first UI stable.

Next work should improve **what sentences get generated**, not add more visible controls:

1. connect the sentence-review planner to the variant/reachability frontier;
2. target unobserved/eligible response variants using production explain evidence;
3. keep coverage balanced across triggers;
4. surface newly reached lines directly in the same sentence table;
5. replace synthetic P7 family/perspective/cluster evidence with real production-Lua/replay cases;
6. finish true `ELIGIBLE_NOT_SELECTED` and anti-repeat acceptance.

Do not re-expand the default GUI into coverage dashboards. Advanced diagnostics may remain hidden behind Advanced… for developer use.

## Stop rule

Completion means the sentence browser can expose the meaningful production dialogue space with truthful context/provenance and the remaining HARNESS_ACCEPTANCE gates pass. A green manifest, a large case count, or a visually complete GUI is not sufficient.
