# Agent Runbook — Pragmatic Dialogue Beat Director

Use this runbook only while implementing this job.

## Read order

Read root `AGENTS.md`, then:

1. `README.md`;
2. `AUDIT.md`;
3. `ARCHITECTURE.md`;
4. this runbook;
5. `ROADMAP.md`;
6. `HARNESS_ACCEPTANCE.md`;
7. `PROGRESS.md` last.

Do not reread historical semantic-job archaeology unless a specific regression
requires it.

## Parent-goal rule

The complete developer objective is P0–P8.

A phase or bounded chunk completing is not a stop condition. Under the provided
autonomous `/goal`:

```text
implement current chunk
→ validate
→ update PROGRESS
→ select next mandatory roadmap chunk
→ continue
```

Stop early only for a genuine technical/authorization/scope blocker or after
all developer-implementable P8 gates pass.

## Reuse before extension

Start from existing owners:

- PsychopatzCore semantic parser/candidates;
- Project Hoomans DialogueFlowRegistry/FlowKernel;
- ContextState and existing fact/context projection;
- DialoguePolicy/LocalResponse;
- ResponsePlan and ResponseCatalog;
- worker FlowEditor and production observation;
- Semantic Lab Studio/Simulation/Inspector;
- modular Conversation CodeBuilder and authoring service.

Do not create a second parser, conversation runtime, Python director, compiler,
translation system, or save database.

## Compiler/source discipline

Canonical authoring is under the existing modular Conversation CodeBuilder
source model.

When this job introduces beats/behaviors:

1. extend the canonical schema/manifest cleanly;
2. author beat/behavior definitions and Dialogue Content in canonical source;
3. derive translation keys/locale bundles mechanically;
4. compile generated Lua/JSON/manifests;
5. inspect the generated diff;
6. run focused tests;
7. run a second generation and prove idempotence;
8. commit source plus generated outputs together.

Generated output is never an authoring surface.

### String rule

Do not hardcode beat-specific first-party semantic/domain strings in production
Lua or Python.

Compiler-owned strings include:

- NPC response variants;
- player suggestions/utterances;
- beat/behavior labels displayed by the mod;
- localized descriptions/status text tied to semantic content;
- response text selected by beat behavior.

Use generic `translations` maps. EN is fallback. Do not add TL-specific normal
control flow or a fixed locale list.

Generic Semantic Lab chrome is not semantic content and may remain in Python UI
code.

## Beat/runtime discipline

- Beat definitions are data, not custom imperative scripts.
- Flows own bounded obligations/protocols; beats own social/dramatic situations.
- Behaviors are reusable across beats.
- Final prose remains Dialogue Content/ResponseCatalog responsibility.
- Gameplay effects remain on existing domain/action authority paths.
- High-confidence social interpretation does not imply authorization for an
  ambiguous gameplay effect.
- All beat/behavior selection must be inspectable from real worker evidence.
- Keep context, beat state, cooldowns, candidate counts, trace and timeline
  bounded.

## Harness authoring discipline

Temporary beat drafts may be validated, previewed and registered only inside
the disposable worker.

Clearly distinguish:

- Draft;
- Worker Registered;
- Canonical.

Diagnostic force/disable modes must emit a visible `HARNESS_OVERRIDE` marker
and cannot satisfy natural-arbitration acceptance.

Canonical promotion must delegate to the existing CodeBuilder authoring/write
path, then restart/reload the worker and replay acceptance.

## Validation discipline

At minimum for each coherent slice:

- focused Python tests;
- focused production Lua tests;
- real Lua-worker conversation cases;
- negative/ambiguous cases;
- compiler schema/build tests where source changes;
- two-pass CodeBuilder idempotence when generated outputs change;
- full native Lua suite for accepted runtime/compiler slices;
- Kahlua/static verifier when available;
- `git diff --check`;
- no source-save mutation.

Do not count:

- JSON shape checks alone;
- Python-only simulations;
- forced-beat override alone;
- selected IR without final rendered response;
- one exact scripted dialogue as proof of emergence.

## Git and environment

Use existing `main` only.

Before each coherent edit/commit:

- inspect branch/HEAD/status/upstream;
- preserve unrelated work;
- do not reset/rebase/stash/discard uncertain changes;
- do not create a branch;
- do not push unless explicitly authorized;
- do not publish Workshop content;
- do not launch native Project Zomboid for ordinary developer acceptance.

Local coherent commits are allowed after validation.

## Documentation updates

Keep:

- `ROADMAP.md` = full objective and phase gates;
- `PROGRESS.md` = current evidence, current phase, immediate Next Chunk;
- `ARCHITECTURE.md` = stable contracts;
- `HARNESS_ACCEPTANCE.md` = real-worker/GUI acceptance rules.

Do not add current progress to root `AGENTS.md`.
