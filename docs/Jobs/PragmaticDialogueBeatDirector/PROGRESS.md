# Progress — Coherent Emergent Conversation

**Status:** IN PROGRESS.
**Current phase:** C9 — social effect / conduct-memory decoupling.
**Branch:** existing `main`.

## Accepted foundation

The prior Pragmatic Interaction Director recovery R0–R9 remains protected.

C0–C4 are now developer-accepted on the paired ProjectHoomans / PsychopatzCore checkout. C0A reports under `tools/semantic_harness/reports/c0a/` are immutable historical pre-C1 evidence; later phases must not rewrite them to match improved runtime behavior.

PsychopatzCore C1 implementation is committed at `3744a7dfab00b2b97e86141f0fd25664523de92b`.

Accepted behavior:

- Core `ParseCandidates()` supports bounded registry-derived compact/no-space recovery, conservative expressive elongation, common contraction recovery, unique vocabulary segmentation, recovery costs and provenance. Exact parsing remains the preferred path and recovered mutating actions are not silently authorized.
- ProjectHoomans composes social features after semantic interpretation: recipient/self/world directedness, hostility, affiliation, threat, contempt, distress and intensity are bounded projections rather than a second sentiment parser.
- Specific grammar now distinguishes malicious wish vs threat, world complaint vs recipient hostility, intensified self-state vs identity claim, and negated-negative assessment vs insult.
- The Contextual Discourse Resolver consumes Core candidates plus existing bounded DialogueContextState. It attaches one explainable DiscourseFrame with pending interaction, topic, subject, reply-to, contextual support and evidence without reparsing raw text.
- Risk-aware admission separates conversation/read-only interpretation from gameplay mutation. Context may reinforce safe conversation; exact high-confidence mutations stay strict; safe fuzzy movement preserves the existing FOLLOW/STOP/STAY contract; recovered mutation is blocked; exact open-text item/world binding may defer only to existing authoritative selectors; typo-like fuzzy inventory/task interpretations clarify.
- C0A characterization tests now read the historical snapshots instead of comparing them to the continuously improving live worker.

Current validation:

- Core surface-recovery smoke: PASS.
- Core semantic pattern-matcher smoke: PASS.
- C0 historical + C1–C4 live Python harness: 24/24 PASS.
- C4 direct risk-policy smoke: PASS.
- full ProjectHoomans `pnc_semantic` Lua suite: 99/99 PASS.
- `git diff --check`: clean before phase transition.

## C5 accepted — storage topology and compiler context-health

C5 is developer-accepted.

Accepted storage/compiler behavior:

- canonical source ownership now drives generated semantic shard names instead of broad-domain numeric overflow splitting;
- oversized canonical sources were split into semantically named source directories while preserving deterministic recursive discovery;
- generated Conversation output contains no numeric `PartNN` shards and no opaque `Massive` / `Sgd` ownership names;
- lightweight discovery indexes map stable IDs to canonical source, generated shard, bounded related IDs and dependents without duplicating full definitions;
- bounded affected-closure metadata is exposed through the compiler/authoring service;
- compiler-owned context-health checks enforce source/shard/index budgets and ownership/naming invariants before output is accepted;
- runtime combinations remain ephemeral; C5 does not add transcript or ModData persistence.

Latest C5 validation:

- C5 context-health + compiler acceptance: **13/13 PASS**;
- context-health status: **pass**, 0 errors, 0 numeric violations, 0 opaque violations, 0 missing ownership;
- largest canonical source: `content/social/emotes/reply.json` at **14,624 bytes**;
- largest generated artifact in the health report: bounded task index at **31,376 bytes**;
- canonical source tree unchanged across two full builds;
- generated Conversation tree: **132 files**, byte-identical across two consecutive full generations;
- C0 historical + C1–C4 live harness: **24/24 PASS** after C5 generation;
- full ProjectHoomans `pnc_semantic` Lua suite: **99/99 PASS** after C5 generation.

## C6–C8 accepted — dynamic affordances, compositional realization and continuity

C6–C8 are developer-accepted as one coherent conversation slice.

Accepted C6 behavior:

- `DialogueSuggestions` remains the sole player-choice authority; generated choices enter through one registered `projecthoomans.generated_affordances` provider and the existing ranking/deduplication path;
- generated candidates expose explicit `origin`, `stance`, `strategy`, typed semantic frame and bounded contextual evidence;
- hostile conversational meaning can produce repair/challenge/dismiss/follow-up lanes, while player traits add only eligible contextual choices such as `CALL_BLUFF` for `Brave`;
- player-trait provenance does not inspect or expose private NPC personality/trait values;
- ordinary authored/static choices remain present and authored `await_player` offers suppress redundant generated alternatives;
- generated button clicks submit their typed semantic frame directly through the existing semantic-click path. Display wording is never reparsed through NLU;
- generated APOLOGIZE and typed `sorry` converge on the same social branch and reconciliation beat.

Accepted C7 behavior:

- compiler-owned `realization` shards are first-class C5 citizens with source ownership, generated semantic shard names and discovery-index routing;
- `UtterancePlan` consumes canonical semantic concepts and safe slots only; arbitrary raw player text is not concatenated into output;
- EN/TL locale constructions are independently authored and generated;
- an aggressive NPC can receive recovered/fuzzy hostility and select `RETALIATE_VERBALLY/MIRROR`, producing EN `fuck you too.` or TL `Putang ina mo rin.` from reusable lexeme + construction records;
- the authoritative response still retains its canonical Dialogue Content template/fallback; compositional realization affects presentation only and unsupported plans fall back to ordinary Dialogue Content;
- grounded knowledge phrase families now preserve their concrete topic/answer arguments rather than collapsing to generic style text.

Accepted C8 behavior:

- short replies bind to the existing pending interaction through the C3 DiscourseFrame;
- generated follow-up buttons explicitly reply to the current NPC response plan/topic and preserve canonical topic identity through semantic-click conversion;
- hostility → generated apology exits argument escalation and enters reconciliation, with stale hostile affordances removed from the next surface;
- grounded referents remain reusable through existing bounded mention/focus state;
- topic interruption/resumption continues to use existing flow/dialogue state; no transcript store or new persistent conversation memory was added.

Latest C6–C8 validation:

- focused C6/C7 acceptance: **8/8 PASS**;
- focused C8 acceptance: **5/5 PASS**;
- combined C0–C8 / legacy continuity / C5 compiler acceptance: **64/64 PASS**;
- full ProjectHoomans `pnc_semantic` Lua suite: **99/99 PASS**;
- canonical Conversation source tree remains byte-stable across two full generations;
- generated Conversation tree: **136 files**, byte-identical across two consecutive full generations;
- `git diff --check`: PASS.

## Immediate Next Chunk — C9

Decouple semantic/social reaction success from bounded conduct-memory persistence.

Start from the existing conduct saturation baseline. Preserve bounded persistence, but represent separately:

- interaction understood/accepted;
- reaction/behavior selected;
- relationship/social effect applied or rejected by its own authority;
- durable conduct evidence persisted, coalesced, pruned or dropped by capacity policy.

A full conduct ledger must never turn an otherwise understood social interaction into a semantic rejection merely because another evidence row cannot be retained.

## Remaining mandatory work

C9 conduct-memory decoupling → C10 observability/fuzzing → C11 integrated acceptance.

## Safety

- no new branch;
- preserve unrelated user work;
- no Workshop publication;
- no native PZ launch for ordinary developer acceptance;
- no source-save mutation;
- no root `AGENTS.md` goal-state edits;
- no hand-editing generated runtime artifacts; generated Conversation output changes only through CodeBuilder.
