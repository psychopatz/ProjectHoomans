# Acceptance — Core Semantic & Relationship Foundation

**Current status:** READY FOR USER LIVE TEST. All P0-P12 corrective architecture phases completed, committed, and verified across PsychopatzCore, DynamicTrading, and ProjectHoomans.

## A. Ownership and canonical identity

- [x] PsychopatzCore is the only canonical owner of shared actor identity/base social relationship state.
- [x] The same player character resolves to exactly one canonical Core Social target key in DT-only, Hoomans-only and combined configurations.
- [x] SP and MP player identity use durable persistent identity, not transient online ID as relationship authority.
- [x] Legacy DT/Hoomans player-key aliases migrate/merge once without duplicate relationship entries.
- [x] Core has no ProjectHoomans or DynamicTrading gameplay-policy dependency.
- [x] Hoomans-only social concepts remain Hoomans-owned extensions/policy.
- [x] DT stock/budget/pricing/market state remains Dynamic Trading-owned.
- [x] Hoomans NPC command/task/combat/faction gameplay remains Hoomans-owned.

## B. Core-first relationship integrity

- [x] Hoomans relationship mutation operates against latest canonical Core state rather than replacing Core from a stale `record.social` snapshot.
- [x] DT trade -> Hoomans relationship mutation preserves DT memory and `DynamicTrading` extension exactly.
- [x] Hoomans relationship mutation -> DT trade preserves `ProjectHoomans` extension and shared changes exactly.
- [x] Stale revisions conflict/retry/merge explicitly and cannot erase newer Core data.
- [x] An adopter cannot overwrite/delete another adopter's extension through normal mutation.
- [x] Synchronization failures that threaten social truth are observable rather than swallowed.

## C. Standalone Dynamic Trading

In Core + DTCommon + DTAbstract without Project Hoomans:

- [x] actor identity is stable across save/reload;
- [x] canonical player relationship/memories persist;
- [x] greeting/farewell conversation is available;
- [x] trade/buy/sell semantics work;
- [x] trader/guard role and identity questions work;
- [x] settlement/trader whereabouts and route/journey questions use real DT evidence where available;
- [x] caravan/commercial story and rumor dialogue works;
- [x] trader/commercial/story dialogue can use relationship context;
- [x] trade/referral semantic actions are available only when eligible;
- [x] no Hoomans-only content/action is registered or displayed;
- [x] no PNC/Hoomans semantic module is required by the standalone path.

## D. Semantic pack lifecycle

- [x] Pack registration tracks ownership of concepts, speech acts, patterns, resolvers/flavors, dialogue blocks and action providers.
- [x] Pack-level capability/activation requirements prevent inactive adopter parser/dialogue/action content from leaking.
- [x] Unregistering a pack removes all of its owned semantic residue.
- [x] Unregistering one adopter leaves other packs intact.
- [x] Re-register/update behavior is deterministic and diagnostics identify active ownership.

## E. Hoomans adoption

With Project Hoomans enabled:

- [x] existing Core actors are reused, not duplicated;
- [x] canonical player target key is reused, not forked;
- [x] base relationship remains semantically equivalent after migration;
- [x] Hoomans social extensions attach to the same canonical relationship;
- [x] Core-facing Hoomans concepts/patterns/dialogue blocks use the actual Core schema and work behaviorally;
- [x] relationship gates select friendly/neutral/wary content correctly;
- [x] expected multi-word Hoomans semantic examples match where registered;
- [x] production Hoomans surfaces actually consume Core-registered semantic content/actions where claimed;
- [x] existing Hoomans semantic corpus/flows/actions remain functional;
- [x] server-authoritative gameplay actions remain Hoomans-owned;
- [x] Semantic Lab can observe the adopted production pipeline.

## F. Real hot-plug/removal

Using actual production adopter modules, not only direct Core table manipulation:

- [x] DT-first save can add Hoomans without actor/player-key/relationship reset.
- [x] A Hoomans mutation after DT history preserves prior DT memories/extensions.
- [x] A DT trade after Hoomans history preserves prior Hoomans extensions/shared state.
- [x] Hoomans can be removed while DT remains healthy.
- [x] Hoomans extension data is preserved dormant and recovers on re-enable.
- [x] Hoomans-first save can add DT without actor or relationship duplication.
- [x] DT can be removed/re-added without damaging Hoomans shared state.
- [x] repeated migration/reload is idempotent.
- [x] absent extension owners do not cause data deletion.
- [x] migration conflicts fail visibly/quarantine rather than destructive reset.
- [x] semantic pack removal leaves no inactive-adopter parser/dialogue/action residue.

## G. Performance

- [x] no global per-tick semantic pack scan;
- [x] no periodic full actor relationship reconciliation;
- [x] pack registration and migration work are bounded to bootstrap/load/import/conversation boundaries;
- [x] relationship mutation/merge is bounded to the affected actor/target;
- [x] existing hot paths remain within accepted performance envelope.

## H. Developer validation

- [x] focused Core owner tests pass;
- [x] Dynamic Trading full suite passes;
- [x] Hoomans focused tests pass;
- [x] every broad-suite failure introduced by this goal is fixed;
- [x] unrelated/pre-existing broad-suite failures are explicitly baselined and proven unchanged rather than silently ignored;
- [x] real cross-adopter hot-plug matrix passes;
- [x] changed runtime Lua passes syntax/Kahlua/static verification where tooling exists;
- [x] `git diff --check` passes;
- [x] repository status/revisions and preserved pre-existing DT work are reported accurately.

## User-owned native handoff

Only after A-H pass should the user validate representative native SP/MP saves for DT-only, Hoomans-only/combined, add/remove/re-add behavior, UI/dialogue quality and persistence across real PZ restarts.

Native acceptance must not be fabricated from synthetic/headless tests.
