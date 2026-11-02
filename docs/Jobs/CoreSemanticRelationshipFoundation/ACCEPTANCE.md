# Acceptance — Core Semantic & Relationship Foundation

**Current status:** READY FOR USER LIVE TEST. All P0-P17 requirements and corrective boundaries have been implemented, verified, and audited across psychopatzCore, DynamicTrading, and ProjectHoomans.

## A. Ownership and canonical identity

- [x] PsychopatzCore is the canonical owner of shared actor/base social state.
- [x] Core has a persistent player-character target-key contract and DT uses it.
- [x] Normal DT-first UUID/key adoption through the real Hoomans service now preserves the exact UUID/key.
- [x] Core maintains authoritative persistent issuance/adoption state for player identities (`PsychopatzPlayerIdentity.STORAGE_KEY = "PsychopatzCore.PlayerIdentity"`).
- [x] Hoomans adoption verifies authoritative Core issuance rather than only reproducible modData values (`CoreIdentity.IsIssuedIdentity`).
- [x] Arbitrary unknown UUID + correctly forged public provenance hash is rejected by the real Hoomans service.
- [x] Hoomans-first identities register/adopt into Core authority without UUID replacement (`RegisterIssuedIdentity(..., { source = "hoom_created" })`).
- [x] Transient online ID is not canonical relationship identity.
- [x] Cross-account claims are rejected in the current path.
- [x] Authoritative issuance persists/reloads and adoption remains idempotent.
- [x] Core has no adopter gameplay-policy dependency.

## B. Core-first relationship integrity

- [x] Stale Hoomans social state cannot delete newer DT memories/extensions.
- [x] DT -> Hoomans and Hoomans -> DT interleaved writes preserve both adopter extensions and shared changes.
- [x] Alias convergence/idempotent social synchronization regressions pass.

## C. Semantic pack lifecycle and production isolation

- [x] Pack ownership/unregister/re-register is residue-free in focused tests.
- [x] `PsychopatzActorConversationService` propagates effective capabilities into parsing.
- [x] DT-only production conversations reject Hoomans grammar when both packs are installed.
- [x] Hoomans-only production conversations reject DT grammar without DT capability.
- [x] Compound turns preserve capability isolation.

## D. Project Hoomans additive adopter

- [x] Hoomans Core semantic pack uses the actual Core schema.
- [x] Follow/camp/recruit/wellbeing examples and relationship gates work.
- [x] Hoomans gameplay actions remain Hoomans/server authority.
- [x] Normal DT-first identity can currently be adopted without UUID replacement.
- [x] Adoption trust is backed by Core authoritative issuance state rather than forgeable self-consistent modData.

## E. Standalone Dynamic Trading semantics

- [x] Core + DT works without Project Hoomans.
- [x] Required parser families now cover identity, trade, trader location, destination, origin, settlement, route, road news, caravan story, and farewell.
- [x] No-evidence destination/news paths return bounded uncertainty/no-news.
- [x] Real acquired route WorldKnowledge facts ground generic route questions with fact IDs.
- [x] Destination/next-settlement production state exists upstream of TalkService and is used for `where are you heading` (`Policy.SetDestinationSettlement`, `TraderService.SetDestinationSettlement`).
- [x] Origin/last-settlement and settlement answers are proven through canonical DT production state, not Submit option injection (`Policy.SetOriginSettlement`, `Policy.SetCurrentSettlement`, `Policy.MarkVisit`).
- [x] Road-news final acceptance is proven from real published/acquired WorldKnowledge, not hand-built Submit gossip (`WorldKnowledge.Publish` + `WorldKnowledge.Acquire` into Core ledger).
- [x] Factual answers survive DT save/reload from canonical state.
- [x] Authored generic caravan storytelling remains clearly non-current flavor.

## F. Real hot-plug/removal

- [x] Current matrix exercises real Hoomans identity service, interleaved social writes, production capability isolation, pack lifecycle, and sync idempotence.
- [x] Final matrix proves forged identity rejection through authoritative issuance.
- [x] Final matrix seeds destination/origin/settlement through real DT owner APIs rather than `TalkService.Submit` answer options.
- [x] Final matrix seeds road news through real WorldKnowledge publish/acquire path.
- [x] Remove/re-add preserves authoritative identity state and factual DT state.

## G. Performance

- [x] No global per-tick semantic pack scan.
- [x] No periodic full relationship reconciliation.
- [x] P16 issuance registry and P17 production fact plumbing remain bounded to identity/load/event/conversation boundaries.

## H. Developer validation

- [x] Core focused corrective tests passed (`psychopatz_player_identity_smoke.lua` 7/7, actor, conversation, lifecycle tests pass).
- [x] Dynamic Trading full runner passed 43/43 (`dt_standalone_semantic_story_smoke.lua` passes with production-derived state).
- [x] Hoomans focused corrective tests passed (`pnc_core_player_identity_adoption_smoke.lua` 9/9, `pnc_real_cross_adopter_hotplug_matrix_smoke.lua` 6/6 sequences, non-destructive social mutation, and core semantic adopter smoke tests).
- [x] Hoomans broad runner reached 982/987 with the exact same five documented pre-existing baseline failures.
- [x] Changed Lua parsed with `luac5.3 -p` and all repos passed `git diff --check`.
- [x] P16 forged-provenance adversarial tests pass across both Core and Hoomans.
- [x] P17 upstream-production grounding tests pass without answer option injection.
- [x] Final P16-P17 matrix passes and exact repository revisions/status are recorded.

## User-owned native handoff

All P0-P17 developer gates above pass.

Ready for user-owned native SP/MP verification:
1. DT-only save: interact with traders, check relationship-grounded dialogue, whereabouts, road news, and trade.
2. Add Project Hoomans: verify exact player and NPC identity are preserved, relationship values and DT extensions persist, Hoomans social/dialogue features activate.
3. Remove Project Hoomans: continue DT play, verify DT trade and dialogue continue cleanly without error.
4. Re-add Project Hoomans: verify Hoomans extensions and memories recover intact.
