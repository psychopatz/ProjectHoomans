# Contextual Semantic Intelligence — phase roadmap

Phases are mandatory unless explicitly marked optional. All gates are **unaccepted** as of the source-only audit on 2026-10-17. Progress is recorded only in this folder's `PROGRESS.md`.

## Phase 0 — Semantic Lab correctness baseline (ACTIVE)

**0A — next chunk:** Prove current production-worker coverage of wellbeing context and fix the minimal scenario-to-context projection needed to vary real NPC health, active behavior, needs/conditions and relationship without hard-coded values. Keep legacy `scenario.world` fields compatible. Add explicit end-to-end assertions in the existing Semantic Lab tests for the observed context and output. Collect baseline outcomes for healthy, injured, severe-thirst, uncertain and relationship-variant scenarios using real production modules.

**0B:** Build a small manually reviewed utterance and multi-turn case matrix. Record actual IR, branch, response, before/after context, LLM calls and transported actions. Measure test baseline and preserve expected existing coverage. Do not change reaction semantics in Phase 0.

**Gate:** `--doctor` works, production module manifest proves real target modules loaded, headless real-worker scenario and explicit assertions run, protocol conflict ledger remains valid, baseline results recorded; known limitations and native-game tests marked pending.

## Phase 1 — Wellbeing contextual reaction pilot

**1A:** Trace existing `QUESTION/WELLBEING` response conditions; enhance existing catalog/context paths before considering a new arbiter. Distinguish healthy, injured, urgent-thirst, stressed/panicked and truly unknown state without inventing unsupported facts.

**1B:** If a response requires a new *behavior* (not wording variant), introduce the narrowest pure reaction-selector hook into the existing policy with explicit precedence, diagnostics and regression tests. Otherwise explicitly document why no new selector was required.

**Gate:** Same recognized utterance generates different factually appropriate NPC reactions through Semantic Lab *real Lua worker*; no PBrainZ calls; no gameplay side effects or regressions to existing identity, gifts, tasks and social responses.

## Phase 2 — Multi-turn wellbeing and commitments

Reuse pending-request, topic, entity references and dialogue context. Add bounded follow-up resolution for "What's wrong?", "Can I help?", clarification, changed mind/correction, speaker-target and topic interruption/reentry. No independent transcript storage.

**Gate:** Replay real Lua multi-turn cases; correct topic/speaker, bounded state, preview idempotence, no invented obligations or task activation; explicitly assert expected before-after state.

## Phase 3 — Broader contextual social reaction

Extend already-authored relationship/emotion/social response conditions to select relevant *behaviors* for apologies, offers, reassurance, threats and disputes. Establish precedence for overlapping reaction candidates without rewriting response catalogs.

**Gate:** Same speech act produces appropriate guarded reactions for varied relationships, and does not mutate relationship/task state except through existing authorized paths.

## Phase 4 — Semantic paraphrase coverage

Use the existing `tools/semantic_harness/codebuilder` reviewed WordNet and dialogue compilation workflow. Add only paraphrases proven missing by baseline samples; preserve strict verb morphology and fuzzy command safety, and the existing IR/catalog IDs where possible.

**Gate:** Held-out paraphrase success improves against measured baseline; no new false-positive task/command routing; compiler tests and Semantic Lab production traces pass.

## Phase 5 — Optional PBrainZ and group compatibility

Expose read-only selected reaction and relevant context to optional provider, reusing present context builder. Keep deterministic offline responses functional; bind dialogue state to actual speaker/conversation keys, not a global NPC default.

**Gate:** LLM disabled/enabled parity for semantic intent and action authorization; no cross-speaker leakage; group conversation tests and native acceptance evidence.

## Phase 6 — SP/MP/game acceptance and performance

Run actual Project Zomboid Build 42 runtime checks after Semantic Lab. Validate live UI, server authority, multi-NPC sessions, save/reload where applicable, no extra tick polling and measured dialogue overhead. Record exact build, results and failures.

**Gate:** Complete live-game evidence and a clean focused regression suite on the tested revision, with recognized limitations documented. Then mark maintenance-ready.

## Transition rule

Advance one phase only after its acceptance gate is evidenced; retain outstanding game acceptance as an explicit gate. No broad feature sweep, whole-repository refactor or docs-only phase churn. If an early audit proves a phase's feature already exists and works, mark it implemented **with evidence** and move to the next unmet product gate.
