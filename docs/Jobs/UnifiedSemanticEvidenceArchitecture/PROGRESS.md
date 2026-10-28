# Progress — Unified Semantic Evidence Architecture

**Status:** IN PROGRESS — E0–E5 accepted; extensibility proof and scale gates pending.
**Branch:** existing main.
**Audit anchor:** ProjectHoomans 2bc4810f.
**Current phase:** E6 — extensibility proof.
**Next exact chunk:** E6A — register a test-only promise/fulfillment/breach/explanation mechanic through public metadata/provider seams, prove SESSION/TODAY/DURABLE and director/UtterancePlan participation without editing generic query/resolver code or adding a store; then complete E7 storage/performance/regression gates.

## E6 precondition — equal-time domain chronology repaired (2026-10-28)

- The future-mechanic fixture exposed ID sorting of equal-world-time durable memories. Relationship mutations now stamp optional `eventSequence` using existing owner revision/retained sequences, capped and bounded to 20 reads. Normalization/fingerprints preserve it; the owner query exposes it instead of treating normalized array order as chronology.
- No occurrence timestamp is fabricated, no new counter/root exists, and legacy memories remain readable. Generic InteractionEvidence.Query and PragmaticResolver source are unchanged from E5.
- A first-party regression proves insult -> repair -> newer insult at the same timestamp remains open after serialize/reimport and day rollover. Future mechanic passes all three tiers after the owner fix. Full Lua 906/906 and relationship 5/5 pass.

## E5 accepted (2026-10-28)

- Repair, gratitude and response families share normalization, relation matching and director admission. Gratitude requires reversed helper/recipient roles; request/offer/question replies reverse the initiating actor roles. Wrong direction and missing antecedents fail closed.
- Existing SocialEvents now supports an explicitly record-only actor memory for NPC wound treatment/rescue, using the canonical event metadata and existing bounded Relationship/Conversation Memory owners. This remembers provided aid without approval/respect/familiarity rewards. Canonical actor metadata registration is audited too.
- Pending follow-ups and current NPC response-plan semantic acts project through SESSION. Generated player strategies enumerate registered contextual acts, use the same admission query, and click through the existing semantic-frame route. Added EN/TL ACCEPT/REFUSE/THANK constructions through canonical CodeBuilder sources. Grounded repair has a one-shot acknowledgement when beat cooldown prevents reconciliation.
- Existing player-scoped Relationship presentation carries at most 16 normalized evidence rows and an observation clock/day. MP adapters normalize them again, reject stale (>1 hour) or prior-day TODAY rows, and prefer available authoritative owners. Presentation does not mutate serialized records or send private full stores, transcripts or relevance scores.
- Full Lua 906/906 PASS; combined E0–E5 worker 15/15 PASS; remote projection smoke PASS; metadata actor audit PASS. Broad pragmatic Python tests retain only the four independently reproduced pre-existing failures. Generation is byte-identical across 227 generated/translation files; runtime Kahlua/syntax/diff checks PASS.
- Worker loads the production Registry dirty owner with an inert engine OnInitGlobalModData event seam; no native runtime/save IO is introduced.

## E4B / E4 accepted (2026-10-28)

- Registered compact semantic-act markers are written through the existing leased server InteractionLifecycle handler. Server admission is recomputed from owning-domain evidence; client plans/scores are not trusted. Unresolved apology writes no marker. Zero-effect Relationship memories retain the fact of addressing a relation; compact TODAY survives detailed pruning. No forgiveness/permission effect was added.
- Generic relation policies declare same/reverse/either actor direction. Repair is same-direction; gratitude/replies reverse the initiating roles. Matching uses policy data, not act/event conditionals.
- Closure derives from ordered SESSION/TODAY evidence and durable owning Relationship records; repeated repair remains closed across serialize/reimport and day rollover, while a newer grievance reopens it. Compact markers use explicitly registered stable hashes rather than dynamic fallback. Retention priority of closure markers prevents lower-salience churn from resurrecting retained antecedents.
- Worker now loads/routes the actual lifecycle server handler and supports both PZ sendClientCommand signatures. SAVE conduct persistence delegates to the production PlayerCharacters owner instead of a fixture stub; normal turns now expose real Conduct evidence. Configurable fixture conversation IDs prevent replay request-ID collisions.
- Full Lua 905/905 PASS; E0–E4 production worker 10/10 PASS; P12J SAVE-backed 2/2 PASS; prior P2/P3/R6 11/11 PASS. E4A's four independently reproduced pre-existing Python failures remain documented for E7 cleanup.
- Native evidence transport is a developer implementation task still pending E5 (not a native-user handoff).

