# Progress — Core Semantic & Relationship Foundation

**State:** IN PROGRESS — third independent audit invalidated two P13-P15 completion claims.

## Current repository snapshot at third audit

- `psychopatzCore`: `main @ 092c72d`, 9 commits ahead of `origin/main`, clean.
- `DynamicTrading`: `main @ 80dd24fd`, 7 commits ahead, with the preserved tracked local edit in `DTHoomans_Conversation.lua`.
- `ProjectHoomans`: `main @ 4cf29f8c`, 15 commits ahead, clean.

Recheck before every write.

## Independently retained accepted work

- P8B non-destructive shared-social merging remains accepted.
- P9 pack lifecycle/unregister behavior remains accepted.
- P10 Hoomans semantic schema/gates remain accepted.
- **P14 is accepted:** real DT + Hoomans packs loaded together through `PsychopatzActorConversationService` correctly isolate grammar by effective capabilities.
- **P15 parser coverage is accepted:** required DT utterance families now parse, including trader/settlement/route/news/story/farewell.
- P15 no-evidence behavior is accepted: destination/news return bounded uncertainty/no-news rather than fabricated current facts.
- Generic route WorldKnowledge can be genuinely grounded: an acquired `market.route` fact produced a route answer with a real fact ID.
- Dynamic Trading full suite: `43/43`.
- Project Hoomans broad suite: `982/987`; the same five documented older failures remain.
- Focused corrective suites pass.
- Changed Lua syntax and `git diff --check` passed at the third audit.

## Acceptance-invalidating findings

### 1. P13 provenance is forgeable and therefore not authoritative issuance proof

Current Core `SignProvenance(uuid, accountKey)` is a public deterministic hash. All verification inputs and the computed signature live in player modData.

Independent adversarial reproduction:

- invent `char_forged_unknown_999`;
- set `PNC_CharacterUUID`, `Core_CharacterUUID`, and `Core_CharacterAccountKey`;
- compute the public `Core_CharacterSignature = SignProvenance(uuid, account)`;
- real `VerifyProvenance` returns `true, valid_provenance`;
- real `PNC.PlayerCharacters.EnsureIdentity` returns the forged UUID with `core_adopted`.

Therefore the implementation fixes normal DT-first handoff but does not distinguish "Core actually issued this identity" from "modData contains a reproducible hash".

P16 must move trust to Core-authoritative persistent issuance/adoption state.

### 2. P15 factual destination/origin/settlement grounding is not fully end-to-end

The old hardcoded southern-outpost/central-market response is removed and required parser coverage is complete.

However, the final grounding tests currently prove destination/origin/settlement by passing values directly into `TalkService.Submit` options such as:

- `destination = "West Point Outpost"`;
- `origin = "March Ridge Depot"`;
- `settlement = "Riverside Safehouse"`;
- hand-built `npcGossip`.

No production caller was found supplying those answer fields.

Independent real WorldKnowledge probe:

- publish/acquire an actual `market.route` fact for `route:rosewood`;
- `what route` returns the grounded statement and real fact ID;
- `where are you heading` still returns bounded uncertainty with no evidence because no canonical destination/next-settlement state is populated.

Therefore P15's rendering is good, but P17 must wire factual destination/origin/settlement/news through real upstream DT/Core production state.

## Acceptance status

- P8B: ACCEPTED.
- P9 lifecycle: ACCEPTED.
- P10: ACCEPTED.
- P14: ACCEPTED.
- P15 parser coverage / uncertainty / generic route grounding: ACCEPTED.
- P13 identity handoff functionality: PARTIAL; trust claim REVOKED pending P16.
- P15 factual destination/origin/settlement end-to-end grounding: PARTIAL pending P17.
- final developer acceptance: REVOKED pending P16-P17.

## Current phase

**P16 — Core-authoritative player identity issuance and adoption.**

### Next Chunk — P16A

Replace the trust root without breaking the working UUID/key handoff.

Required starting work:

1. inspect Core identity persistence/storage facilities and choose the smallest durable authoritative issuance registry;
2. record Core-generated identities and account/slot binding there;
3. provide a Core verification API that answers whether a UUID/account pair is actually issued/adopted;
4. make Hoomans `canAdoptCoreIdentity` depend on that authority;
5. keep modData signature/mirrors only as lookup/integrity hints if useful;
6. add the forged-valid-signature adversarial test that currently succeeds;
7. preserve DT-first SP/MP, reconnect, cross-account rejection, Hoomans-first adoption, persistence, and idempotence.

P16A gate: a forged well-formed modData claim cannot become `core_adopted`, while a genuinely Core-issued DT-first UUID still does.

After P16 acceptance, continue automatically through P17.

## Parent goal status

**IN PROGRESS.**

Do not return to READY FOR USER LIVE TEST until P16-P17 pass through real production owner paths.
