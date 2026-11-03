# Roadmap — Core Semantic & Relationship Foundation

**Status:** IN PROGRESS — P0-P19 implementation exists. A fifth production-path audit accepted P18 and most P19 behavior but reproduced a FAILED-after-departure lifecycle defect and found the trader-record reload proof still reuses the same backing Lua table. P20 is the mandatory final correction.

The parent goal completion boundary is now the complete P0-P20 outcome. Preserve accepted P0-P19 implementation; P20 repairs only the remaining failure-state and persistence-evidence gaps reproduced after the P19 closeout.

After every accepted chunk: implement -> validate actual production owners -> update PROGRESS -> commit coherent owner-repository changes -> continue automatically to the next mandatory chunk.

## P0-P7 — Existing implementation foundation

The original P0-P7 scope remains authoritative for intended ownership and product behavior:

- P0: convergence audit/public contracts;
- P1: Core canonical shared relationship authority;
- P2: generic Core semantic/conversation foundation;
- P3: standalone Dynamic Trading semantic/story pack;
- P4: Project Hoomans additive adopter;
- P5: cross-adopter boundary/capability isolation;
- P6: hot-plug/save migration/removal;
- P7: final developer acceptance.

Independent verification after the first P7 closeout found that P1, P3, P4, P5, P6 and P7 were not fully accepted. Do not delete their existing implementation; repair the concrete gaps below.

## P8 — Canonical player identity and Core-first relationship authority

### P8A — One canonical player social target key

Audit current Core/PZ/Hoomans player identity persistence and implement a Core-owned target-key resolver usable without Project Hoomans.

Requirements:

- same player character -> same Core Social target key in DT-only, Hoomans-only and combined modes;
- SP and MP fixtures;
- no transient online-ID relationship identity;
- username/account alone must not silently collapse distinct persistent characters if the existing Hoomans character model distinguishes them;
- migration/alias support for legacy DT `player:online:*`, `player:user:*` and existing Hoomans player-character keys;
- migration is one-time/idempotent and merges rather than forks relationship state;
- DT pricing, trade events and TalkService context use this resolver;
- Hoomans relationship/social event paths use the same canonical contract.

Gate: no duplicate relationship entries for the same player character across adopters or install orders.

### P8B — Non-destructive Core-first writes

Core is the mutation authority, not a mirror of Hoomans `record.social`.

Requirements:

- add/use bounded Core APIs for relationship/event/extension updates against the latest Core actor/social revision;
- preserve all foreign adopter extensions, memories and newer shared fields;
- stale writes conflict/retry/merge explicitly rather than replacing the whole social table;
- Hoomans compatibility state is refreshed/projected from Core after accepted mutations;
- synchronization failures are not swallowed by best-effort `pcall` where loss of social truth is possible;
- no adopter commits another adopter's extension payload.

Mandatory regressions:

1. DT trade -> Hoomans social mutation -> DT memory/extension remain intact.
2. Hoomans social mutation -> DT trade -> Hoomans extension/shared changes remain intact.
3. stale Hoomans projection cannot erase newer Core data.
4. two target aliases converging to one canonical player key merge once without double-applying events.

Gate: Core is observably canonical under interleaved DT/Hoomans writes.

## P9 — Complete semantic pack ownership, lifecycle and capability isolation

Repair the generic Core pack contract rather than adding adopter-specific exceptions.

Requirements:

- registration records ownership for concepts, speech acts, patterns, context resolvers, flavors, dialogue blocks and action providers;
- unregister removes/reverts every registration owned by that pack without damaging another pack;
- duplicate/re-register behavior is deterministic;
- pack-level `capabilitiesRequired` is enforced for relevant parsing/dialogue/action surfaces, or pack activation itself is capability-scoped by a clearly tested equivalent contract;
- dialogue blocks cannot leak from inactive/missing adopters;
- parser candidates from an inactive/unregistered adopter cannot remain globally active;
- action-provider strict capability behavior remains intact;
- diagnostics show active owner/pack/capability state.

Mandatory adversarial tests:

- unregister DT pack -> `trade` no longer resolves through DT-owned grammar;
- no DT capability -> DT dialogue blocks are not selectable;
- no Hoomans capability -> Hoomans pack content/actions are absent;
- unregister one pack -> other packs remain intact.

