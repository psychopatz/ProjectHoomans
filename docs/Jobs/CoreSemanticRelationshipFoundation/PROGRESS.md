# Progress — Core Semantic & Relationship Foundation

**State:** IN PROGRESS — fourth production-path audit invalidated the P16-P17 READY FOR USER LIVE TEST closeout.

## Current repository snapshot at fourth audit

- `psychopatzCore`: `main @ 241cd47`, 10 commits ahead of `origin/main`, clean.
- `DynamicTrading`: `main @ 4131fbe9`, 8 commits ahead, with the preserved tracked modification in `Contents/mods/DTHoomans/42.20/media/lua/shared/DTHoomans/DTHoomans_Conversation.lua`.
- `ProjectHoomans`: `main @ 359ba483`, 19 commits ahead, clean.

Recheck actual state before every write.

## Retained accepted work

- P8B non-destructive Core-first social merging.
- P9 semantic pack ownership/unregister lifecycle.
- P10 Hoomans Core semantic schema/gates.
- P14 production conversation capability isolation.
- Complete required DT parser coverage.
- Bounded uncertainty/no-news when factual evidence is absent.
- Real route/road-news WorldKnowledge grounding with fact IDs.
- P16 Core issuance registry, account binding, save/load API and normal DT-first adoption flow.
- P17 canonical DT home/current/origin/destination policy fields/setters and TalkService policy consumption.
- Dynamic Trading full runner: `43/43`.
- Hoomans broad runner: `982/987`; the same five documented older baseline failures remain.
- Focused P16/P17 tests pass.
- Changed P16/P17 Lua syntax and repository diff checks pass.

## Acceptance-invalidating findings from fourth audit

### 1. Unknown PNC mirrors can still bootstrap themselves into Core authority

Current `PsychopatzPlayerIdentity.GetCharacterUUID` has a fallback for an existing `PNC_CharacterUUID` that writes Core mirror fields and calls:

`RegisterIssuedIdentity(pncUUID, accountKey, { source = "hoom_adopted" })`.

Independent production-order reproduction:

1. Core issuance registry reset.
2. Player modData contains only `PNC_CharacterUUID = char_forged_bootstrap_123`.
3. Before Core lookup: `IsIssuedIdentity = false / not_issued`.
4. DT/Core calls `PlayerIdentity.GetTargetKey(player)`.
5. After lookup: `IsIssuedIdentity = true / source=hoom_adopted`.
6. Real Hoomans `EnsureIdentity` then returns the forged UUID with `core_adopted`.

Therefore P16's registry is useful but the trust root is still bypassable by call order.

The current adversarial tests call Hoomans before this Core mirror-registration path and do not detect the bypass.

### 2. Destination/origin APIs are not yet wired to the actual travel owner

P17 added valid policy/service APIs and TalkService reads them.

Production callsite audit found:

- Hoomans settlement binding uses `SetHomeSettlement`.
- Hoomans resident excursion uses `SetCurrentSettlement`.
- No production runtime caller currently invokes `SetDestinationSettlement` or `SetOriginSettlement`.

The actual `DTHoomans_ResidentExcursion` payload already knows the selected destination community and lifecycle states, but does not project those transitions into the new canonical policy fields.

Current tests call `Policy.SetDestinationSettlement/SetOriginSettlement` directly on a test record. This proves the API/TalkService seam, not live gameplay integration.

### 3. Canonical Hoomans community IDs can leak into player-facing dialogue

Hoomans communities have separate stable `community.id` and human `community.name`.

The bridge stores `community.id` as DT settlement identity, while TalkService currently concatenates the policy value directly into text.

Actual community IDs are generated machine identifiers such as `community_<timestamp>_<random>`. P17 tests hide this by using friendly strings like `"Riverside Safehouse"` directly as settlement IDs.

A presentation resolver is required so canonical IDs remain stable while dialogue emits the known human-facing settlement name.

### 4. Factual-state reload acceptance is claimed but not tested

P17 tests set destination/origin/current state and query immediately.

The final matrix does not persist/reload the new factual trader policy/world-knowledge state after seeding it and then re-query TalkService.

The current DT storage design likely persists `record.ca`, but the acceptance claim remains unverified.

## Acceptance status

- P8B/P9/P10/P14: ACCEPTED.
- P15 parser coverage/uncertainty/route-news grounding: ACCEPTED.
- P16 issuance registry foundation: ACCEPTED.
- P16 authority bootstrapping safety: REVOKED pending P18.
- P17 policy APIs/TalkService consumption: ACCEPTED.
- P17 live travel origin/destination wiring: PARTIAL pending P19.
- P17 settlement presentation: NOT ACCEPTED pending P19.
- P17 factual-state reload: UNVERIFIED pending P19.
- final developer acceptance: REVOKED.

## Current phase

**P18 — Prevent mirror-to-authority identity bootstrapping.**

### Next Chunk — P18A

Start with the exact vulnerable ordering.

1. recheck all repository statuses and preserve the Dynamic Trading local edit;
2. inspect `PsychopatzPlayerIdentity.GetCharacterUUID/GetTargetKey` and remove implicit issuance registration from unknown PNC mirrors;
3. keep Core-issued mirrors working;
4. route legitimate Hoomans-first registration through the validated Hoomans player-character registry/service after Hoomans accepts/creates the identity;
5. add the adversarial sequence:
   - unknown PNC mirror;
   - Core `GetTargetKey` first;
   - assert still `not_issued`;
   - Hoomans `EnsureIdentity`;
   - assert forged UUID not adopted;
6. retain DT-first/Hoomans-first exact UUID/key convergence, persistence and alias idempotence.

P18A gate: lookup order can never manufacture identity authority.

After P18 acceptance, continue automatically through P19.

## Parent goal status

**IN PROGRESS.**

Do not return to READY FOR USER LIVE TEST until P18-P19 pass through real identity and travel owner paths.
