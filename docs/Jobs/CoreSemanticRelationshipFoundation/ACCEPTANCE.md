# Acceptance — Core Semantic & Relationship Foundation

**Current status:** IN PROGRESS. The P18-P19 closeout was reopened by a fifth production-path audit. P18 is independently accepted; P19 happy-path travel/presentation remains accepted; P20 failure-state and reconstructed-persistence gates remain mandatory.

## A. Ownership and canonical identity

- [x] PsychopatzCore owns shared actor/base social state and canonical target-key shape.
- [x] Core has a persistent issuance registry and save/load API.
- [x] legitimate DT-first Core-issued UUIDs are adopted by the real Hoomans service without UUID/key replacement.
- [x] Core `GetCharacterUUID/GetTargetKey` does not auto-register an unknown `PNC_CharacterUUID` mirror.
- [x] forged unknown PNC mirror -> Core resolves first -> forged identity remains `not_issued`.
- [x] real Hoomans `EnsureIdentity` does not adopt that forged UUID.
- [x] Hoomans-first Core registration originates from validated Hoomans identity authority.
- [x] cross-account and repeat-adoption protections remain intact.

## B. Core-first relationship integrity

- [x] DT/Hoomans interleaved writes preserve foreign extensions/memories.
- [x] stale Hoomans state cannot erase newer Core/DT social state.
- [x] alias convergence and repeated synchronization remain idempotent.

## C. Semantic lifecycle and isolation

- [x] pack lifecycle remains residue-free.
- [x] production ActorConversationService propagates effective capabilities.
- [x] DT-only conversations reject Hoomans grammar.
- [x] Hoomans-only conversations reject DT grammar.
- [x] compound turns preserve capability isolation.

## D. Dynamic Trading factual semantics and presentation

- [x] required parser families are complete.
- [x] no-evidence destination/news uses bounded uncertainty.
- [x] route/news WorldKnowledge facts produce evidence-backed responses.
- [x] canonical home/current/origin/destination policy fields exist.
- [x] TalkService consumes canonical policy state.
- [x] production resident excursion wires PREPARING/OUTBOUND/VISITING/RETURNING_HOME/AT_HOME.
- [x] canonical community IDs resolve to human-facing names through a bounded resolver.
- [x] unresolved machine IDs do not leak into dialogue.
- [ ] FAILED before departure is explicitly regression-tested and restores coherent home state.
- [ ] FAILED after departure with numeric `completedAt = 0` does not falsely report the trader home/available.
- [ ] FAILED while visiting/returning preserves coherent authoritative travel facts.
- [ ] retry after FAILED does not inherit stale destination/origin incorrectly.

## E. Persistence

- [x] WorldKnowledge real `Save/Load` path is exercised with fact IDs/evidence.
- [x] DT storage contains canonical trader policy state.
- [ ] headless reload reconstructs trader records from a persisted snapshot/fresh backing table.
- [ ] the reloaded trader record is proven to be a distinct Lua object from the pre-save record.
- [ ] reconstructed reload preserves destination/origin/current settlement and human presentation.
- [ ] completed/failed travel cleanup remains correct after reconstructed reload.

## F. Real hot-plug/removal matrix

- [x] real Hoomans identity service is exercised.
- [x] forged PNC mirror -> Core-first resolution -> Hoomans-second validation is covered.
- [x] P8B relationship interleaving remains covered.
- [x] P14 production capability isolation remains covered.
- [x] live happy-path excursion transitions and place presentation are covered.
- [x] pack unregister/re-register and migration idempotence remain covered.
- [ ] FAILED/cancelled lifecycle coverage is included.
- [ ] factual-state reload uses reconstructed persistence rather than same-object storage reuse.

## G. Performance

- [x] no global per-tick semantic scan.
- [x] no periodic full relationship reconciliation.
- [x] identity/travel/presentation work remains bounded to explicit lifecycle/load/conversation events.
- [ ] P20 correction preserves bounded behavior.

## H. Developer validation

- [x] fifth audit independently verified P18 attack-order fix.
- [x] Core focused identity/social/conversation tests pass.
- [x] Dynamic Trading full runner passes `43/43`.
- [x] Hoomans focused P18/P19 tests pass.
- [x] Hoomans broad runner remains `982/987` with the same five known baseline failures.
- [x] changed P18/P19 Lua passes `luac5.3 -p`; all repos pass `git diff --check`.
- [ ] P20 failure-state regressions pass.
- [ ] P20 reconstructed persistence regression passes.
- [ ] final exact revisions/worktree status are recorded accurately.

## Repository-history note

Dynamic Trading is currently clean. The former tracked local `DTHoomans_Conversation.lua` semantic-hub edit was incorporated into commit `be9e8e10`; it is no longer an outstanding working-tree modification.

## User-owned native handoff

Do not hand this goal to native SP/MP testing until P20 developer gates pass.

After P20, native acceptance covers representative DT-only/combined/add-remove-readd saves, real excursion failure/recovery behavior, settlement naming, relationship continuity and UI/dialogue quality.