Gate: a semantic pack can be installed, activated, deactivated and removed without semantic residue.

## P10 — Repair Project Hoomans additive adopter

Use the actual Core semantic contracts; do not invent a parallel schema.

Requirements:

- concepts use the Core registry's supported alias vocabulary contract;
- patterns match actual Core matcher rule semantics, including multi-word phrases;
- dialogue blocks use the Core `gates / entryNode / nodes / choices / outcomes` contract or a deliberately supported adapter that converts Hoomans-authored blocks losslessly;
- relationship gates use canonical Core relationship context;
- Hoomans-only gameplay actions remain Hoomans-owned/server-authoritative;
- production Hoomans paths actually consume the Core-registered content/actions where claimed;
- avoid duplicating already-authoritative Hoomans semantic flows merely to satisfy a smoke test;
- Semantic Lab remains able to observe the real production pipeline;
- update composition contract tests for the intentional new module order.

Mandatory tests assert actual behavior, not only registration:

- friendly/neutral/wary relationship gating;
- `follow me`, camp/recruit/wellbeing examples parse as intended where Core participation is expected;
- selected Core-backed Hoomans block has usable text/node content;
- DT-only actors never receive Hoomans content/actions;
- production selector/action surfaces consume the registered pack.

Gate: Project Hoomans is an additive, working Core semantic/social adopter rather than a registered-but-unused/broken pack.

## P11 — Finish standalone Dynamic Trading semantic/story coverage

Preserve the already working standalone DT greeting/trade/rumor foundation and complete the original mandatory P3 surface.

Requirements:

- trader/guard identity and role questions;
- trade/referral semantics;
- trader/settlement whereabouts and direction/route facts where DT has evidence;
- caravan/journey/commercial stories and rumors;
- relationship-aware variants;
- farewell/greeting;
- radio and physical talk contexts where applicable;
- use DT world-knowledge/fact services instead of fabricated Hoomans data;
- zero Project Hoomans dependency in Core + DTCommon + DTAbstract mode.

Mandatory utterance coverage includes real variants for:

- who are you / who handles trading;
- where are you heading;
- where did you come from;
- where is the trader / settlement where evidence exists;
- road news / caravan story;
- trade/buy/sell;
- greeting/farewell.

Gate: these produce meaningful bounded semantics/responses in a standalone DT configuration.

## P12 — Real adopter hot-plug acceptance and final developer re-close

The existing `psychopatz_hotplug_save_matrix_smoke.lua` remains useful only as a low-level Core serialization test. It is not sufficient for this gate.

Build a real cross-repository integration matrix that loads and exercises production adopter modules.

Mandatory sequence:

1. Core + DT create actor/relationship through production DT paths.
2. Save/reload.
3. Add Hoomans production adapters.
4. Verify actor identity and canonical player target key are unchanged.
5. Exercise a Hoomans relationship mutation.
6. Verify prior DT memories/extensions survive.
7. Exercise another DT trade.
8. Verify Hoomans extension/shared changes survive.
9. Remove Hoomans and reload through Core + DT production paths.
10. Verify DT talk/trade/social data still works and Hoomans extension remains dormant/preserved.
11. Re-add Hoomans and verify exact extension recovery.
12. Repeat the reverse Hoomans-first -> add DT -> remove/re-add DT sequence.
13. Repeat migrations/reloads to prove idempotence.
14. Exercise conflict/quarantine behavior without destructive reset.
15. Prove semantic pack activation/removal leaves no cross-adopter residue.

Final validation:

- Core focused Social/Actors/Semantics suites;
- Dynamic Trading full suite;
- Hoomans focused and broad suites;
- classify unrelated pre-existing Hoomans failures against a baseline rather than silently broadening scope;
- fix every failure introduced by this goal, including composition bootstrap expectations;
- changed Lua syntax/static/Kahlua checks where tooling exists;
- `git diff --check`;
- performance/bounded-work review;
- exact repository revisions/status recorded;
- no unauthorized native PZ launch or Workshop publication.

Historical P12 closeout gate: superseded by the second production-path audit. P13-P15 are now mandatory before **READY FOR USER LIVE TEST**.



## P13 — Trusted DT-first player identity adoption into Hoomans

### P13A — Real production identity convergence

Fix the actual optional-adopter identity handoff.

Verified failure to reproduce before implementation:

