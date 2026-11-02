# Roadmap — Core Semantic & Relationship Foundation

**Status:** IN PROGRESS — P0-P7 implementation exists, but independent verification invalidated several acceptance claims. P8-P12 are mandatory corrective continuation.

The parent goal completion boundary is now the complete P0-P12 outcome. P0-P7 remain implementation history/foundation; P8-P12 close the verified gaps instead of rebuilding accepted components.

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

Gate: only after P12 passes may PROGRESS return to **READY FOR USER LIVE TEST**.

## Completion rule

The parent goal is not complete merely because:

- Core Social supports extensions;
- DT standalone greetings work;
- Hoomans registers a pack;
- action providers are capability-filtered;
- a synthetic payload survives serialization;
- focused tests pass.

Completion requires one canonical player relationship identity, non-destructive interleaved adopter writes, residue-free semantic pack lifecycle, working Hoomans adoption, full standalone DT story/whereabouts coverage, and a real production-module hot-plug matrix.
