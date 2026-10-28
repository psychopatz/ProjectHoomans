# Progress — Coherent Emergent Conversation

**Status:** IN PROGRESS.
**Current phase:** C11 — integrated acceptance and live-test handoff.
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
- generated follow-up buttons prefer the current open NPC pending interaction over the preceding player classifier, so greeting/wellbeing questions yield typed positive/neutral/negative self-state answers and identity questions yield safe name-disclosure/evasion choices;
- pending-question affordances carry explicit `replyTo=pending_interaction`, flow/topic identity, typed slots and self-directed social context; clicking them retires/cancels the same existing flow rather than starting a parallel button state machine;
- generated wellbeing answers and equivalent typed self-state replies converge on `SELF_STATE_RECEIVED` and the same flow transition;
- generated identity disclosure uses the already-known player name as a bounded safe slot; private NPC traits/personality are not exposed;
- hostility → generated apology exits argument escalation and enters reconciliation, with stale hostile affordances removed from the next surface;
- grounded referents remain reusable through existing bounded mention/focus state;
- topic interruption/resumption continues to use existing flow/dialogue state; no transcript store or new persistent conversation memory was added.

Latest C6–C8 validation:

- focused C6/C7 + C8 acceptance: **14/14 PASS**;
- combined C0–C8 + legacy referent/interruption/flow continuity: **52/52 PASS**;
- full ProjectHoomans `pnc_semantic` Lua suite: **99/99 PASS**;
- canonical Conversation source tree remains byte-stable across two full generations;
- generated Conversation tree: **136 files**, byte-identical across two consecutive full generations;
- context-health: **pass**, 0 errors, 0 numeric shard violations, 0 opaque shard violations;
- `git diff --check`: PASS.

## C9 accepted — social effect / conduct-memory decoupling

C9 is developer-accepted.

Accepted behavior:

- direct `Conduct.AddEvidence()` remains a strict bounded-storage API and still reports `evidence_pruned_by_limit` / `permanent_evidence_limit` to callers that explicitly request durable evidence;
- social-event preparation treats ordinary capacity pruning as a bounded persistence outcome rather than a reason to reject an otherwise valid relationship/social interaction;
- authoritative social-event results now separate `relationshipsChanged` / relationship memory from `conductEvidenceCreated`;
- `conductPersistence` records each evidence attempt as `persisted`, `pruned` or `dropped` with the original capacity reason and durable flag;
- `conductEvidenceOutcome` summarizes persisted/pruned/dropped counts and reports `bounded` when storage capacity prevents retention;
- the semantic-dialogue social authority forwards these conduct outcomes independently from its accepted relationship effect;
- a saturated all-permanent player conduct ledger can receive a hostile social interaction, apply the NPC relationship/memory reaction, report zero durable conduct evidence created, and remain at the same bounded evidence count.

Latest C9 validation:

- authoritative social-event suite: **12/12 PASS**;
- conduct suite: **2/2 PASS**;
- C0A direct conduct-saturation characterization remains PASS;
- full ProjectHoomans `pnc_semantic` Lua suite: **99/99 PASS**;
- bounded conduct storage size is unchanged by pruned social evidence.

## C10 accepted — Semantic Lab observability and fuzz/regression

C10 is developer-accepted.

Accepted behavior:

- the existing Conversation Inspector now exposes bounded sections for surface normalization/recovery, candidate arbitration, DiscourseFrame/social features, generated affordances, selected semantic-click frame, pragmatic/interaction state, UtterancePlan/realization, storage ownership and social-effect/conduct-memory outcomes;
- queue-ready response payloads preserve presentation-only UtterancePlan/realization metadata for the inspector without changing semantic/action authority;
- storage pointers resolve compiler-owned canonical IDs to source path, generated shard, bounded related/dependent IDs and context-health status through the C5 discovery model; unresolved non-Conversation catalog IDs remain explicitly unresolved instead of being guessed;
- social interaction projection separates understood semantic act, selected reaction/beat/behavior, relationship effect and conduct persistence outcome;
- the existing human-readable Conversation Inspector rendering shows the new bounded chain before the separate command-authority section;
- the bounded real-worker mutation matrix covers compact spacing, repeated letters, punctuation/capitalization, safe social typos, safe fuzzy movement, unsafe item typos and intensified self-state controls;
- fuzz rows report only compact semantic/risk/authority facts and never persist a transcript or giant worker snapshot.

Latest C10 validation:

- focused C10 chain/fuzz acceptance: **3/3 PASS**;
- Conversation Inspector + Semantic Lab persona regression: **12/12 PASS** including C10;
- full ProjectHoomans `pnc_semantic` Lua suite: **99/99 PASS**;
- fuzz safety controls: PASS, including zero transport for the unsafe item-typo case;
- Python compilation, Lua syntax and `git diff --check`: PASS.

## Immediate Next Chunk — C11

Run the final integrated acceptance matrix across C0–C10 plus NPC-to-NPC interaction regression, generation idempotence/context-health, bounded performance, source/save immutability and no transcript/ModData bloat.

Do not launch or publish Project Zomboid. When all developer gates pass, update this ledger to **READY FOR USER LIVE TEST** and leave native gameplay verification to the user.

## Remaining mandatory work

C11 integrated acceptance and live-test handoff.

## Safety

- no new branch;
- preserve unrelated user work;
- no Workshop publication;
- no native PZ launch for ordinary developer acceptance;
- no source-save mutation;
- no root `AGENTS.md` goal-state edits;
- no hand-editing generated runtime artifacts; generated Conversation output changes only through CodeBuilder.