1. Core + Dynamic Trading resolves a player with no existing Hoomans registry.
2. Core `PlayerIdentity.GetTargetKey` generates/persists a canonical `Core_CharacterUUID` / mirrored `PNC_CharacterUUID`.
3. Project Hoomans is enabled later.
4. `PNC.PlayerCharacters.EnsureIdentity` sees the UUID but `ValidateClaim` returns `unknown_uuid`.
5. Hoomans generates a different UUID and therefore a different relationship target key.

Requirements:

- define an explicit trusted-Core-issued identity adoption path in Hoomans;
- do not weaken rejection of arbitrary unknown UUID claims;
- validate account/slot ownership before import;
- import/create the Hoomans registry record once using the exact existing Core UUID;
- preserve Hoomans dead/retired/cross-account/duplicate-live-binding protections;
- keep `Core_CharacterUUID` and `PNC_CharacterUUID` mirrors consistent;
- migrate/alias any already-forked relationship keys without duplicate event application;
- SP and MP fixtures must call real production `PNC.PlayerCharacters.EnsureIdentity` and `GetEntityKey`.

Mandatory adversarial tests:

- DT-first SP -> add Hoomans -> exact same UUID and target key;
- DT-first MP -> add Hoomans -> exact same UUID and target key;
- reconnect/online-ID change -> unchanged key;
- arbitrary `char_untrusted` claim without trusted Core provenance -> still rejected;
- cross-account trusted-looking claim -> rejected;
- repeated Hoomans enable/load -> idempotent registry adoption.

Gate: the actual Hoomans player-character service adopts canonical Core identity without replacement.

## P14 — Production conversation capability isolation

### P14A — Propagate effective context capabilities into parsing

Verified failure:

- DT and Hoomans packs are both globally registered;
- a conversation has only `core.conversation` + Dynamic Trading capabilities;
- `PsychopatzActorConversationService:Submit("follow me", context, options)` parses Hoomans `COMMAND` because `effectiveContext.capabilities` is not forwarded to `ParseTurn`.

Requirements:

- Core conversation orchestration passes effective capabilities into every parser/candidate path;
- caller options cannot accidentally erase stricter effective capability context;
- compound turns preserve the same capability boundary;
- direct `Semantics.Parse`, `DialogueRouter`, preview/process, and ActorConversationService behavior remain consistent;
- action/dialogue gating stays unchanged except where needed for one coherent capability contract;
- no adopter-specific hardcoding in Core.

Mandatory tests:

- both packs registered + DT-only conversation + `follow me` -> no Hoomans semantic match;
- both packs registered + Hoomans capabilities + `follow me` -> Hoomans command match;
- Hoomans-only conversation + `trade` -> no DT grammar unless DT capability is present;
- compound utterance cannot smuggle an ineligible adopter clause;
- unregister/re-register lifecycle remains residue-free.

Gate: installed-but-ineligible semantic packs cannot influence production conversation parsing.

## P15 — Grounded DT story/whereabouts completion and true final matrix

### P15A — Complete standalone DT utterance coverage

Retain working identity/trade parsing, but cover the originally mandated surface behaviorally.

Required representative families include:

- who are you / who handles trading;
- where are you heading / where did you come from;
- where is the trader;
- where is the settlement / what settlement are you going to;
- route/direction questions where DT has evidence;
- road news;
- caravan/commercial story;
- buy/sell/trade;
- greeting/farewell/goodbye.

### P15B — Ground factual responses in DT/Core world knowledge

For factual origin/destination/settlement/trader-location/route/news claims:

- use `DTCommon.WorldKnowledge` / canonical DT state;
- propagate fact provenance/context into response planning;
- prefer exact known settlement/route/direction when evidence exists;
- return bounded uncertainty/no-news when evidence does not exist;
- do not satisfy the gate with static fiction such as a hardcoded "southern outpost" / "central market" route.

Authored generic flavor remains allowed when it is clearly not presented as a factual current-location claim.

### P15C — Replace the false-positive final hot-plug matrix

Upgrade `pnc_real_cross_adopter_hotplug_matrix_smoke.lua` or replace it with a stricter production integration test.

It must:

