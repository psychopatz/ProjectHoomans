# Corrected audit — 2026-10-17

## Repository and evidence

Project Hoomans GitHub `main` inspected at `56288e50e6d782634df7f26ceaa0f0cb7c0922f9` before this documentation correction, source implementing the candidate/flow/response-plan/sharded-translation architecture. PsychopatzCore remote `main` has **advanced to `44a4d534a9520440070ae7943d7ae9fb848f71ce`**; it now includes `Parser.ParseCandidates`, dialogue router candidate parser/selector + flow commit hooks, and manifest-aware `scope.registerSystem(systemName, basePath, manifestPath)`.

**IMPORTANT CORRECTION:** The previous audit's claim that *published Core lacks all three APIs and requires Workshop republishing* is now **stale**. The Core API features are code-verified on the latest connected GitHub branch; the exact local/staged files used by a future test remain a separate fact. Do not block on Workshop publication or assume a live game is running.

Previous agent's local C0B report states compatibility work committed as `27e1fd94` in the user's worktree and app polling repeated; that local commit was not independently recovered from connected GitHub by this audit. Treat as **user-provided agent report**, not GitHub proof. Avoid undoing its local files. The remote Hoomans main at audit time is not a source of local worktree status.

## Code-verified implemented foundation

- Hoomans `PNC_SemanticDialogueCandidateEligibility.lua` selects/rejects bounded candidate interpretations.
- `PNC_SemanticDialogueFlowRegistry.lua` and `...FlowKernel.lua` register validated flows and maintain bounded active/suspended state. `...Flow_Identity.lua` and `...Flow_Wellbeing.lua` are registered.
- `PNC_SemanticDialogueResponsePlan.lua` supports typed segments, plan validation, `Attach`, `Compose` and rendering.
- Hoomans `common/media/translation/manifests/Conversation.json` lists 12 EN + 12 TL shards. Core now supports manifest registration. Preserve stable keys and the previously reported 521-key per-language baseline; don't reshard files without evidence.
- Semantic Lab has a persistent production Lua worker, GUI transcript, scenario controls and trace, plus tests. It is **not proven to offer the complete interactive branch authoring UI** requested.

## Remaining implementation gaps (not completed solely by headless passes)

1. **Semantic Lab usability/trust:** user reports the present headless-centered harness approach is broken/unhelpful for agent visualization. Audit and repair the **existing GUI + shared worker/session** so it loads production modules and exposes real selected IR/flow/node, reply, translation and side effects. Do not make another JSON-only harness or pile up synthetic fixtures.
2. **Flow has weak response authority:** `PNC_SemanticDialoguePolicy_Flow.lua` computes `flowPreview` but still calls the central `resolveIntentBranch`, then `PNC_SemanticDialogueLocalResponse_Resolve.lua` chooses response by legacy branch. No verified production consumer of `decision.flow.responsePool`. A flow-state trace can pass while replies ignore the selected flow.
3. **Response composition not adopted:** policy uses `ResponsePlan.Attach` on a selected reply. No normal-game `Plan.Compose` call site was located; multi-act EN/TL NPC speech remains to implement.
4. **Flow authoring not done:** GUI has transcript and trace, not a functional graph/transition editor backed by the production registry.
5. **Some translation/domain integration remains:** direct `Trading` system lookup was reported to fall back; needs specific scope/consumer proof. Source shard parity is necessary but does not guarantee correct display without an actual lookup through Core.
6. **Native PZ evidence:** user reports limited live success, but controlled SP/MP acceptance is for the **user at the end**. Do not turn it into a Codex blocker or require a PZ process.

## Test evidence classification
Earlier agent ledger reported 97/97 Python harness, 68/68 focused Lua, and 12 failing full headless Lua tests (native/UI-associated), plus Core catalog smoke count mismatch. These are **agent-reported**, not independently executed here. Keep regression failures accurately categorized; never claim 100% or 'native accepted' from green fixtures. The goal is **working observable behavior through the existing Semantic Lab**, not maximizing test counts.

## Verdict
Reopen any local goal marked `blocked` only for absent PZ/Workshop (unless it has a separate genuine blocker). Preserve implemented Core and Hoomans code; proceed with practical harness repair, flow-driven behavior, visual authoring and coherent EN/TL reply integration. Final real-game testing is handed to the user.
