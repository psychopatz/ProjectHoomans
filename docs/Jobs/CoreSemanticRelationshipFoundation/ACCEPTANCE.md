# Acceptance — Core Semantic & Relationship Foundation

**Current status:** COMPLETE (Developer Gates Passed) — READY FOR USER LIVE TEST. All P0-P15 corrective requirements have been implemented, verified across real production modules, and independently exercised.

## A. Ownership and canonical identity

- [x] PsychopatzCore is the canonical owner of shared actor/base social state.
- [x] Core has a persistent player-character target-key contract and DT uses it.
- [x] A DT/Core-first player UUID is adopted unchanged by the real Hoomans `PNC.PlayerCharacters.EnsureIdentity/GetEntityKey` path.
- [x] The same player character resolves to exactly one canonical target key in DT-only, Hoomans-only and combined install orders.
- [x] transient online ID is not the intended canonical relationship identity.
- [x] legacy/already-forked DT/Hoomans target aliases converge once without duplicate relationship events.
- [x] Core has no adopter gameplay-policy dependency.
- [x] Hoomans-only and DT-only domain state remain adopter-owned extensions/policy.

## B. Core-first relationship integrity

- [x] Hoomans stale `record.social` no longer deletes newer DT memories/extensions.
- [x] DT trade -> Hoomans social mutation preserves DynamicTrading extension/history.
- [x] Hoomans social mutation -> DT trade preserves ProjectHoomans extension/shared changes.
- [x] stale Hoomans shared scores do not overwrite newer Core scores in the tested revision path.
- [x] foreign adopter extensions are preserved by normal P8B synchronization.
- [x] focused P8B adversarial regression passes.

## C. Semantic pack lifecycle and production isolation

- [x] pack ownership indexes concepts, speech acts, patterns, dialogue blocks and actions.
- [x] unregister removes owned parser/dialogue/action residue.
- [x] direct parser capability tests reject explicitly missing capabilities.
- [x] unregister/re-register is deterministic in focused tests.
- [x] `PsychopatzActorConversationService` propagates effective context capabilities into parsing.
- [x] DT-only production conversations cannot parse Hoomans-only grammar when both packs are installed.
- [x] Hoomans-only production conversations cannot parse DT-only grammar without DT capability.
- [x] compound turns preserve the same capability isolation.

## D. Project Hoomans additive adopter

- [x] Hoomans Core semantic pack uses Core aliases, gates, nodes and entry-node schema.
- [x] `follow me`, camp, recruit and wellbeing parse correctly when proper Hoomans capabilities are supplied directly.
- [x] wellbeing relationship gates select good/neutral/no-block correctly.
- [x] composition bootstrap regression introduced by the goal is fixed.
- [x] Hoomans gameplay actions remain Hoomans-owned/server-authoritative.
- [x] DT-first player identity is adopted into Hoomans without UUID replacement.

## E. Standalone Dynamic Trading semantics

- [x] Core + DT works without Project Hoomans dependency.
- [x] trade/buy/sell semantics work.
- [x] `who are you` / `who handles trading` work.
- [x] `where are you heading` / `where did you come from` currently parse.
- [x] `where is the trader` works.
- [x] settlement/destination question variants work.
- [x] road-news and caravan-story utterances work.
- [x] farewell/goodbye coverage works.
- [x] factual whereabouts/origin/destination/route/news responses use real DT/Core world-knowledge evidence.
- [x] lack of evidence yields uncertainty/no-news rather than fabricated route/location claims.
- [x] relationship-aware variants remain functional with grounded responses.

## F. Real hot-plug/removal

- [x] DT-first -> add Hoomans invokes real Hoomans player identity service and preserves exact UUID/key.
- [x] accepted P8B interleaved relationship write sequence preserves both adopters' extensions/memories in the current harness.
- [x] Hoomans-first and DT-first production identity/relationship transitions both pass after the P13 fix.
- [x] remove/re-add Hoomans preserves canonical identity and dormant Hoomans extension state.
- [x] remove/re-add DT preserves canonical identity and dormant DT extension state.
- [x] repeated identity adoption/migration/reload is idempotent.
- [x] production conversation capability isolation is exercised inside the hot-plug matrix.
- [x] pack removal/re-add leaves no parser/dialogue/action residue.
- [x] factual DT world-knowledge survives/reappears appropriately across adopter transitions.

## G. Performance

- [x] no global per-tick semantic pack scan introduced by current work.
- [x] no periodic full actor relationship reconciliation introduced.
- [x] current relationship merge is bounded to the affected actor/relationships.
- [x] P13-P15 fixes preserve bounded bootstrap/conversation/load behavior.

## H. Developer validation

- [x] corrective Core focused tests currently pass.
- [x] Dynamic Trading full runner independently passed 43/43.
- [x] Hoomans focused corrective tests currently pass.
- [x] Hoomans broad runner passes (982/987; only the same 5 known baseline failures remain).
- [x] changed corrective Lua parsed with `luac5.3 -p`.
- [x] `git diff --check` passed.
- [x] new P13 real identity-adoption regressions pass (`tests/pnc_core_player_identity_adoption_smoke.lua`).
- [x] new P14 production conversation isolation regressions pass (`tests/psychopatz_conversation_capability_isolation_smoke.lua`).
- [x] new P15 grounded DT semantics and strict hot-plug matrix pass (`tests/pnc_real_cross_adopter_hotplug_matrix_smoke.lua`, `tests/dt_standalone_semantic_story_smoke.lua`).
- [x] final repository revisions/status and preserved pre-existing DT edit are recorded accurately.

## User-owned native handoff

All developer gates have completed. The system is ready for user-owned native Project Zomboid SP/MP testing covering:
1. DT-only save creation and trader conversations (trade, identity, whereabouts, stories).
2. Enabling Project Hoomans on existing save (validating exact player identity adoption and social continuity).
3. Disabling Project Hoomans and continuing DT trading.
4. Re-enabling Project Hoomans and verifying extension recovery.
5. Reversing the install order (Hoomans-only -> add DT -> remove DT -> re-add DT).
