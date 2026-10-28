# Progress — Coherent Emergent Conversation

**Status:** IN PROGRESS.
**Current phase:** C5 — storage topology and compiler context-health.
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

## Immediate Next Chunk — C6

Implement dynamic semantic player affordances through the existing DialogueSuggestions provider/ranking path.

Read `DYNAMIC_CONVERSATION.md` before implementation.

Start by defining the bounded generated-affordance candidate contract and one provider that derives eligible positive/negative/neutral/contextual strategies from the current DiscourseFrame, active flow/beat, relationship/trait/world context and capability availability.

Preserve authored/static candidates. Do not create a second button engine, do not generate free-form text as authority, and do not reparse displayed button wording through NLU.

C6 acceptance must prove:

- candidate origin, stance, strategy and contextual provenance are explicit;
- authored choices remain available;
- positive/negative/contextual generated choices appear only when semantically eligible;
- trait/context-derived choices do not leak private NPC facts;
- ranking/deduplication prevents near-duplicate button spam;
- generated button clicks carry the typed semantic frame through the existing semantic-click path;
- typed utterance and equivalent generated-button semantics converge on the same downstream result.

## Remaining mandatory work

C6 dynamic semantic affordances → C7 compositional utterance realization → C8 discourse continuity → C9 conduct-memory decoupling → C10 observability/fuzzing → C11 integrated acceptance.

## Safety

- no new branch;
- preserve unrelated user work;
- no Workshop publication;
- no native PZ launch for ordinary developer acceptance;
- no source-save mutation;
- no root `AGENTS.md` goal-state edits;
- no hand-editing generated runtime artifacts; generated Conversation output changes only through CodeBuilder.
