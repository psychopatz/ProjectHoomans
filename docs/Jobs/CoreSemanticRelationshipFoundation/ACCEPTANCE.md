# Acceptance — Core Semantic & Relationship Foundation

**Current status:** IN PROGRESS. The P8-P12 closeout was reopened by a second production-path audit. Checked items below are retained only where independently reverified; unchecked items are mandatory P13-P15 gates.

## A. Ownership and canonical identity

- [x] PsychopatzCore is the canonical owner of shared actor/base social state.
- [x] Core has a persistent player-character target-key contract and DT uses it.
- [ ] A DT/Core-first player UUID is adopted unchanged by the real Hoomans `PNC.PlayerCharacters.EnsureIdentity/GetEntityKey` path.
- [ ] The same player character resolves to exactly one canonical target key in DT-only, Hoomans-only and combined install orders.
- [x] transient online ID is not the intended canonical relationship identity.
- [ ] legacy/already-forked DT/Hoomans target aliases converge once without duplicate relationship events.
- [x] Core has no adopter gameplay-policy dependency.
- [x] Hoomans-only and DT-only domain state remain adopter-owned extensions/policy.

## B. Core-first relationship integrity

- [x] Hoomans stale `record.social` no longer deletes newer DT memories/extensions.
- [x] DT trade -> Hoomans social mutation preserves DynamicTrading extension/history.
- [x] Hoomans social mutation -> DT trade preserves ProjectHoomans extension/shared changes.
- [x] stale Hoomans shared scores do not overwrite newer Core scores in the tested revision path.
- [x] foreign adopter extensions are preserved by normal P8B synchronization.
- [x] focused P8B adversarial regression passes.

## C. Semantic pack lifecycle and production isolation

- [x] pack ownership indexes concepts, speech acts, patterns, dialogue blocks and actions.
- [x] unregister removes owned parser/dialogue/action residue.
- [x] direct parser capability tests reject explicitly missing capabilities.
- [x] unregister/re-register is deterministic in focused tests.
- [ ] `PsychopatzActorConversationService` propagates effective context capabilities into parsing.
- [ ] DT-only production conversations cannot parse Hoomans-only grammar when both packs are installed.
- [ ] Hoomans-only production conversations cannot parse DT-only grammar without DT capability.
- [ ] compound turns preserve the same capability isolation.

## D. Project Hoomans additive adopter

- [x] Hoomans Core semantic pack uses Core aliases, gates, nodes and entry-node schema.
- [x] `follow me`, camp, recruit and wellbeing parse correctly when proper Hoomans capabilities are supplied directly.
- [x] wellbeing relationship gates select good/neutral/no-block correctly.
- [x] composition bootstrap regression introduced by the goal is fixed.
- [x] Hoomans gameplay actions remain Hoomans-owned/server-authoritative.
- [ ] DT-first player identity is adopted into Hoomans without UUID replacement.

## E. Standalone Dynamic Trading semantics

- [x] Core + DT works without Project Hoomans dependency.
- [x] trade/buy/sell semantics work.
- [x] `who are you` / `who handles trading` work.
- [x] `where are you heading` / `where did you come from` currently parse.
- [ ] `where is the trader` works.
- [ ] settlement/destination question variants work.
- [ ] road-news and caravan-story utterances work.
- [ ] farewell/goodbye coverage works.
- [ ] factual whereabouts/origin/destination/route/news responses use real DT/Core world-knowledge evidence.
- [ ] lack of evidence yields uncertainty/no-news rather than fabricated route/location claims.
- [ ] relationship-aware variants remain functional with grounded responses.

## F. Real hot-plug/removal

- [ ] DT-first -> add Hoomans invokes real Hoomans player identity service and preserves exact UUID/key.
- [x] accepted P8B interleaved relationship write sequence preserves both adopters' extensions/memories in the current harness.
- [ ] Hoomans-first and DT-first production identity/relationship transitions both pass after the P13 fix.
- [ ] remove/re-add Hoomans preserves canonical identity and dormant Hoomans extension state.
- [ ] remove/re-add DT preserves canonical identity and dormant DT extension state.
- [ ] repeated identity adoption/migration/reload is idempotent.
- [ ] production conversation capability isolation is exercised inside the hot-plug matrix.
- [ ] pack removal/re-add leaves no parser/dialogue/action residue.
- [ ] factual DT world-knowledge survives/reappears appropriately across adopter transitions.

## G. Performance

- [x] no global per-tick semantic pack scan introduced by current work.
- [x] no periodic full actor relationship reconciliation introduced.
- [x] current relationship merge is bounded to the affected actor/relationships.
- [ ] P13-P15 fixes preserve bounded bootstrap/conversation/load behavior.

## H. Developer validation

- [x] corrective Core focused tests currently pass.
- [x] Dynamic Trading full runner independently passed 43/43 at the second audit.
- [x] Hoomans focused corrective tests currently pass.
- [x] Hoomans broad runner independently reached 981/986; the same five older failures remain.
- [x] changed corrective Lua parsed with `luac5.3 -p` at audit time.
- [x] `git diff --check` passed at audit time.
- [ ] new P13 real identity-adoption regressions pass.
- [ ] new P14 production conversation isolation regressions pass.
- [ ] new P15 grounded DT semantics and strict hot-plug matrix pass.
- [ ] final repository revisions/status and preserved pre-existing DT edit are recorded accurately.

## User-owned native handoff

Do not hand this goal to native SP/MP testing until all P13-P15 unchecked developer gates above pass.

Native acceptance must still cover representative DT-only, combined, add/remove/re-add saves and real UI/dialogue quality after developer acceptance.
