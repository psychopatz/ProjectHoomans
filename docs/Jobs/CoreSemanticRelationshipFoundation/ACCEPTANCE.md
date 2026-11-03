# Acceptance — Core Semantic & Relationship Foundation

**Developer status:** COMPLETE — READY FOR USER LIVE TEST.

Native Project Zomboid SP/MP acceptance remains user-owned and has not been claimed by the developer test harness.

## Developer acceptance

### Canonical identity and relationships

- [x] Core owns canonical actor/player social identity and persistent issuance state.
- [x] unknown `PNC_CharacterUUID` mirrors cannot bootstrap Core authority.
- [x] DT-first and Hoomans-first identity adoption preserve the same UUID/key.
- [x] cross-account/repeat-adoption protections remain intact.
- [x] DT/Hoomans interleaved social writes preserve foreign extensions, memories, and newer shared state.
- [x] alias convergence and repeated synchronization are idempotent.

### Semantic lifecycle and adopter isolation

- [x] semantic-pack ownership/unregister/re-register is residue-free.
- [x] production `ActorConversationService` propagates effective capabilities into parsing.
- [x] DT-only conversations reject Hoomans-only grammar.
- [x] Hoomans-only conversations reject DT-only grammar.
- [x] compound turns preserve capability isolation.
- [x] required standalone DT identity/trade/whereabouts/news/story/farewell parser coverage is complete.
- [x] CodeBuilder-generated shared semantic assets follow canonical package ownership: Core-owned lexicon/common parser modules generate into PsychopatzCore and are not duplicated under Hoomans.

### Factual travel dialogue and presentation

- [x] canonical home/current/origin/destination state is owned by DT policy.
- [x] production excursion lifecycle updates travel state.
- [x] route/news WorldKnowledge facts produce evidence-backed responses.
- [x] missing evidence produces bounded uncertainty/no-news.
- [x] canonical machine settlement/community IDs resolve to human-facing names.
- [x] unresolved machine IDs do not leak into dialogue.
- [x] FAILED before departure restores coherent home state.
- [x] FAILED after departure with numeric `completedAt = 0` does not fabricate home/availability.
- [x] FAILED while visiting/returning preserves coherent authoritative travel facts.
- [x] retry after failure does not inherit stale destination/origin state.

### Persistence and hot-plug behavior

- [x] WorldKnowledge real `Save/Load` path preserves fact/evidence data.
- [x] trader-record headless reload reconstructs from a deep-copied persisted snapshot/fresh backing table.
- [x] reloaded trader record is a distinct Lua object from the pre-save record.
- [x] reconstructed reload preserves factual policy and human-facing presentation.
- [x] completed/failed travel cleanup remains coherent after reload.
- [x] production hot-plug matrix covers real identity service, interleaved social writes, capability isolation, pack lifecycle, travel state, and migration idempotence.

### Performance and validation

- [x] no global per-tick semantic scan was introduced.
- [x] no periodic full relationship reconciliation was introduced.
- [x] identity/travel/presentation work remains bounded to explicit lifecycle/load/conversation boundaries.
- [x] Core focused identity/social/conversation/semantic checks pass.
- [x] Dynamic Trading full runner passes `43/43`.
- [x] Hoomans full runner remains `982/987` with the same five documented pre-existing baseline failures.
- [x] changed P20 Lua passes `luac5.3 -p`.
- [x] all three repositories pass `git diff --check`.
- [x] final repository revisions/worktree state are recorded in `PROGRESS.md`.

## Known baseline failures outside this parent goal

- `pnc_companion_commands_smoke.lua`
- `pnc_semantic_harness_worker_modules_smoke.lua`
- `pnc_semantic_horde_command_ack_smoke.lua`
- `pnc_semantic_horde_tactical_prompt_smoke.lua`
- `pnc_semantic_local_route_smoke.lua`

These remain classified as pre-existing/unrelated baseline failures based on the completed audits.

## User-owned native acceptance

- [ ] native SP Core + DT behavior;
- [ ] native MP Core + DT behavior;
- [ ] combined DT + Hoomans identity/relationship continuity;
- [ ] add/remove/re-add adopter behavior across real saves/restarts;
- [ ] excursion departure/visit/return/failure/retry in the native runtime;
- [ ] human-readable settlement/location dialogue in live gameplay;
- [ ] real UI/dialogue quality and multiplayer lifecycle acceptance.

Native acceptance is the next step. No Steam Workshop publication is implied.
