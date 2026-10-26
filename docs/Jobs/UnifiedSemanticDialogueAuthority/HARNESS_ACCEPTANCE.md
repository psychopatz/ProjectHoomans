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
- migration matrix shows no Project Hoomans first-party legacy prose selector with semantic authority.
