# Harness Acceptance — Unified Semantic Dialogue Authority

All acceptance uses the existing production Lua worker/Semantic Lab. Python is orchestration/presentation, not dialogue authority.

## Acceptance matrix

| Gate | Required proof |
| --- | --- |
| A. Authority inventory | Every first-party Flavor/ToolReply/legacy-registry production path is classified and mapped to a semantic/content owner or explicitly retained generic compatibility boundary. |
| B. Single semantic selection | Representative migrated events call semantic response selection once and carry response plan/realization/fact provenance into presentation. |
| C. No hidden first-party prose fallback | Project Hoomans semantic-owned packets cannot silently call generic SocialFlavor prose resolution when selected text/realization is missing; tests fail loudly or use explicit semantic fallback. |
| D. Content migration | Accepted authored EN/TL wording remains available through Dialogue Content/translation ownership or a documented equivalent content backend below semantic authority. |
| E. NPC-initiated follow-up | Delivered event speech records the existing lifecycle beat/eventRef/facts/offers and exposes grounded follow-up choices/typed resolution through existing Suggestions/ContextResolver. |
| F. Typed/click parity | Equivalent typed and clicked follow-ups converge on the same semantic answer/plan when appropriate. |
| G. Grounding/privacy | Follow-ups use authoritative fact refs/Knowledge/disclosure; unknown/private/stale facts do not become invented answers. |
| H. Legacy conversation categories | wellbeing/small-talk/ask-about no longer report `conversation_registry` as conversational authority. |
| I. ToolReplies retirement | ToolReply literal tables no longer choose production conversational wording for migrated first-party outcomes. |
| J. Presentation-only SocialFlavor | Queue/cooldown/TTL/TTS/nameplate/Conversation behavior remains, but swapping presentation does not change semantic plan/variant. |
| K. Compatibility | Bandits/Necroa/Project ALife facts adapt into semantics without stealing provider gameplay authority; generic Core compatibility remains intact. |
| L. Persistence/scale | No transcript text, no new Player×NPC preallocation, no per-tick scan, bounded thread/event/offer state, source saves unchanged. |
| M. Observatory/Studio | Migrated families expose semantic owner, content owner, EN/TL, event/fact provenance and follow-up affordances through existing tooling without a second editor. |
| N. Performance | Event selection/follow-up projection/startup/regression remain within measured practical budgets; no duplicate semantic evaluation. |

## Required scenario set

At minimum prove through real production Lua:

1. conversation farewell;
2. conversation safety/danger;
3. witnessed player kill or equivalent combat reaction;
4. teammate hurt / medical distress;
5. follower abandonment;
6. horde detection;
7. incapacitated call/update/repeat;
8. leader death;
9. one social ToolReply;
10. ask-name ToolReply path;
11. one companion order result;
12. wellbeing;
13. small-talk;
14. ask-about/context question;
15. Bandits or Necroa compatibility event;
16. Project ALife event.

## Required follow-up scenarios

### Horde

- event produces canonical event/fact refs;
- semantic combat/horde response is selected;
- NPC speaks once;
- existing lifecycle response window exposes eligible “where/how many/what happened” style semantic offers;
- typed and clicked equivalent follow-up resolve against the same event context;
- stale/current-state location is revalidated or answered with uncertainty.

### Medical/incapacitated

- health remains authoritative;
- NPC semantic distress line is delivered;
- follow-up offers only facts actually known;
- “what do you need?” resolves without duplicating health state.

### Leader loss

- faction event remains canonical;
- grief reaction is selected semantically;
- follow-up uses same event ref;
- “what now?” can query current succession/faction state without rewriting event history.

## Negative tests

- semantic-owned presentation packet with missing selected realization must not silently pick a first-party Flavor prose line;
- deleting/substituting SocialFlavor definition tables for migrated families must not alter semantic selected pool/variant/plan;
- follow-up is not offered to an unrelated player/NPC pair;
- expired response window does not surface stale offer;
- private/unknown fact is not disclosed;
- repeated event does not create unbounded pair/thread state;
- Conversation open does not scan all NPCs/events/catalog pools.

## Content/translation checks

- EN/TL placeholder parity;
- normal translation values remain strings;
- Dialogue Content generation is deterministic/idempotent;
- phrase variants do not consume semantic variant slots merely for synonyms;
- migrated content has one canonical owner.

## Performance/data checks

Capture and compare:

- worker startup;
- event response selection;
- event speech delivery;
- follow-up suggestion projection;
- typed follow-up answer;
- many-event bounded stress;
- dormant many-NPC case;
- lifecycle/pair serialized size where relevant;
- full headless + focused GUI suite timings.

Source-save hashes must remain unchanged.