1. create DT/Core player identity through the production Core resolver;
2. add Hoomans and call the real `PNC.PlayerCharacters.EnsureIdentity/GetEntityKey`;
3. verify UUID/key equality before any relationship assertions;
4. perform the accepted P8B interleaved DT/Hoomans write sequence;
5. exercise production `ActorConversationService:Submit` with both packs installed and different capability sets;
6. verify Hoomans grammar cannot leak into DT-only conversations and vice versa;
7. exercise DT factual whereabouts/news responses with seeded world-knowledge evidence and with no evidence;
8. remove/re-add packs/adopters and prove identity, relationships, extensions, memories, parser isolation and factual state remain correct;
9. repeat load/migration to prove idempotence.

Final validation:

- Core focused identity/social/semantics/conversation tests;
- Dynamic Trading full runner (second-audit baseline: 43/43);
- Hoomans focused tests and broad runner (second-audit baseline: 981/986 with the same five pre-existing failures);
- every goal-introduced failure fixed;
- changed Lua syntax/static/Kahlua checks where tooling exists;
- `git diff --check`;
- exact repository revisions/status and preserved DT local edit reported.

Historical P15 closeout gate: superseded by the third independent audit. P16-P17 are now mandatory before **READY FOR USER LIVE TEST**.


## P16 — Core-authoritative player identity issuance and adoption

### P16A — Replace forgeable provenance with authoritative issuance state

Retain the working DT-first UUID/key adoption flow, but replace its trust decision.

Verified third-audit failure:

- Core exposes public `SignProvenance(uuid, accountKey)`;
- the signature is a deterministic hash with no secret or authoritative issuance lookup;
- an arbitrary unknown UUID can be placed into player modData;
- the public signature can be computed for it;
- `VerifyProvenance` returns `valid_provenance`;
- real `PNC.PlayerCharacters.EnsureIdentity` accepts it as `core_adopted`.

Therefore the current mechanism proves self-consistency of modData, not actual Core issuance.

Requirements:

- Core owns persistent authoritative player-identity issuance/adoption state;
- provide a bounded API such as `IsIssuedIdentity(uuid, accountKey)` / `ResolveIssuedIdentity` or equivalent;
- generating a Core player identity records it authoritatively;
- adopting an existing Hoomans-first identity records/links it authoritatively without changing its UUID;
- Hoomans DT-first adoption checks the authoritative Core record, not only player modData;
- player modData mirrors remain useful for lookup/recovery but are not the trust root;
- arbitrary forged UUID + correctly computed public hash remains rejected;
- cross-account, retired/dead, malformed, and duplicate-live-binding cases remain rejected;
- persistence/save/reload keeps issuance records;
- migration from already-created P13 identities is bounded and idempotent.

Mandatory tests:

1. real DT-first SP identity -> authoritative record exists -> Hoomans adopts exact UUID/key;
2. real DT-first MP identity -> same;
3. arbitrary unknown UUID + forged public signature -> real Hoomans service rejects adoption;
4. cross-account reuse -> rejected;
5. save/reload Core issuance state -> identity still adoptable;
6. Hoomans-first identity -> Core registers/adopts same UUID without fork;
7. repeated import/adoption -> idempotent;
8. legacy already-forked aliases still converge without duplicate social events.

Gate: Hoomans can distinguish "Core actually issued/adopted this identity" from "modData merely contains a reproducible hash".

## P17 — Production-derived DT factual route/destination grounding and final re-close

### P17A — Define canonical DT route/destination fact ownership

Retain P15 parser coverage and bounded uncertainty.

Establish the production owner/path for factual:

- current settlement;
- origin/last settlement;
- destination/next settlement;
- active route/direction;
- trader location;
- road news.

Use existing DT policy/world-knowledge mechanisms where possible rather than inventing a parallel dialogue-only store.

If destination/next-settlement does not currently exist in standalone DT policy, add the smallest canonical field/service or typed WorldKnowledge fact required by actual gameplay.

### P17B — TalkService consumes upstream production evidence

Requirements:

- gameplay/DT services publish or update route/destination/origin/settlement state before conversation;
- `TalkService.Submit` builds context from that production state;
- tests must not need `options.destination`, `options.origin`, `options.settlement`, or hand-built `options.npcGossip` to prove final grounding;
- direct option injection may remain supported for bounded unit tests/debugging, but is not the canonical production evidence path;
- factual replies include inspectable evidence/fact refs where the source is WorldKnowledge;
- no evidence -> bounded uncertainty/no-news;
- generic authored caravan stories remain allowed as clearly non-current fiction/flavor.

