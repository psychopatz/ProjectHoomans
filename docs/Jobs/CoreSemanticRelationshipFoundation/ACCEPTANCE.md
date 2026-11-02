# Acceptance — Core Semantic & Relationship Foundation

**Current status:** REOPENED after independent post-P7 audit. No previous developer-complete claim supersedes the unchecked gates below.

## A. Ownership and canonical identity

- [ ] PsychopatzCore is the only canonical owner of shared actor identity/base social relationship state.
- [ ] The same player character resolves to exactly one canonical Core Social target key in DT-only, Hoomans-only and combined configurations.
- [ ] SP and MP player identity use durable persistent identity, not transient online ID as relationship authority.
- [ ] Legacy DT/Hoomans player-key aliases migrate/merge once without duplicate relationship entries.
- [ ] Core has no ProjectHoomans or DynamicTrading gameplay-policy dependency.
- [ ] Hoomans-only social concepts remain Hoomans-owned extensions/policy.
- [ ] DT stock/budget/pricing/market state remains Dynamic Trading-owned.
- [ ] Hoomans NPC command/task/combat/faction gameplay remains Hoomans-owned.

## B. Core-first relationship integrity

- [ ] Hoomans relationship mutation operates against latest canonical Core state rather than replacing Core from a stale `record.social` snapshot.
- [ ] DT trade -> Hoomans relationship mutation preserves DT memory and `DynamicTrading` extension exactly.
- [ ] Hoomans relationship mutation -> DT trade preserves `ProjectHoomans` extension and shared changes exactly.
- [ ] Stale revisions conflict/retry/merge explicitly and cannot erase newer Core data.
- [ ] An adopter cannot overwrite/delete another adopter's extension through normal mutation.
- [ ] Synchronization failures that threaten social truth are observable rather than swallowed.

## C. Standalone Dynamic Trading

In Core + DTCommon + DTAbstract without Project Hoomans:

- [ ] actor identity is stable across save/reload;
- [ ] canonical player relationship/memories persist;
- [ ] greeting/farewell conversation is available;
- [ ] trade/buy/sell semantics work;
- [ ] trader/guard role and identity questions work;
- [ ] settlement/trader whereabouts and route/journey questions use real DT evidence where available;
- [ ] caravan/commercial story and rumor dialogue works;
- [ ] trader/commercial/story dialogue can use relationship context;
- [ ] trade/referral semantic actions are available only when eligible;
- [ ] no Hoomans-only content/action is registered or displayed;
- [ ] no PNC/Hoomans semantic module is required by the standalone path.

## D. Semantic pack lifecycle

- [ ] Pack registration tracks ownership of concepts, speech acts, patterns, resolvers/flavors, dialogue blocks and action providers.
- [ ] Pack-level capability/activation requirements prevent inactive adopter parser/dialogue/action content from leaking.
- [ ] Unregistering a pack removes all of its owned semantic residue.
- [ ] Unregistering one adopter leaves other packs intact.
- [ ] Re-register/update behavior is deterministic and diagnostics identify active ownership.

## E. Hoomans adoption

With Project Hoomans enabled:

- [ ] existing Core actors are reused, not duplicated;
- [ ] canonical player target key is reused, not forked;
- [ ] base relationship remains semantically equivalent after migration;
- [ ] Hoomans social extensions attach to the same canonical relationship;
- [ ] Core-facing Hoomans concepts/patterns/dialogue blocks use the actual Core schema and work behaviorally;
- [ ] relationship gates select friendly/neutral/wary content correctly;
- [ ] expected multi-word Hoomans semantic examples match where registered;
- [ ] production Hoomans surfaces actually consume Core-registered semantic content/actions where claimed;
- [ ] existing Hoomans semantic corpus/flows/actions remain functional;
- [ ] server-authoritative gameplay actions remain Hoomans-owned;
- [ ] Semantic Lab can observe the adopted production pipeline.

## F. Real hot-plug/removal

Using actual production adopter modules, not only direct Core table manipulation:

- [ ] DT-first save can add Hoomans without actor/player-key/relationship reset.
- [ ] A Hoomans mutation after DT history preserves prior DT memories/extensions.
- [ ] A DT trade after Hoomans history preserves prior Hoomans extensions/shared state.
- [ ] Hoomans can be removed while DT remains healthy.
- [ ] Hoomans extension data is preserved dormant and recovers on re-enable.
- [ ] Hoomans-first save can add DT without actor or relationship duplication.
- [ ] DT can be removed/re-added without damaging Hoomans shared state.
- [ ] repeated migration/reload is idempotent.
- [ ] absent extension owners do not cause data deletion.
- [ ] migration conflicts fail visibly/quarantine rather than destructive reset.
- [ ] semantic pack removal leaves no inactive-adopter parser/dialogue/action residue.

## G. Performance

- [ ] no global per-tick semantic pack scan;
- [ ] no periodic full actor relationship reconciliation;
- [ ] pack registration and migration work are bounded to bootstrap/load/import/conversation boundaries;
- [ ] relationship mutation/merge is bounded to the affected actor/target;
- [ ] existing hot paths remain within accepted performance envelope.

## H. Developer validation

- [ ] focused Core owner tests pass;
- [ ] Dynamic Trading full suite passes;
- [ ] Hoomans focused tests pass;
- [ ] every broad-suite failure introduced by this goal is fixed;
- [ ] unrelated/pre-existing broad-suite failures are explicitly baselined and proven unchanged rather than silently ignored;
- [ ] real cross-adopter hot-plug matrix passes;
- [ ] changed runtime Lua passes syntax/Kahlua/static verification where tooling exists;
- [ ] `git diff --check` passes;
- [ ] repository status/revisions and preserved pre-existing DT work are reported accurately.

## User-owned native handoff

Only after A-H pass should the user validate representative native SP/MP saves for DT-only, Hoomans-only/combined, add/remove/re-add behavior, UI/dialogue quality and persistence across real PZ restarts.

Native acceptance must not be fabricated from synthetic/headless tests.
