# Acceptance — Core Semantic & Relationship Foundation

**Current status:** IN PROGRESS. The P13-P15 closeout was reopened by a third independent audit. Retain all independently reverified work; only P16-P17 unchecked gates remain mandatory.

## A. Ownership and canonical identity

- [x] PsychopatzCore is the canonical owner of shared actor/base social state.
- [x] Core has a persistent player-character target-key contract and DT uses it.
- [x] Normal DT-first UUID/key adoption through the real Hoomans service now preserves the exact UUID/key.
- [ ] Core maintains authoritative persistent issuance/adoption state for player identities.
- [ ] Hoomans adoption verifies authoritative Core issuance rather than only reproducible modData values.
- [ ] arbitrary unknown UUID + correctly forged public provenance hash is rejected by the real Hoomans service.
- [ ] Hoomans-first identities register/adopt into Core authority without UUID replacement.
- [x] transient online ID is not canonical relationship identity.
- [x] cross-account claims are rejected in the current path.
- [ ] authoritative issuance persists/reloads and adoption remains idempotent.
- [x] Core has no adopter gameplay-policy dependency.

## B. Core-first relationship integrity

- [x] stale Hoomans social state cannot delete newer DT memories/extensions.
- [x] DT -> Hoomans and Hoomans -> DT interleaved writes preserve both adopter extensions and shared changes.
- [x] alias convergence/idempotent social synchronization regressions pass.

## C. Semantic pack lifecycle and production isolation

- [x] pack ownership/unregister/re-register is residue-free in focused tests.
- [x] `PsychopatzActorConversationService` propagates effective capabilities into parsing.
- [x] DT-only production conversations reject Hoomans grammar when both packs are installed.
- [x] Hoomans-only production conversations reject DT grammar without DT capability.
- [x] compound turns preserve capability isolation.

## D. Project Hoomans additive adopter

- [x] Hoomans Core semantic pack uses the actual Core schema.
- [x] follow/camp/recruit/wellbeing examples and relationship gates work.
- [x] Hoomans gameplay actions remain Hoomans/server authority.
- [x] normal DT-first identity can currently be adopted without UUID replacement.
- [ ] adoption trust is backed by Core authoritative issuance state rather than forgeable self-consistent modData.

## E. Standalone Dynamic Trading semantics

- [x] Core + DT works without Project Hoomans.
- [x] required parser families now cover identity, trade, trader location, destination, origin, settlement, route, road news, caravan story, and farewell.
- [x] no-evidence destination/news paths return bounded uncertainty/no-news.
- [x] real acquired route WorldKnowledge facts ground generic route questions with fact IDs.
- [ ] destination/next-settlement production state exists upstream of TalkService and is used for `where are you heading`.
- [ ] origin/last-settlement and settlement answers are proven through canonical DT production state, not Submit option injection.
- [ ] road-news final acceptance is proven from real published/acquired WorldKnowledge, not hand-built Submit gossip.
- [ ] factual answers survive DT save/reload from canonical state.
- [x] authored generic caravan storytelling remains clearly non-current flavor.

## F. Real hot-plug/removal

- [x] current matrix exercises real Hoomans identity service, interleaved social writes, production capability isolation, pack lifecycle, and sync idempotence.
- [ ] final matrix proves forged identity rejection through authoritative issuance.
- [ ] final matrix seeds destination/origin/settlement through real DT owner APIs rather than `TalkService.Submit` answer options.
- [ ] final matrix seeds road news through real WorldKnowledge publish/acquire path.
- [ ] remove/re-add preserves authoritative identity state and factual DT state.

## G. Performance

- [x] no global per-tick semantic pack scan.
- [x] no periodic full relationship reconciliation.
- [ ] P16 issuance registry and P17 production fact plumbing remain bounded to identity/load/event/conversation boundaries.

## H. Developer validation

- [x] Core focused corrective tests passed at third audit.
- [x] Dynamic Trading full runner passed 43/43 at third audit.
- [x] Hoomans focused corrective tests passed at third audit.
- [x] Hoomans broad runner reached 982/987 with the same five documented pre-existing failures.
- [x] changed Lua parsed with `luac5.3 -p` and all repos passed `git diff --check` at third audit.
- [ ] P16 forged-provenance adversarial tests pass.
- [ ] P17 upstream-production grounding tests pass.
- [ ] final P16-P17 matrix passes and exact repository revisions/status are recorded.

## User-owned native handoff

Do not hand this goal to native SP/MP testing until all P16-P17 developer gates above pass.

Native acceptance then covers representative DT-only, combined, add/remove/re-add saves and real UI/dialogue quality.