Mandatory end-to-end tests:

1. publish/set a destination through the canonical DT production API -> ask `where are you heading` with no answer injection -> exact grounded destination/evidence;
2. set/persist origin/last settlement through production state -> ask `where did you come from` -> grounded answer;
3. set current/home settlement -> ask `where is the settlement` -> grounded answer;
4. publish/acquire a real route WorldKnowledge fact -> `what route` returns the fact and fact ID;
5. publish/acquire road-news fact -> `road news` returns fact-backed statement and fact ID;
6. no destination/news evidence -> uncertainty/no-news, never fabricated location;
7. save/reload DT state -> factual answers remain grounded.

### P17C — Final production matrix and documentation reconciliation

Upgrade the final cross-adopter matrix so it proves both P16 and P17 through real owner paths:

- DT-first identity created through Core authoritative issuance;
- real Hoomans EnsureIdentity adopts it;
- forged well-formed unknown identity is rejected;
- P8B interleaved social writes still preserve both adopters;
- P14 capability isolation remains green through ActorConversationService;
- DT destination/origin/settlement/route/news are seeded through canonical production APIs, not Submit answer options;
- remove/re-add adopters/packs preserves identity, relationships, extensions, semantic isolation, and factual state;
- migrations/reloads remain idempotent.

Final validation:

- Core focused identity/social/semantics/conversation suites;
- Dynamic Trading full runner (third-audit baseline: 43/43);
- Hoomans focused corrective tests;
- Hoomans broad runner (third-audit baseline: 982/987 with the same five pre-existing failures);
- changed Lua syntax/Kahlua/static checks where tooling exists;
- `git diff --check`;
- exact final repository revisions/status including the preserved DT local edit.

Historical P17 closeout gate: superseded by the fourth production-path audit. P18-P19 are now mandatory before **READY FOR USER LIVE TEST**.


## P18 — Prevent mirror-to-authority identity bootstrapping

### P18A — Remove implicit authorization of unknown PNC mirrors

Retain the P16 Core issuance registry and its persistence API.

Verified fourth-audit bypass:

1. player modData contains only an unknown but syntactically valid `PNC_CharacterUUID`;
2. `PsychopatzPlayerIdentity.GetTargetKey/GetCharacterUUID` runs before Hoomans validation;
3. Core's existing PNC-UUID fallback calls `RegisterIssuedIdentity(..., { source = "hoom_adopted" })`;
4. the formerly unknown UUID is now authoritative in Core;
5. later real Hoomans `EnsureIdentity` accepts it as `core_adopted`.

Independent reproduction produced:

- before Core resolution: `IsIssuedIdentity = false / not_issued`;
- after Core resolution: `IsIssuedIdentity = true / source=hoom_adopted`;
- Hoomans adopted the forged UUID.

Requirements:

- `GetCharacterUUID/GetTargetKey` must never self-register an unknown PNC/adopter mirror;
- existing Core-issued UUID mirrors continue to resolve normally;
- if only an unknown PNC mirror exists, Core must not bless it as authoritative;
- Hoomans-first import into Core must come from the validated Hoomans player-character registry/service after Hoomans has accepted/created that identity;
- preserve exact UUID/key convergence for legitimate DT-first and Hoomans-first saves;
- preserve cross-account/dead/retired/duplicate-live-binding safeguards;
- preserve issuance persistence and idempotence;
- legacy already-forked aliases continue to converge without duplicate social events.

Mandatory adversarial tests:

1. forged unknown PNC UUID -> Core `GetTargetKey` first -> Core still reports `not_issued`;
2. same player -> real Hoomans `EnsureIdentity` -> forged UUID is not `core_adopted`;
3. legitimate DT-first Core-issued UUID -> Core resolution -> Hoomans adoption -> exact UUID/key preserved;
4. legitimate Hoomans-first registry identity -> explicit registry/service registration into Core -> exact UUID/key preserved;
5. unknown PNC mirror with no Hoomans registry record cannot silently replace/generate Core authority;
6. save/reload authoritative issuance and repeat resolution -> same safe behavior.

Gate: player mirrors can never create authority by lookup order.

## P19 — Live travel-derived factual dialogue, place presentation and persistence

