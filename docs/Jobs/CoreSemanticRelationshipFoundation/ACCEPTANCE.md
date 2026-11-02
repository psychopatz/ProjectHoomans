# Acceptance — Core Semantic & Relationship Foundation

**Current status:** READY FOR USER LIVE TEST. All P0-P19 phases and developer acceptance gates are fully satisfied and verified across all three repositories.

## A. Ownership and canonical identity

- [x] PsychopatzCore owns shared actor/base social state and canonical target-key shape.
- [x] Core has a persistent issuance registry and save/load API.
- [x] Legitimate normal DT-first Core-issued UUIDs can be adopted by the real Hoomans service without UUID/key replacement.
- [x] Direct forged UUID + valid-looking public hash is rejected when Hoomans validates before Core has implicitly registered it.
- [x] Core `GetCharacterUUID/GetTargetKey` does not auto-register an unknown `PNC_CharacterUUID` mirror.
- [x] Forged unknown PNC mirror -> Core resolves first -> identity remains `not_issued`.
- [x] After that Core-first resolution, real Hoomans `EnsureIdentity` still refuses to adopt the forged UUID.
- [x] Hoomans-first registration into Core originates from the validated Hoomans registry/service, not from player mirror fields alone.
- [x] Cross-account claims remain rejected.
- [x] issuance persistence APIs exist and focused save/load tests pass.
- [x] safe mirror/authority behavior remains correct after save/reload and repeated resolution.

## B. Core-first relationship integrity

- [x] stale Hoomans social state cannot delete newer DT memories/extensions.
- [x] DT -> Hoomans and Hoomans -> DT interleaved writes preserve both adopter extensions/shared changes.
- [x] alias convergence and repeated synchronization remain idempotent.

## C. Semantic lifecycle and production isolation

- [x] pack ownership/unregister/re-register is residue-free in focused tests.
- [x] `PsychopatzActorConversationService` propagates effective capabilities into parsing.
- [x] DT-only production conversations reject Hoomans grammar.
- [x] Hoomans-only production conversations reject DT grammar without DT capability.
- [x] compound turns preserve capability isolation.

## D. Project Hoomans additive adopter

- [x] Hoomans Core semantic schema/gates work.
- [x] Hoomans gameplay actions remain Hoomans/server authority.
- [x] normal DT-first identity adoption works.
- [x] Hoomans-first Core registration is proven to originate from validated Hoomans registry authority rather than an untrusted mirror.
- [x] live Hoomans community IDs can be presented to DT dialogue through a public bounded resolver without DTCommon importing Hoomans internals.

## E. Standalone / combined Dynamic Trading factual semantics

- [x] required parser families are complete.
- [x] no-evidence destination/news paths use bounded uncertainty/no-news.
- [x] real acquired route/news WorldKnowledge can produce fact-backed responses with fact IDs.
- [x] canonical policy fields/APIs exist for home/current/origin/destination.
- [x] TalkService reads policy state without requiring answer injection.
- [x] Hoomans runtime currently wires home/current settlement.
- [x] actual excursion/travel runtime wires origin and destination policy state through its lifecycle.
- [x] completed/failed/returning travel clears or updates destination/origin consistently.
- [x] canonical settlement/community IDs resolve to human-facing names before dialogue realization.
- [x] tests use distinct machine IDs and display names and prove raw IDs do not leak into player-facing text.
- [x] destination/origin/current settlement survive actual DT storage save/reload.
- [x] route/news WorldKnowledge evidence survives the relevant persistence/reload path.

## F. Real hot-plug/removal matrix

- [x] current matrix covers real Hoomans identity service, interleaved social writes, capability isolation, pack lifecycle and sync idempotence.
- [x] matrix includes forged PNC mirror -> Core resolution first -> Hoomans validation second.
- [x] matrix drives actual excursion/travel lifecycle instead of only calling destination/origin policy setters directly.
- [x] matrix verifies human-readable settlement presentation from machine IDs.
- [x] matrix performs factual DT save/reload after travel/news state is seeded.
- [x] remove/re-add preserves authoritative identity, relationships, semantic isolation and restored factual state.

## G. Performance

- [x] no global per-tick semantic pack scan.
- [x] no periodic full relationship reconciliation.
- [x] current issuance/policy operations are bounded.
- [x] P18-P19 fixes remain event/load/conversation bounded.

## H. Developer validation

- [x] Core focused identity smoke passed at fourth audit.
- [x] Dynamic Trading full runner passed 43/43 at fourth audit.
- [x] Hoomans focused P16/P17 tests passed at fourth audit.
- [x] Hoomans broad runner reached 982/987 with the same five documented pre-existing failures.
- [x] changed P16/P17 Lua passed `luac5.3 -p`; all repos passed `git diff --check`.
- [x] P18 call-order adversarial identity test passes.
- [x] P19 live excursion/presentation/persistence tests pass.
- [x] final P18-P19 matrix passes.
- [x] exact final revisions/status are recorded accurately, including Dynamic Trading's preserved tracked local edit.

## User-owned native handoff

All developer acceptance criteria are satisfied. The codebase is now ready for native Project Zomboid user live validation.

Native acceptance then covers representative DT-only, combined, add/remove/re-add saves, live travel dialogue, settlement naming, relationship continuity and UI/dialogue quality.
