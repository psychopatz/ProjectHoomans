# Acceptance — Core Semantic & Relationship Foundation

## A. Ownership

- [ ] PsychopatzCore is the only canonical owner of shared actor identity/base social relationship state.
- [ ] Core has no ProjectHoomans or DynamicTrading policy dependency.
- [ ] Hoomans-only social concepts remain Hoomans-owned extensions/policy.
- [ ] DT stock/budget/pricing/market state remains Dynamic Trading-owned.
- [ ] Hoomans NPC command/task/combat/faction gameplay remains Hoomans-owned.

## B. Standalone Dynamic Trading

In Core + DTCommon + DTAbstract without Project Hoomans:

- [ ] actor identity is stable across save/reload;
- [ ] base relationship/memories persist;
- [ ] trader/guard conversation is available;
- [ ] trader/commercial/story dialogue can use relationship context;
- [ ] trade semantic action is available when eligible;
- [ ] no Hoomans-only action is registered or displayed;
- [ ] no PNC/Hoomans semantic module is required by the standalone path.

## C. Hoomans adoption

With Project Hoomans enabled:

- [ ] existing Core actors are reused, not duplicated;
- [ ] base relationship remains byte/semantic-equivalent after migration where applicable;
- [ ] Hoomans social extensions attach to the same relationship;
- [ ] existing Hoomans semantic corpus/flows/actions remain functional;
- [ ] server-authoritative gameplay actions remain Hoomans-owned;
- [ ] Semantic Lab can observe the adopted production pipeline.

## D. Hot-plug/removal

- [ ] DT-first save can add Hoomans without identity/relationship reset.
- [ ] Hoomans can be removed while DT remains healthy.
- [ ] Hoomans extension data is preserved dormant and recovers on re-enable.
- [ ] Hoomans-first save can add DT without actor duplication.
- [ ] DT can be removed/re-added without damaging Hoomans shared state.
- [ ] repeated migration/reload is idempotent.
- [ ] absent extension owners do not cause data deletion.

## E. Safety and data integrity

- [ ] migration is versioned and provenance-marked;
- [ ] unknown/incompatible state fails visibly or is quarantined/preserved;
- [ ] no destructive reset is used as migration fallback;
- [ ] no duplicate actor/provider/body lease is created;
- [ ] one actor/target pair cannot expose divergent shared relationship values through DT versus Hoomans.

## F. Performance

- [ ] no global per-tick semantic pack scan;
- [ ] no periodic full actor relationship reconciliation;
- [ ] pack registration and migration work are bounded to bootstrap/load/import/conversation boundaries;
- [ ] existing hot paths remain within accepted performance envelope.

## G. Developer validation

- [ ] focused owner tests pass;
- [ ] cross-adopter matrix passes;
- [ ] relevant existing broad suites pass or pre-existing failures are proven unchanged;
- [ ] changed runtime Lua passes syntax/Kahlua/static verification;
- [ ] `git diff --check` passes;
- [ ] repository status and revisions are reported accurately.

## User-owned native handoff

After developer acceptance, user validates representative SP/MP saves for DT-only, Hoomans-only/combined, add/remove/re-add behavior, UI/dialogue quality and persistence across real PZ restarts.

Native acceptance is not to be fabricated from synthetic tests.