### P19A — Wire actual excursion/travel lifecycle into canonical DT policy

Retain P17 policy fields and setters.

Verified fourth-audit gap: production runtime uses `SetHomeSettlement` and `SetCurrentSettlement`, but no production caller currently sets `destinationSettlementID` or `originSettlementID`. The Hoomans excursion payload already knows `homeCommunityID`, `destination.communityID`, and state transitions.

Wire the owning lifecycle so canonical policy reflects the actual trip.

At minimum for the Hoomans resident excursion bridge:

- PREPARING: origin/current home, destination selected community;
- OUTBOUND: current nil/offsite, origin retained, destination retained;
- VISITING: current visited community; origin remains actual departure; destination updates only if a next itinerary stop exists;
- RETURNING_HOME: origin becomes last visited community; destination becomes home community;
- AT_HOME: current/home set; destination cleared; origin remains historically meaningful as appropriate;
- FAILED/cancelled paths clear or restore destination/origin consistently.

Use equivalent owner paths for standalone DT travel where present.

### P19B — Resolve canonical IDs to human-facing place names

Do not store display names as canonical IDs merely to make tests readable.

Add/reuse a generic presentation seam so TalkService can resolve:

- DT-native settlement IDs;
- Hoomans community IDs when the optional adopter is installed;
- route/place IDs from WorldKnowledge.

The canonical policy should keep stable IDs. Dialogue should emit a known human name such as `Riverside Safehouse`, not a raw machine ID such as `community_367200000_423831`.

No DTCommon dependency on Project Hoomans internals is allowed. Hoomans may register/provide presentation through a public adapter/resolver.

Mandatory tests must use distinct values, e.g.:

- canonical ID: `community_123_456`;
- display name: `Riverside Safehouse`.

The response must contain the display name and must not expose the machine ID.

### P19C — Prove factual-state persistence through real DT storage

The P17 tests currently set policy state and query immediately. That does not prove the acceptance claim that factual answers survive reload.

Required:

1. establish home/current/origin/destination through the real production owner/lifecycle;
2. publish/acquire route/news WorldKnowledge through production APIs;
3. persist using the actual DT storage path that owns trader records and knowledge;
4. clear/reload runtime state from serialized/persisted data;
5. reopen TalkService;
6. ask destination/origin/settlement/route/news questions;
7. verify same canonical IDs, human-facing names and evidence/fact IDs are restored;
8. verify no stale destination survives completed/cancelled travel incorrectly.

### P19D — Final production matrix and docs reconciliation

Upgrade the existing matrix rather than replacing useful coverage.

The final matrix must include:

- forged PNC mirror -> Core resolves first -> remains unissued -> Hoomans rejects adoption;
- legitimate DT-first and Hoomans-first identity flows;
- P8B interleaved social integrity;
- P14 production capability isolation;
- real excursion/travel lifecycle populating origin/destination/current state;
- machine settlement ID resolved to human display name in dialogue;
- real WorldKnowledge road-news/route evidence;
- DT factual-state save/reload;
- remove/re-add adopters/packs without identity/social/semantic/factual corruption;
- repeated migration/reload idempotence.

Final validation:

- Core focused identity/social/semantics/conversation suites;
- Dynamic Trading full runner (fourth-audit baseline: 43/43);
- Hoomans focused corrective tests;
- Hoomans broad runner (fourth-audit baseline: 982/987 with the same five pre-existing failures);
- changed Lua syntax/Kahlua/static checks where tooling exists;
- `git diff --check`;
- exact final repository revisions/status, explicitly reporting the preserved tracked DT working-tree edit.

Historical P19 closeout gate: superseded by the fifth production-path audit. P20 is mandatory before **READY FOR USER LIVE TEST**.


## P20 — Failure-state correctness and reconstructed persistence acceptance

### P20A — Correct FAILED excursion lifecycle semantics

Retain the accepted PREPARING/OUTBOUND/VISITING/RETURNING_HOME/AT_HOME mapping.

Verified fifth-audit defect:

Project Hoomans normalizes excursion timestamps to numeric values:

- `departedAt = tonumber(...) or 0`;
- `completedAt = tonumber(...) or 0`.

Current DTHoomans FAILED handling checks:

```lua
if payload.departedAt ~= nil
    and not payload.completedAt
then
    ...
end
```