## E4A accepted (2026-10-28)

- PragmaticResolver matches registered act relations, actors/targets and bounded provider rows. Exposes grounded/unresolved/unrelated/ambiguous status and independent confidence, retention salience, strength, age/recency, topic fit, priority and ephemeral contextual relevance. No APOLOGIZE-to-INSULT branch.
- Canonical content/behavior now clarifies ungrounded contextual acts and requires admitted repair for reconciliation. Added EN/TL generic clarification and made fallback apology wording ask for context. Source + generated outputs are kept together.
- Production-worker tests prove reset clarification, session/today/durable repair, repeated in-session closure and newer grievance admission. Generic Lua test covers repair/gratitude/response, swapped reply roles, wrong actor, expired strength and ambiguity.
- Lua 905/905 PASS. Focused worker/structural suites pass; two CodeBuilder generations are byte-identical across 223 generated/translation files. Kahlua/diff checks pass.
- Broad pragmatic Python baseline has four pre-existing failures, reproduced on an isolated `git archive bbaf2cd4` with the same Core checkout: P5 promotion paths (2), R9 structural-diff generated path (1), R2 visible phraseSemanticTemplateID expectation (1). Logs `/tmp/unified-baseline-regressions.log`; none is treated as new acceptance. Stale catalog-count and no-context THANK expectations introduced by this slice were updated to the current contract.
- Closure currently uses session evidence. Compact cross-session closure is intentionally pending E4B; do not mark E4 or the parent complete.

## E3B / E3 accepted (2026-10-28)

- Production adapters read at most 12 session turns, 8 TODAY triples, 20 relationship memories and 64 conduct entries; the shared result remains capped at 16. Relationship and Conduct expose bounded owner queries without journals/full-store export. No durable truth is inferred from compact `l`.
- Added bounded semantic-act relation registration for session projection. Owning social metadata is reused for hostility; reply/repair act participation is declarative. Resolver matching is still pending E4.
- Pragmatic diagnostics expose normalized rows and provider statuses. Production turn tests show SESSION/TODAY/DURABLE; serialize/reimport retains TODAY/DURABLE; permanent authoritative relationship evidence survives rollover without TODAY.
- Corrected SAVE synthetic-fixture actor identity alignment through the production PlayerCharacters owner and supplied its entity key to the existing dialogue context. Cached actor projections refresh evidence rather than reusing stale evidence rows.
- Full Lua suite 904/904 PASS; E0–E3 worker suite 6/6 PASS before final conduct adapter (E3 4/4 PASS after it); SAVE-backed P12J 2/2 PASS; conduct 2/2 PASS. Runtime Kahlua/syntax and diff checks PASS. Host-only test `package` use is intentionally outside PZ sandbox validation.
- Native client availability/transport and SP/MP acceptance remain to be checked with E5/E7; absent owner APIs currently contribute no evidence. No native process or source save was used.

## E3A accepted (2026-10-28)

- TODAY eviction uses canonical retention salience and oldest-first equal-salience ties; storage remains numeric triples with the eight-entry limit. Duplicate pairs still coalesce.
- Successful authoritative social events project compact memory even when detailed relationship retention prunes the proposed memory. No gameplay effect, new ModData root or persistence field was added.
- Production-worker tests prove 20-memory saturation with immediate effect and retained TODAY insult; high-salience rescue survives 45 lower-salience events, bounds/coalescing and day rollover pass. Serialized delta remains below 4000 canonical JSON bytes and roots unchanged. Relationship 5/5 and social-event smoke pass.

## E2 accepted (2026-10-28)

