# Procedural Semantic NLP Compiler — automatic capability-to-production-flow pipeline

**Direction changed 2026-10-18.** The preexisting compiler is useful but narrow: `tools/semantic_harness/codebuilder/sources/semantic_definitions.json` authors one FOLLOW request and its `PNC_SemanticGeneratedDefinitions_Flows_01.lua` flow contains only a terminal response node. `_semantic_flow` accepts no executable capability/result node; `compile_semantic_definitions` restricts authored top-level frames to REQUEST/REQUEST and therefore cannot compile OFFER/GIFT. Recorded previous worker/generation tests prove that *subset* only.

## End-to-end compiler contract

1. Discover the live **production capability and semantic registries** and snapshot stable descriptor/schema versions; respect available permissions, source modules, owner.
2. Classify each recognized capability into reusable workflow templates defined in `AUTOMATIC_FLOW_GENERATION.md`. Build explicit coverage report including unsupported capabilities; preserve existing hand-authored response-only flows and untranslated/legacy owners.
3. Generate typed editable **canonical authoring definitions**: trigger frames and *reused existing* pattern IDs where possible, reviewed linguistic positives/negatives, typed args, context gates, action binding ID, result classes, dialogue/response nodes, EN/TL keys, translated fallback. If metadata insufficient, request contract extension from owner / show missing fields, do not infer.
4. Validate/collision check against actual Core parser/candidate precedence, registry boundaries, existing Flow Registry schema, registered handler and result types, unknown facts, speaker/addressee scope, source uniqueness, translation manifests and migration/version constraints.
5. Compile deterministically into **modular Lua patterns/flows/responses and explicit manifests**, using existing `tools/semantic_harness/codebuilder` and actual mod media layout; no new runtime JSON interpreter and no arbitrary Lua string execution. Generated flow owns orchestration while adapter owns effects.
6. Surface a **dry-run coverage + exact file diff** through Semantic Lab, require explicit Generate approval and restart actual worker. Re-run positive/negative/denial dialogue cases and verify selected generated flow + result branch + real worker utterance. Repeat generate on same canonical inputs and assert byte-identical files.
7. Incrementally regenerate only changed definitions; protect graph/code edits and overlay metadata, never overwrite unrelated handwritten Lua, preserve translation owners and normalized stable IDs.

## Generality requirements

- Compiler must not special-case a list of known actions. Templates are extensible **by workflowKind** and capability descriptors define actual binding. A generic `simple_command` renderer must handle FOLLOW and STAY (and any other eligible registered descriptor) without extra per-action generator code. As other templates ship, coverage widens automatically.
- New intent types beyond REQUEST/REQUEST (OFFER/GIFT, QUESTION/INFO, etc.) require versioned support and confidence/negation rules; do not relax executable safety just to support more syntax.
- Auto-expand grammar only from reviewed/registered patterns and conservative templates; distinguish recognition examples from unsafe imperative permission. No unreviewed WordNet synonym explosion.
- A capability descriptor that lacks authorization/parameter/result metadata must never generate a runnable action node; mark it with actionable diagnostic and owner.
- Registry max 32 flows and 32 nodes per flow as currently observed; audit safe capacity and performance before batch generation, avoid boot failure due to excessive output.
- Existing tests and X11/UI/worker evidence are baseline only. Acceptance is now **catalog coverage + two generated flows from one template + actual runtime flow outcome** initially, and later all supported workflow families.

## Generated source and test artifacts

Use canonical Project Hoomans Build 42.20 paths after checking actual `AGENTS.md`: shared Lua modules under `42.20/media/lua/shared/PNC/Semantics/`, authored/portable definitions and EN/TL translation assets in their existing approved locations. Explicit require manifest/load order; deterministic sharding; no side outputs in arbitrary test JSON or `tools` as the only deliverable. Generated test-case *plans* are useful, but real Lua worker is the authority for semantics.

Required diagnostics: `sourceSHA/templateVersion/capabilityRevision, coverage, generated/unsupported, collisions, missingFields, compiledPaths, existingOwnedFiles, worker-loadedFlowID, matchedIR, gate, binding, request/result, response, transport/effects`.

## Implementation sequence

G0A single registered simple-command template drives multiple generated complete action flows and real-Lua worker results. G0B parameterized task template, G0C multi-stage gift template, G1 bulk generation / coverage and safe regen UI, G2 conversation/context/quest extensions. Never declare general generation complete based on one manually filled `semantic_definitions.json` file.
