# Quality Sweep Workbench — Sentence-First UX

## Purpose

The Quality Sweep exists primarily to help a human quickly find bad NPC dialogue.

The default workflow must answer:

> What sentences can the semantic system produce, what triggered each sentence, and which ones look awkward, robotic, repetitive, or contextually wrong?

The user should **not** need to understand test-engine concepts such as smoke, full, pairwise, batch IDs, reachability states, or coverage matrices to perform this task.

## Primary workflow

The default Quality Sweep page is:

`Generate Sentences → browse all rendered NPC lines → filter/search → inspect trigger/context`.

### Primary controls

Expose only:

- **Generate Sentences**
- **Stop**
- Languages
- Max examples
- Reload Results
- Advanced…

Generation automatically plans broad balanced production-backed coverage and resumes a stopped in-memory run when possible.

Do not expose Run/Resume, Plan, strategy comboboxes or batch controls as primary workflow concepts.

## Main sentence table

One row per rendered NPC output.

Required visible columns:

- **NPC Sentence**
- **Trigger**
- **Context**
- **Lang**
- **Quality / Problem**
- **Source**

### Trigger

Show a human-readable cause such as:

- `Player: "how are you?"`
- `Player: "hello"`
- `Menu: recruit`
- `Menu: ask_name`

Do not require the user to interpret internal surface IDs.

### Context

Show a compact useful summary, for example:

`bond=sister · approval=75 · style=guarded · traits=reserved · need=thirst:MINOR`

The full detailed context remains available in the right-hand inspector.

### Quality / Problem

Show automatic flags when present, such as:

- unsupported family reference;
- one-word response;
- perspective suspect;
- duplicate rendered text;
- fallback saturation;
- variant collapse.

Clean rows show a neutral dash rather than technical status noise.

## Direct filters

Default filters should support the actual review task:

- free-text search;
- only suspicious / flagged lines;
- only duplicates / repeated lines;
- language.

Do not make pool IDs, batch IDs, reachability states or strategy names part of the normal filtering experience.

## Evidence detail panel

Selecting a sentence should immediately explain **why it happened**.

Show:

- exact rendered sentence;
- player/menu trigger;
- relationship/bond;
- approval/respect/familiarity/identity trust;
- persona/style/traits;
- needs/health/activity/behavior;
- semantic intent/subject/speech act;
- template/variant;
- realization/phrase/translation;
- quality flags;
- canonical source owner;
- changed parameter vector.

Primary actions:

- Open Full Inspector
- Copy Evidence

## Advanced developer tooling

Advanced… may expose:

- internal coverage strategy;
- sweep ID;
- batch size;
- response-pool/variant reachability scan;
- review-bundle export;
- technical plan digest/status.

These controls must remain secondary and hidden by default.

The default page must never again look like a batch/coverage dashboard.

## Generation behavior

The sentence review planner should:

1. discover current production interaction surfaces;
2. exclude expected fallback probes from normal review unless explicitly requested;
3. seed every selected surface with baseline cases;
4. distribute persona/relationship/boundary/pairwise contexts across all surfaces fairly;
5. avoid consuming the entire case cap on early surfaces;
6. progressively incorporate variant-frontier targets as reachability improves.

“Max examples” is an execution bound, not a promise of mathematical exhaustiveness.

## Live results

Evidence rows are written incrementally.

After each completed engine batch, the GUI should reload and display available sentences immediately.

A completed manifest with an empty sentence table is a failure.

The analyzer must tolerate actual production types such as categorical `identityTrust="unknown"`; a quality heuristic must never crash the results display.

## Full Inspector behavior

Open Full Inspector must recreate the selected sentence, not a generic replacement turn.

Replay must use:

- the row's original `identity.input`;
- language;
- changed parameter vector;
- compatible production inventory/fingerprint where available.

A wellbeing row must not reopen as a greeting.

## Threading

Long sentence generation and advanced reachability analysis must not block Tk.

Use background workers and marshal UI updates through Tk's event loop.

## Acceptance

The GUI is accepted only when:

1. a real worker run produces visible sentence rows;
2. each row shows its human-readable trigger;
3. each row shows compact context;
4. filtering flagged/duplicate lines works;
5. selecting a row populates detailed context;
6. Full Inspector recreates the same semantic route/input;
7. Stop preserves completed sentence evidence;
8. generation remains responsive;
9. broad review coverage is balanced across selected triggers;
10. Advanced diagnostics are not required for ordinary dialogue review.