This is incorrect in Lua because `0` is truthy.

Independent production-handler reproduction:

- before FAILED: current=nil, origin=home, destination=selected destination;
- payload: `departedAt=12`, `completedAt=0`;
- current implementation incorrectly restores `currentSettlementID=home` and clears destination as though departure never happened.

Requirements:

- use numeric lifecycle meaning, not truthiness;
- failure before departure may restore/remain at home and restore availability;
- failure after departure must not fabricate home/current state;
- failure after visiting or while returning must preserve/derive the best authoritative origin/current/destination state;
- availability after failure must reflect whether the trader is actually home/usable;
- retry/recovery must not inherit stale destination incorrectly;
- no new Hoomans gameplay ownership should move into DTCommon.

Mandatory regressions:

1. PREPARING -> FAILED before departure -> home/current restored, destination cleared, availability consistent.
2. OUTBOUND -> FAILED with `departedAt > 0, completedAt = 0` -> trader is not reported home and is not incorrectly available.
3. VISITING -> FAILED -> current/origin/destination remain coherent with the last authoritative visit state.
4. RETURNING_HOME -> FAILED -> do not falsely mark home until exact-home completion occurs.
5. retry/new PREPARING after FAILED -> old destination does not leak into the new trip.
6. normal happy path remains unchanged.

Gate: FAILED/cancelled travel can never create a false factual "at home" state.

### P20B — Reconstructed trader-record persistence acceptance

Retain the accepted WorldKnowledge `Save/Load` coverage.

Strengthen trader-record persistence proof.

Current matrix and standalone semantic test put the trader record in a simulated storage table, set one local record variable to nil, then retrieve the same table/object from that storage. That demonstrates storage lookup continuity but not reconstruction from persisted state.

Required headless acceptance:

1. establish home/current/origin/destination through the production owner/lifecycle;
2. publish/acquire route/news facts;
3. obtain the real DT storage representation;
4. create a persisted snapshot/deep copy that represents what Global ModData would retain;
5. tear down/reset relevant TalkService/session/runtime references;
6. replace/reinitialize the storage backing with a fresh table reconstructed from the snapshot;
7. prove the reloaded trader record is not the same Lua object as the pre-save record;
8. run WorldKnowledge `Load` from the reconstructed storage;
9. re-open TalkService;
10. verify destination/origin/settlement/route/news output and evidence;
11. verify completed/failed trip cleanup is also represented correctly after reload.

Native engine serialization is not required for this developer gate, but same-object reuse is not accepted as a reload proof.

### P20C — Final regression matrix and documentation truth

Upgrade existing tests minimally rather than replacing accepted coverage.

Required final validation:

- exact P18 Core-first forged-mirror adversarial test remains green;
- P20 failure-state regressions pass;
- reconstructed persistence regression passes;
- production DTHoomans community presentation resolver remains verified;
- Dynamic Trading full runner remains at the fifth-audit baseline of `43/43` or improves;
- Hoomans broad runner remains at `982/987` with the same five documented baseline failures unless touched causes legitimately change;
- Core focused identity/social/conversation suites pass;
- changed Lua passes syntax/static/Kahlua checks where available;
- `git diff --check` passes;
- exact repository revisions/worktree statuses are recorded.

Git-history reconciliation:

- Dynamic Trading is currently clean at `89c349ce`;
- the formerly uncommitted `DTHoomans_Conversation.lua` semantic-hub edit was incorporated into commit `be9e8e10`;
- do not report it as an outstanding preserved tracked working-tree edit.

Gate: after P20A-P20C pass, the parent goal may return to **READY FOR USER LIVE TEST**.

## Completion rule

The parent goal is not complete merely because:

- Core Social supports extensions;
- DT standalone greetings work;
- Hoomans registers a pack;
- action providers are capability-filtered;
- a synthetic payload survives serialization;
- focused tests pass.

Completion requires one canonical player relationship identity whose authority cannot be bootstrapped from mirrors, non-destructive interleaved adopter writes, residue-free and capability-isolated production conversation semantics, working Hoomans adoption, factual DT route/destination/origin/settlement/news answers driven by actual gameplay owners and rendered with human-facing place presentation, failure-state travel correctness, reconstructed factual-state persistence across reload, and a real production-module hot-plug matrix that exercises those boundaries.
