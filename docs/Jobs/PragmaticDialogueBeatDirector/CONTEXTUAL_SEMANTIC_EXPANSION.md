# Next design: compositional understanding and contextual social admission

Status: SUPERSEDED AS AN EXECUTION PLAN. The symptom/requirements remain useful evidence, but implementation ownership moved to `docs/Jobs/UnifiedSemanticEvidenceArchitecture/` so contextual memory, salience and pragmatic admission are standardized once rather than built as an apology/social-only subsystem. Existing C0–C11/L0–L5 foundation remains accepted.

## Live symptom and distinction

In the Semantic Lab SAVE-backed simulation, player input `im sorry` produces Core candidate `APOLOGIZE` at 0.95 (contraction recovery, two eligible candidates, selected contextual margin 0.04). The NPC says `Noted. Let's move on.` The visible screenshot shows no preceding offense or apology-requiring exchange after scenario reset, and no native conversation is open. This is evidence of an inappropriate apparent acceptance, not proof of an actual relationship mutation. Check the production replay/decision/authority trace before claiming a gameplay effect.

**Recognition is not admission.** Generic Core NLU may identify a well-formed APOLOGIZE without context. Only Hoomans discourse/pragmatic authority may resolve *what the apology is for*, whether it refers to the NPC, whether the NPC was offended, and whether accept/reject/clarify is appropriate. No blanket suppression of the input, hard-coded string exception, or unconditional forgive/repair.

## Contextual apology contract

A contextual apology interpretation should carry:
- recognized speech act and candidate provenance;
- addressed party and target of apology (NPC/player/third party/unclear);
- referenced offense or incident ID, if grounded;
- evidence source: active beat, recent semantic acts, explicit incident reference, pending social obligation, or relevant authoritative remembered event;
- recency and confidence; expiry/consumption state for outstanding repair opportunities;
- admission outcome: GROUNDED_REPAIR, EXPLICIT_BUT_UNRESOLVED, GENERAL_POLITENESS, IRRELEVANT_TO_TARGET, or AMBIGUOUS;
- permitted dialogue action, separate from permitted relationship/memory mutation.

No apology-acceptance or forgiveness claim without eligible grounded repair context. An unprompted `I'm sorry` can elicit `What for?`, `About what?`, cautious concern, or other contextually appropriate neutral reaction; it must not imply a real grievance was already resolved. A genuinely grounded recent insult, betrayal, harmful action or offended NPC may enable acceptance, skepticism, rejection or guarded reconciliation according to the NPC's personality, relationship and actual conduct; mere apology does not automatically erase consequences. Apologies for unrelated third-party events should be interpreted as sympathy where justified, not forgiveness by the target NPC.

Store only bounded semantic obligations/incident references where existing context and social memory already allow them. Never persist whole transcripts, dynamically generated sentences or parallel grievance records. Keep authority on the server for mutating consequences.

## Generalize to all social dialogue acts

Treat THANK, ACCEPT, REFUSE, AGREE, DISAGREE, ACKNOWLEDGE, COMFORT, JOKE/REFRAME, PRAISE, THREAT, and CHALLENGE analogously: recognition of a speech act alone cannot imply that an offer, wrongdoing, compliment, allegation or question exists. Contextual outcomes may be grounded, unrelated, ambiguous or non-mutating. Do not apply an apology-specific patch that leaves the same defect elsewhere.

## Compositional turn upgrade

Preserve Core's one-parser architecture and backwards-compatible single-clause contract. Audit and extend the existing bounded DialogueTurn and Hoomans Discourse Resolver so compatible multi-act meaning survives even if a broad whole-turn pattern matches; handle unpunctuated coordination, contrast, negation, corrections and counterquestions conservatively. Represent a primary act plus bounded secondary acts and relation edges (answers, thanks, contradicts, qualifies, corrects, reframes, asks-reason, changes-topic). Context decides adjacency/reference, not a second tokenizer or semantic engine. Uncertain clauses may trigger clarification and must never lower mutation thresholds.

## Generated choices and natural realization

Use admitted contextual commitments to generate appropriate reply strategies. The NPC asking `What are you apologizing for?` should show context-appropriate player replies; it must not generate `I was joking` unless a joke/reframe antecedent exists. Widen positive/negative/neutral and trait-conditioned affordances beyond hostility, with explainable eligibility. Extend existing UtterancePlan/locale-owned EN/TL constructions to new admitted behavior acts without hard-coded full-sentence branches or raw profanity echo. Grounded mirroring expands via canonical semantic insult categories; never reproduce arbitrary raw input. Every button must remain a typed frame on the native Response Channel.

## Acceptance plan — follow existing real-worker authority

1. Reproduce `im sorry` against reset SAVE-backed and disposable fixture contexts; distinguish Core recognition, discourse evidence, decision/InteractionPlan, generated options, final NPC line, and actual relationship/social effects. Source saves read-only.
2. Add paired positive/negative cases: no grievance, earlier insult, active reconciliation, expired/consumed grievance, unrelated NPC, third-party tragedy, apology after unrelated factual question, repeated apology, NPC defensive/forgiving profiles, EN/TL. Assert no fabricated apology acceptance or unearned relationship mutation.
3. Prove typed input, generated button, and NPC-generated act parity; no leaked inactive Response Channel rows before conversation open. Include native-shaped client projection and current-turn session choices.
4. Test multi-act turns, including `im fine thanks but why are you asking`, `sorry I was joking don't get mad`, `yeah but I'm not going`, and explicit ambiguity/safety controls. Retain conservative action gates and no phantom consequences.
5. Extend contextual choice strategies, realization variants and canonical lexemes through CodeBuilder's atomic sources; regenerate twice byte-identically, compare EN/TL, validate context-health, avoid numeric/opaque shards and hand-edited generated Lua.
6. Run focused Core + Hoomans Lua and Python production-worker regression, interaction/memory/conduct tests, paired checkout verification, Kahlua check, source-save immutability, bounded trace/storage/performance checks; native SP/MP remains user-owned.

Do not mark the parent improvement complete merely because `im sorry` now gives one correct line. Developer acceptance requires generalized context admission, multi-act behavior, visible choice parity, and no regressions.