# Architecture — Semantic Exhaustive Dialogue Quality Sweep

## Authority and reuse

### Existing authoritative owners

- **PsychopatzCore NLU / ProjectHoomans semantic Lua**: interpretation, policy, flow state, eligibility and semantic decisions.
- **ResponseCatalog / SpeechRealization / Dialogue Content**: response identity, realization and authored wording.
- **Semantic Test Subsystem**: scenario/fixture execution primitives and bounded matrix mechanics.
- **Response Observatory / Conversation Inspector**: read-only runtime evidence, actor context and provenance.
- **Simulation/persona control catalogs**: production-backed editable context dimensions.
- **CodeBuilder / source lineage**: canonical content ownership and safe authoring boundaries.
- **Studio**: content/source authoring and review.
- **Simulation**: live/single-scenario interaction and inspection.
- **Quality Sweep workbench**: broad batch planning, coverage, quality triage and replay.

The Quality Sweep workbench is a new **GUI surface**, not a new semantic engine. CLI, Simulation entry points and the dedicated GUI must all consume the same sweep service layer.

## Corrected core flow

~~~text
Production catalogs + live choice/response registries
                    |
                    v
     Surface + Dimension + Pool Discovery
                    |
                    v
       Bucket / Coverage / Frontier Planner
                    |
                    v
     <=64 case batches + resumable manifest
                    |
                    v
            Production Lua worker
                    |
                    v
        Planned-vs-Reached Verification
                    |
                    v
    Conversation Inspector / Observatory join
                    |
                    v
          Compact Evidence Rows
          /                   \
         v                     v
 Run-level Quality        Lazy Inspector Resolver
 Analyzer + Clusters       + Source Navigation
         \                     /
          v                   v
      CLI / Quality Sweep Workbench / Review Bundles
~~~

## Production surface discovery contract

The planner must not treat a historical hard-coded root-choice string as proof of a current interaction surface.

A discovered surface record should include, where applicable:

- stable surface ID;
- presentation/candidate ID;
- provider/source kind;
- frame/action metadata;
- semantic or flow identity;
- prerequisites/eligibility;
- discovery source and revision;
- whether the surface is directly executable or requires a bounded adapter.

Typed utterance surfaces may be represented by production semantic fixture families rather than every free-form string.

Each planned case carries a planned surface identity. Execution must capture the observed surface/semantic route and classify reachability as matched, expected fallback, invalid/mismatched, or execution failure.

## Dimension discovery contract

Consume current production control/persona catalogs.

For option-bearing controls:

- scalar options may be used directly;
- object options must extract canonical `value`/ID and preserve label separately;
- multi-select arrays must validate each canonical value;
- never stringify an arbitrary option object into the mutation domain.

Read-only/derived fields remain output-only.

## Compact evidence contract

A compact row is only accepted when it faithfully projects current Inspector data.

### Actor/context source priority

Use current authoritative Inspector structures, including where available:

- `personaChoices.actorConversationContext.personalRelationship`;
- `personaChoices.actorConversationContext.relationship`;
- `personaChoices.actorConversationContext.personality`;
- `personaChoices.actorConversationContext.traits`;
- `personaChoices.actorConversationContext.roles`;
- `personaChoices.actorConversationContext.situation`;
- `socialContext.durableBond`;
- response trace/persona choice data;
- observation/engine facts for needs/health/world state;
- semantic/effects/execution/source projections.

Fallback paths may exist for schema compatibility, but tests must prove the current primary paths are populated.

### Required bounded groups

- identity/case/batch/surface/language;
- changed parameters;
- planned and reached semantic surface;
- relationship/bond;
- persona/style/traits;
- relevant needs/health/activity;
- semantic/response/realization/phrase/translation identities;
- selected/rejected provenance;
- canonical source or explicit UNKNOWN;
- action/effect/authority;
- deterministic quality flags;
- resolvable lazy trace handle.

A trace handle is not accepted merely because it says `lazy=true`; the service must resolve it.

## Coverage strategies

### Smoke

At least one representative case for each discovered approved surface in each selected language, subject to explicit caps.

### Boundary

Vary each selected dimension through semantic bucket values against controlled baselines and distribute those cases across relevant valid surfaces.

### Pairwise

Cover all permitted value pairs in the selected bounded dimension set and report excluded/uncovered pairs.

### Persona/relationship

Exercise production personality, social style, trait, bond, relationship, identity-trust and authority contexts across relevant response surfaces.

### Variant frontier

Start from the complete paginated response registry and use production explanations to target still-unobserved eligible variants.

### Full bounded

Deterministic deduplicated union of approved strategies. Full means complete coverage of the declared surface/dimension/bucket/frontier contract at the recorded revisions, not an infinite Cartesian product.

## Batch/resume state machine

States must distinguish:

- PENDING;
- RUNNING;
- COMPLETED_VALID;
- COMPLETED_WITH_INVALID_SURFACE;
- FAILED;
- CANCELLED/INCOMPLETE.

Cancellation is resumable. A new executor must be able to continue cancelled/incomplete work after validating plan and catalog compatibility.

Do not duplicate completed case rows on resume. Case-level progress may be needed inside a batch.

## Complete response registry contract

Pool enumeration must paginate until production reports completion. Never hard-code a maximum page as the complete registry.

The report records production total, enumerated total and pagination completeness.

## Run-level quality analysis

Per-row heuristics cannot detect repetition across cases. The quality layer therefore has two stages:

1. **row analyzer** for local textual/context defects;
2. **run analyzer** for duplicates, repetition, generic-response concentration and fallback saturation.

Run-level flags should retain case IDs, semantic causes and context differences so one root defect can be clustered correctly.

## Dedicated Quality Sweep GUI ownership

The Semantic Harness has three distinct human workflows:

- **Simulation** — interact with one scenario/NPC context and inspect a conversation.
- **Quality Sweep** — plan and execute broad matrices, browse coverage/reachability, triage outputs, inspect evidence, replay affected cases.
- **Studio** — edit/review canonical semantic content and source lineage.

The dedicated Quality Sweep workbench is a top-level harness workspace or equivalently prominent first-class page. It must not be buried solely inside Simulation's trace notebook.

See `GUI_WORKBENCH.md`.

## GUI execution architecture

Long sweep work may not run synchronously on the Tk event thread.

Use a background worker/task queue or equivalent established harness pattern. Requirements:

- no Tk widget mutation from worker thread;
- progress/events marshaled via `after()`/UI queue;
- cancel flag remains responsive;
- close/shutdown safely terminates or detaches work;
- resume reconstructs state from manifest;
- UI never mutates source saves.

## LLM/human review

Deterministic evidence remains authoritative. LLM/human review may judge naturalness, blandness, setting fit and persona quality, but cannot silently change gameplay semantics/authority.

Review bundles remain bounded and point back to exact case/evidence/source identities.

## Safety/performance

- production Lua remains semantic authority;
- no runtime LLM dependency;
- no per-frame NPC scanning;
- no unbounded registry payloads—paginate/stream;
- no committed giant result snapshots;
- no source-save mutation;
- no native PZ launch required for developer-side acceptance.
