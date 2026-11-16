# Semantic Generation Lifecycle Cleanup

**Status:** REOPENED — G0–G6 remain accepted groundwork; G7 structural ownership refactor is active.

## Parent objective

Make Semantic CodeBuilder generation a closed-set, ownership-aware reconciliation process so obsolete generated Lua, translations, manifests and legacy output paths are removed automatically and safely instead of becoming repository archaeology for future coding agents.

The permanent workflow should be:

```text
canonical semantic sources
        ↓
CodeBuilder generation recipe
        ↓
compile complete desired artifact plan
        ↓
validate before mutation
        ↓
reconcile owned outputs
        ├── rewrite current artifacts
        ├── prune proven stale artifacts
        ├── prune stale generated keys from mixed catalogs
        └── reject unexpected/unowned leftovers
        ↓
post-generation closure check
```

Agents should not manually inspect hundreds of generated files to decide what is stale. They should read the compact recipe and run the canonical reconciliation command.

## Scope

Primary job/document owner:
- `ProjectHoomans`

Implementation owner:
- `psychopatzCore/tools/semantic_harness/codebuilder/`

Generated adopter/output surfaces:
- `ProjectHoomans`
- `psychopatzCore`
- `DynamicTrading/DTCommon` when present/enabled

This is a lifecycle/cleanup job, not a semantic behavior redesign.

## Core outcomes

1. Introduce one compact machine-readable **CodeBuilder generation recipe** describing generated surfaces, ownership and cleanup strategy.
2. Introduce one canonical **check/apply reconciliation entrypoint** so an agent does not perform manual semantic generated-file cleanup.
3. Make all CodeBuilder-owned artifact families closed-set after successful generation.
4. Structurally separate hand-written engine/adaptor code, canonical CodeBuilder semantic source, generated runtime output, and ordinary application/tooling translations.
5. Eliminate legacy hand-authored runtime dialogue content by migrating it into canonical CodeBuilder families.
6. Keep the permanent recipe compact and policy-based; do not grow per-file preserve/retirement inventories.
7. Add deletion/migration regressions so stale artifacts cannot quietly return.
8. Keep `AGENTS.md` guidance brief: edit canonical source, run the recipe/reconciler, never patch generated output as source-of-truth.
9. Preserve all accepted ConvoEngine naming, stable-ID, realization, owner-routing, and semantic sharding rules while simplifying lifecycle ownership.

## Non-goals

- Do not redesign NLU, dialogue arbitration, response wording, or semantic gameplay behavior.
- Do not collapse legitimate generated shard files merely because their names contain hashes.
- Do not delete files using broad age/name heuristics.
- Do not convert ordinary application/tooling translations into ConvoEngine content merely to simplify cleanup.
- Do not preserve legacy hand-authored dialogue text merely because it is currently a runtime translation file.
- Do not create a second semantic generator beside CodeBuilder.
- Do not require native Project Zomboid for developer-side acceptance.

## Minimal read order

1. root `AGENTS.md`
2. this README
3. `PROGRESS.md`
4. `AGENT_RUNBOOK.md`
5. relevant phase in `ROADMAP.md`
6. `ARCHITECTURE.md` when changing lifecycle contracts
7. `AUDIT.md` only when baseline evidence is needed
8. `G7_STRUCTURAL_OWNERSHIP_REFACTOR.md` for the active corrective architecture
9. `psychopatzCore/Docs/semantic_dialogue_language_standard/CONVO_ENGINE.md` and `NAMING_AND_LAYOUT.md` when touching naming/sharding
10. `HARNESS_ACCEPTANCE.md` when accepting a phase

The chat-delivered `/goal` is not checked into the repository.
