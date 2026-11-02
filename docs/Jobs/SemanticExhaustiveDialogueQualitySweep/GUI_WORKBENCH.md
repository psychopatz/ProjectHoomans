# Dedicated Quality Sweep Workbench

## Purpose

Provide a first-class GUI inside the existing Semantic Harness for broad semantic dialogue coverage and quality review.

This is **not** a second harness. It is a human-facing client of the same `DialogueQualitySweepService` / sweep planner / executor / report services used by CLI.

## Workspace ownership

### Simulation

Use for:

- one current scenario;
- interactive conversation;
- live actor/context editing;
- immediate Conversation Inspector work.

### Quality Sweep

Use for:

- broad/batched semantic coverage;
- surface/dimension/variant inventory;
- run progress;
- dialogue-quality triage;
- reachability/coverage gaps;
- targeted replay.

### Studio

Use for:

- canonical content/source authoring;
- reviewed text changes;
- source lineage editing workflows.

The existing Simulation Quality Sweep sub-tab should be migrated into this workbench or reduced to a compact **Open Quality Sweep** launcher/status summary. Do not maintain two separate full sweep interfaces.

## Proposed layout

A dedicated top-level harness tab/page named **Quality Sweep**.

### 1. Sweep configuration header

Controls:

- Sweep ID;
- strategy: Smoke / Boundary / Pairwise / Persona / Reachability / Full;
- languages;
- max cases;
- batch size;
- scope preset;
- Plan;
- Run;
- Cancel;
- Resume;
- Refresh.

Show before running:

- discovered surface count;
- selected surface count;
- selected dimension count;
- response pool / variant totals;
- estimated cases;
- estimated batches;
- truncation/cap warnings.

### 2. Coverage Explorer

Tabs or panes:

#### Surfaces

Columns:

- surface ID;
- source/provider;
- type;
- eligible/executable;
- planned count;
- reached count;
- invalid/mismatch count;
- last observed semantic route.

Allow selecting surfaces to include/exclude.

#### Dimensions

Columns:

- dimension ID;
- type;
- source;
- bucket values;
- prerequisite;
- selected for coverage;
- covered values/pairs.

Trait values should display friendly labels while retaining canonical IDs.

#### Response Pools / Variants

Hierarchical or paged browser:

- pool ID;
- variant ID;
- registered conditions summary;
- reachability state;
- selected count;
- eligible-not-selected count;
- tested contexts;
- source owner.

Must reflect the **full paginated production registry**.

#### Batches

Show:

- batch ID;
- status;
- valid;
- invalid-surface;
- failed;
- cancelled/incomplete;
- duration.

### 3. Results / Evidence table

One row per rendered NPC output.

Recommended columns:

- severity;
- flag/review state;
- rendered text;
- planned surface;
- reached semantic route;
- language;
- response template;
- semantic variant;
- realization family/variant;
- phrase ID;
- bond/relationship state;
- persona/style;
- batch/case ID;
- source owner.

Filters:

- free text;
- severity;
- flag;
- language;
- planned/reached surface;
- response pool/template;
- variant;
- phrase;
- source;
- strategy;
- batch;
- relationship/bond;
- reachability state;
- only invalid surfaces;
- only repeated/duplicate text.

### 4. Cluster view

Show canonical-cause clusters with:

- primary flag;
- severity/confidence;
- count;
- source;
- phrase/variant;
- affected context ranges;
- representative outputs.

Actions:

- inspect examples;
- select affected cases;
- replay cluster;
- export review bundle;
- open canonical source when verified.

### 5. Evidence detail inspector

For the selected evidence row, show bounded structured sections:

- **Trigger** — changed parameters;
- **Persona** — dimensions/style/traits;
- **Relationship** — approval/respect/familiarity/trust/bond;
- **Situation** — needs/health/activity/behavior;
- **Semantic Path** — intent/speech act/subject/flow/template/variant;
- **Realization** — family/variant/phrase/translation/fallback;
- **Selection** — selected candidate and rejection summary;
- **Authority/Effects**;
- **Quality** — flags and reasons;
- **Source** — canonical owner/fingerprint.

Buttons:

- Open Full Conversation Inspector;
- Replay Case;
- Open/Locate Source;
- Copy Compact Evidence;
- Export Selected Evidence.

## Full Inspector behavior

The Open Full Conversation Inspector action must resolve the selected compact row's trace handle using the shared service.

It should either:

1. load a compatible persisted bounded trace if available; or
2. deterministically replay the exact case/turn under matching fingerprints.

If fingerprints are stale, show that explicitly rather than silently inspecting a different revision.

## Source navigation

When canonical source lineage is verified, expose:

- source owner;
- path/content identity;
- optional line/location where supported.

A source navigation action should use existing Studio/source-lineage mechanisms rather than parsing generated Lua independently.

UNKNOWN remains an honest valid state.

## Responsive execution

The GUI must remain usable during a long run.

Required pattern:

- sweep execution on background worker/thread/task;
- worker emits progress events into a thread-safe queue;
- Tk polls the queue with `after()`;
- only Tk thread mutates widgets;
- Cancel sets a checked cancellation token;
- completed cases are persisted incrementally;
- Resume reconstructs from manifest.

Do not call the complete sweep synchronously from a button callback.

## Status and progress

Always show:

- planned cases;
- completed-valid;
- invalid-surface;
- failed;
- cancelled/incomplete;
- flagged rows;
- clusters;
- elapsed time;
- current batch/case where bounded.

A manifest saying COMPLETED must not imply all cases were semantically valid.

## Exports

Support bounded:

- evidence JSONL;
- filtered evidence JSON/JSONL;
- cluster report;
- reachability report;
- LLM review bundle;
- replay case list.

No giant full-inspector dump by default.

## GUI acceptance

Tests must prove:

- workspace exists as first-class harness page;
- production-backed inventory populates;
- plan estimate renders;
- long-running execution does not block Tk event processing;
- Cancel works while running;
- Resume finishes cancelled work;
- filters operate on real report data;
- selecting a row populates trigger/persona/relationship/semantic/source detail;
- Open Full Inspector resolves a real case;
- cluster replay creates/runs only affected cases;
- source action handles verified and UNKNOWN source states safely;
- Xvfb/Tk tests are hermetic and do not touch user save-selection state.