- All 24 first-party social event definitions explicitly carry domain-owned semantic/retention metadata (23 distinct memory types; praise is shared). Conversation Memory derives registration. Four former metadata files remain compatibility load delegates only.
- Preserved codes 1101..1104, existing hash aliases and `player_spoke_insult` code 1026626453. Unknown addons retain bounded hashed fallback. Existing persisted tuples need no migration.
- Retention salience, classes and relations are defined independently of effect strength, decay and NLU confidence. Intended grievance/help adopters no longer silently use salience zero.
- Production-worker metadata audit PASS for every first-party definition, existing fallback and stable codes. E0/E1 worker regressions PASS, semantic Lua 100/100 PASS, relationship 5/5 PASS, social events and compact memory smoke PASS, Kahlua/diff checks PASS.

## E1 accepted (2026-10-28)

- InteractionProviders exposes NormalizeEvidence, RegisterEvidenceAdapter and QueryEvidence; InteractionContext carries the read-only result. The cohesive schema/query spoke owns no facts or persistence.
- Limits: 16 adapters, 16 rows per adapter/result, 8 terms per class/relation/tag list, 128 characters per identifier. Fixed relation keys; only explicit fields copied. Adapter callback failure contributes no evidence; diagnostics are bounded. Target/class/relation selection and deterministic SESSION/TODAY/DURABLE ordering are tested.
- Production-worker tier fixtures PASS; provider seam smoke PASS; existing provider smoke PASS; semantic Lua 100/100 PASS; Kahlua verifier and diff check PASS. New paths are untracked in the old graph generation and were read directly.

## E0A accepted (2026-10-28)

- Added disposable production-worker storage fixture and `test_unified_evidence_e0.py`; no native runtime or source saves are used.
- Machine capture: `E0_BASELINE.json`, production semantics at bbaf2cd4. Reset APOLOGIZE gives “Noted. Let's move on.”; same-session insult/apology selects reconciliation; serialized same-day replay retains the compact insult triple but lacks contextual admission.
- Saturation: 20 permanent memories; insult applies immediate effect while detailed memory is pruned and compact TODAY is missing. This confirms the E3 projection defect.
- Durable event projection survives day rollover in `l`; `s` is removed. Existing limits are 8 triples, 6 quadruples, 20 relationship memories, 64 conduct evidence entries. Session shape is captured without copying text/history into persistence.
- Ordinary serialized record: 2693 -> 4354 canonical JSON bytes (+1661). These measure production serializer output transported as canonical JSON, not Java binary allocation overhead. Root set unchanged.
- Worker close/open reloads its source fixture, so cross-conversation persistence is additionally tested by serializing and importing into a new isolated worker. No source save mutation.
- Validation: E0 worker test PASS; social-event smoke PASS. Graph generation 2026-10-24 is stale/untracked for newer semantics/harness files; direct source fallback used for those owners.
- Ranking contracts remain as specified in ARCHITECTURE.md: confidence is certainty, salience retention importance, effective strength domain decay, recency age, contextual relevance ephemeral fit, priority deterministic catalog order.

## Accepted foundation

Do not redo these systems merely because this goal depends on them:

- PsychopatzCore generic NLU/candidate/DialogueTurn path;
- bounded Hoomans DialogueContextState;
- compact Conversation Memory s/t/l storage;
- Relationship and Conduct authorities;
- InteractionProviders / InteractionContext;
- Pragmatic Resolver / Interaction Director;
- generated affordances / native Response Channel;
- UtterancePlan / Dialogue Content / CodeBuilder;
- prior Pragmatic Dialogue C0-C11 + L0-L5 developer acceptance.

## Known gaps to prove/fix

- ungrounded APOLOGIZE currently reaches a generic acceptance-like response;
- InteractionProviders has no canonical evidence projection;
- social-event metadata and Conversation Memory event metadata are separately authored;
- most first-party social events can fall through dynamic memory typing with salience 0;
- TODAY short retention is recency-only;
- compact today projection depends too strongly on successful detailed relationship-memory retention;
- generic semantic relation/obligation matching does not yet exist;
- interactionJournal is too heavy to become semantic authority.

## Parent completion boundary

Not complete until E0-E7 pass, including synthetic extensibility fixture and storage stress gate. Fixing apology alone is insufficient.

## Safety

No native PZ launch, Workshop publication, source-save mutation, new branch, transcript persistence, new semantic ModData root, or feature-specific parallel resolver/memory subsystem.
