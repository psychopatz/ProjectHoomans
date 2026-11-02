# Progress — Core Semantic & Relationship Foundation

**State:** IN PROGRESS — second production-path audit invalidated the P8-P12 READY FOR USER LIVE TEST closeout.

## Current repository snapshot at second audit

- `psychopatzCore`: `main @ bc1f7a8`, 7 commits ahead of `origin/main`, clean.
- `DynamicTrading`: `main @ 03318881`, 5 commits ahead, with the preserved tracked local edit in `DTHoomans_Conversation.lua`.
- `ProjectHoomans`: `main @ e78f4fb6`, 11 commits ahead, clean.

Recheck before every write; these are audit observations, not permanent assumptions.

## Retained accepted work

- **P8B:** non-destructive Core-first social synchronization materially fixes the previous stale Hoomans overwrite. Independent adversarial tests preserve DT memories/extensions and newer shared approval.
- **P9 registry lifecycle:** semantic pack ownership/unregister/re-register works at registry/direct-parser level.
- **P10:** Hoomans Core semantic schema/gates are repaired. With correct `hoomans.*` capabilities, `follow me`, `make camp`, `how are you`, `join me`, and wellbeing relationship gates behave correctly.
- Goal-caused Hoomans composition bootstrap regression is fixed.
- Dynamic Trading full runner independently passed `43/43`.
- Hoomans broad runner independently reached `981/986`; the same five older failures remain:
  - `pnc_companion_commands_smoke.lua`
  - `pnc_semantic_harness_worker_modules_smoke.lua`
  - `pnc_semantic_horde_command_ack_smoke.lua`
  - `pnc_semantic_horde_tactical_prompt_smoke.lua`
  - `pnc_semantic_local_route_smoke.lua`
- Changed corrective Lua passed `luac5.3 -p`; all repos passed `git diff --check`.

## Acceptance-invalidating findings from second audit

### 1. P8A fails through the real Hoomans identity service

Direct reproduction of DT-first -> add Hoomans:

- Core/DT player identity generated `char_2156615e6cce35c487a58fea`.
- Canonical DT/Core key: `player:sp_slot_7:char_2156615e6cce35c487a58fea`.
- Later `PNC.PlayerCharacters.EnsureIdentity` rejected that mirrored UUID as `unknown_uuid` because it was absent from the Hoomans player-character registry.
- Hoomans generated `char_367200000_7`.
- Hoomans key became `player:sp_slot_7:char_367200000_7`.

Result: `SAME_UUID=false`, `SAME_KEY=false`.

The previous P8A test manually formatted the expected Hoomans key instead of calling the real Hoomans identity service. P12 likewise bypassed this boundary.

### 2. P9 capability isolation fails in production conversation orchestration

Registry/direct-parser gating works, but `PsychopatzActorConversationService:Submit` computes `effectiveContext` and then calls `ParseTurn(text, options)` without propagating `effectiveContext.capabilities`.

Independent reproduction with both packs registered:

- conversation capabilities: only `core.conversation` + `dynamictrading.trade`;
- input: `follow me`;
- production ActorConversationService result: Hoomans `COMMAND / COMMAND`.

Actions remained DT-only, but semantic understanding leaked across adopter capability boundaries.

### 3. P11 is partial and factual whereabouts are currently hardcoded

Working direct parser examples include:

- `who are you`;
- `who handles trading`;
- `where are you heading`;
- `where did you come from`;
- buy/sell/trade.

Still unmatched in independent audit:

- `where is the trader`;
- `where is the settlement`;
- `what settlement are you going to`;
- `road news`;
- `tell me a caravan story`;
- `goodbye`.

The current TalkService whereabouts response returns a static authored sentence about a "southern outpost" and "central market" before using real `DTCommon.WorldKnowledge` evidence. The P11 test asserts that static sentence. This does not satisfy evidence-grounded whereabouts/route/settlement requirements.

### 4. P12 is still a false-positive final matrix

`pnc_real_cross_adopter_hotplug_matrix_smoke.lua` loads several real modules and does valuable interleaved relationship testing, but it:

- manually constructs player objects/keys through Core;
- does not invoke real Hoomans `PNC.PlayerCharacters.EnsureIdentity/GetEntityKey` for the DT-first player;
- does not exercise production ActorConversationService capability isolation with both packs installed;
- does not verify factual DT whereabouts/news provenance.

Therefore P12 cannot currently close the parent goal.

## Acceptance status

- P8B: **ACCEPTED / retain**.
- P9 pack ownership/unregister lifecycle: **ACCEPTED / retain**.
- P10 Hoomans semantic schema/gates: **ACCEPTED / retain**.
- P8A: **REVOKED** pending P13.
- P9 production conversation capability isolation: **REVOKED/PARTIAL** pending P14.
- P11: **PARTIAL** pending P15.
- P12/final developer acceptance: **REVOKED** pending P15.

## Current phase

**P13 — Trusted DT-first player identity adoption into Hoomans.**

### Next Chunk — P13A

Use the real production identity services to implement a safe trust/adoption bridge.

Required starting work:

1. recheck all three repository statuses and preserve the existing Dynamic Trading local edit;
2. inspect Core `PsychopatzPlayerIdentity` provenance/persistence and Hoomans `PlayerCharacterService.ValidateClaim/EnsureIdentity`;
3. define how Hoomans can distinguish a trusted Core-issued UUID from an arbitrary untrusted `PNC_CharacterUUID` claim;
4. adopt/import the trusted Core UUID into Hoomans' registry without generating a replacement;
5. preserve all current Hoomans safeguards for malformed, dead, retired, cross-account and duplicate-live-binding claims;
6. add real SP and MP DT-first -> Hoomans tests that call `PNC.PlayerCharacters.EnsureIdentity` and `GetEntityKey`;
7. add idempotence and already-forked alias-convergence coverage.

P13A gate: exact same UUID and target key before and after enabling Hoomans through the actual Hoomans player-character service.

After P13 acceptance, continue automatically through P14 and P15.

## Parent goal status

**IN PROGRESS.**

Do not return to READY FOR USER LIVE TEST until P13-P15 pass with production-path evidence.
