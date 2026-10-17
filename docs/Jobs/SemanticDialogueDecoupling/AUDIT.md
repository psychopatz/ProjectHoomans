# Corrective audit — current repo vs product goal (2026-10-17)

## Evidence boundaries

**Source verified through connected GitHub:** Project Hoomans `main` `d345e5c3ba41ba752517b405320e6d61e847a3f8`, PsychopatzCore `main` `0212491d2af3597cceaa7353e62f01ef54adca44`. The agent's historical `PROGRESS.md` recorded an Hoomans implementation at `e804750f36e1...` and locally modified Core at `afc1bda0f5f3aaec1bbe1693f1264cd5d990ed5d`; the latter commit and other reported Core candidate/router commits could **not** be found on the connected Core remote. No claim about the user's local installed Core or current worktree cleanliness is made here.

**Agent-reported, not independently rerun:** 97/97 Semantic Lab Python, 68/68 focused Lua, translation-shard parity, manifest smoke, response-plan smoke; full headless suite 12 failures, described in old ledger as pre-existing UI/native failures. Core legacy catalog smoke additionally fails a hardcoded 316-vs-334 coverage assertion after unrelated in-flight catalog edits. No hosted CI runs found; no controlled native SP/MP acceptance captured. User reports some limited successful live play, without a complete recorded test matrix. Preserve prior detail in `IMPLEMENTATION_EVIDENCE.md`.

## Finding A — dependency release mismatch (CRITICAL)

Hoomans `PNC_TranslationBootstrap.lua` passes a manifest third argument to `Scope.registerSystem`, with `manifests/Conversation.json`. Published Core `PsychopatzCustomTranslationManager.lua` implements `scope.registerSystem(systemName, basePath)`; its registration normalization has no manifest field. Published Core therefore ignores the third argument and reads legacy `EN/Conversation/Conversation.json`, which Hoomans removed.

Hoomans candidate integration expects optional `Parser.ParseCandidates` and router candidate/flow hooks. Published Core parser exposes `Parser.Parse` but not `ParseCandidates`; published Core router has no matching candidate/commit hooks.

**Consequences:** installed Hoomans + published Core are not established compatible. Exact runtime behavior depends on which Core revision is installed. Do not infer all in-game text fails: default response fallbacks and alternate paths can mask missing localized catalogs. Establish the deployed file set first. Do not weaken authority as a workaround.

## Finding B — flow kernel is not yet behavioral authority (HIGH)

`PNC_SemanticDialogueFlowRegistry.lua`, `...FlowKernel.lua` and two modules `...Flow_Identity.lua` / `...Flow_Wellbeing.lua` are real. The kernel previews/commits bounded state and returns `responsePool` metadata. But `PNC_SemanticDialoguePolicy_Flow.lua` still calls `resolveIntentBranch` to choose branch; `PNC_SemanticDialogueLocalResponse_Resolve.lua` still selects text by that branch. No production consumer of `decision.flow.responsePool` was established in this static review. A successful flow transition therefore does **not** prove a flow chose the reply or action.

Registry `PNC_SemanticDialogueFlowCatalog.lua` explicitly lists two flow modules. New conversation types can be registered but an end-to-end no-central-switch addition has not been demonstrated.

## Finding C — response planning is infrastructure, not full realization (HIGH)

`PNC_SemanticDialogueResponsePlan.lua` validates bounded turns/segments, builds/attaches plans and exposes `Compose`/`RenderTurns`. In ordinary policy `PNC_SemanticDialoguePolicy_Decision.lua`, `ResponsePlan.Attach(result.response, result.branch)` wraps an **already selected** response. The `Plan.Compose` production call site was not found outside isolated smoke tests. Multi-act in-game composition, flow-selected plans and grammatical EN/TL realization remain unaccepted.

## Finding D — Semantic Lab is a trace tool, not the requested flow editor (HIGH)

Existing Tk `tools/semantic_harness/gui.py` has a conversation editor, mock scenarios/settings, transcript and trace panel. There is no found interactive graph-node/edge editing or production flow registration UI. Worker trace and graph-validity tests are real, but do not establish the desired authoring interface.

## Finding E — translation files moved correctly; runtime contract unresolved

Hoomans now has `common/media/translation/manifests/Conversation.json` listing **12 shards for EN and 12 for TL**, and removed the former 521-key per-language monolith. Historical ledger reports 521-key exact-value/placeholder parity in both languages; independent runtime recheck against the **deployed** matching Core is still required. The `Trading` custom catalog remains outside 15 bootstrap systems; agent reported its direct lookup falls back to default. Do not call other catalogs broken without source/consumer evidence.

## Finding F — headless acceptance overclaimed

The existing worker invokes many real Lua modules and can test parser, state, registry and fallback contracts, so it is valuable for diagnosis. It mocks critical PZ UI/network/world boundaries and cannot establish game display, server authority, native file loading or actual MP synchronization. The full Lua headless suite has 12 reported failures; classify and reproduce individually rather than globally relabeling them harmless. Native-only limitation is not a reason to manufacture more JSON fixtures.

## Verdict

Original phases 0A–8 are **implemented with reported worker-level tests**, not accepted as the completed real-game architecture. Open a corrective integration phase: reconcile installed/published Core, establish live game baseline, then make flow selection actually own response behavior, implement real visual authoring, finish multi-act composition and domain/localization acceptance. Preserve the working code; no Jess rewrite or new job.