## Final developer gate

Before `READY FOR USER LIVE TEST`:

- focused migration tests green;
- full headless semantic-harness Python suite green;
- focused Xvfb GUI/Observatory acceptance green;
- full native Lua suite green;
- installed-PZ Kahlua verification green;
- CodeBuilder/Dialogue Content idempotence green;
- save/data-safety checks green;
- `git diff --check` green;
- migration matrix shows no Project Hoomans first-party legacy prose selector with semantic authority;
- P10 no-legacy/source/schema/Studio gates in `P10_CANONICAL_SEMANTIC_CLEANUP.md` pass.


## P10 no-legacy acceptance extension

The earlier P8/P9 gate proved that legacy prose was no longer semantic
authority. P10 raises the steady-state requirement from "non-authoritative" to
"absent from Project Hoomans production architecture."

Required negative checks:

- no `PNC_SocialFlavorDefinitions*` source;
- no `PNC_ConversationToolReplyCatalog.lua`;
- no Project Hoomans CompanionCommandFlavor wording registry;
- no `PNC.FlavorText` / `PNC.FlavorTextConst`;
- no first-party semantic packet depending on `Flavor.Resolve`;
- no `.migrated.` family ID in canonical Dialogue Content;
- no `MIGRATED_*` content concept;
- no `legacySource` in canonical Dialogue Content;
- no worker/composition load of a deleted legacy file.

Required positive checks:

- former command/emote/greeting content resolves through ResponseCatalog →
  SpeechRealization → Dialogue Content;
- social/medical/compatibility content remains EN/TL-equivalent;
- semantic context/address behavior remains equivalent after rename/merge;
- Studio Responses and Dialogue Content are hierarchical, searchable and
  traceable to exact canonical IDs;
- generated outputs are deterministic across two consecutive builds;
- PBrainZ and compatibility adapters still consume canonical semantic
  realization/context;
- full P9 regression topology remains green.

Final broad acceptance must use the resource-aware Python runner introduced in
P9, not plain serial full `unittest discover`.

## P11 modular Conversation acceptance extension

P11 is accepted only when the following additional gates pass.

### Source/authority

- no live `LEGACY_TEXT_FALLBACKS` or equivalent first-party wording fallback;
- no dead migration-only `legacyRegistry`, `migrationPhase`, `legacyTrace`
  fields in production contracts;
- no first-party `Responses.json` / `Realizations.json` independent wording
  authority;
- Dialogue Content is the traceable first-party wording owner;
- one canonical Conversation UI/navigation registry exists;
- gameplay/domain services remain authoritative for eligibility/effects.

### Taxonomy/modularity

- no canonical `semantic.generated.*` response taxonomy;
- generator origin remains inspectable metadata;
- Conversation content is domain-sharded;
- NLU/pattern sources do not embed response wording merely for convenience;
- global ID uniqueness and deterministic compilation are enforced.

### Human authoring

- selecting a phrase family can edit EN/TL and add/duplicate/delete/reorder
  variants through structured controls;
- selecting a landing/hub/choice can edit labels/utterances and
  add/remove/reorder existing registered semantic children;
- What's Up child membership can be changed without editing production Lua;
- dynamic provider eligibility is visibly locked and still production-owned;
- stale edits are rejected;
- preview/review is effect-free until explicit write;
- normal editing does not require raw JSON.

### Agent authoring

- bounded machine-readable inspect/edit/add/remove/reorder APIs exist;
- GUI and agents use the same service contract;
- generated artifacts are never edited directly;
- validation/diagnostics are deterministic and machine-readable.

### Studio

- one Conversation explorer replaces the everyday Responses/Interactions split;
- route/conditions/follow-ups/sources remain inspectable for the selected item;
- Sources stays read-only;
- Review stays centralized;
- branch counts are unambiguous.

### Regression

- every coherent P11B+ runtime/wording migration slice must pass the full native Lua suite before it is accepted or used as a base for the next slice;
- tests that predate the slice remain contract evidence and must not be mechanically rewritten to accept changed keys/text/`nil` behavior without explicit parity proof;
- no broad runtime-key alias registry may be used to declare one-wording-authority acceptance while old production callers remain unmigrated;
- typed/clicked parity remains;
- task/command/gift automatic flows retain behavior after ID migration;
- event follow-up grounding/privacy remains;
- PBrainZ and compatibility adapters remain green;
- source saves remain unchanged;
- resource-aware Python, focused Xvfb, native Lua, installed-PZ Kahlua,
  CodeBuilder idempotence and performance gates remain green.

P11 is not complete merely because the new editor renders. It must prove that
the old parallel wording/navigation authoring paths are removed or reduced to
explicit external provider boundaries.
