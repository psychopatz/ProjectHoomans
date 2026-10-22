# Contextual Dialogue Persona & Choices — Current Progress

**Updated:** 2026-10-22  
**Parent status:** REOPENED — P8 developer foundation passed, but P9 UI/direct-routing acceptance is mandatory.  
**Current mandatory phase:** P9A — Direct category routing + full-block graph projection.  
**Current remote main baseline inspected:** `81f4fb982ff5f65024ec9003d1a0a6f08ea7d1f4`.  
**Native Project Zomboid SP/MP:** UNTESTED / user-owned.

## Accepted foundation

Preserve the completed P8 work:

- production ActorConversationContext;
- friend/family/lover bond classes with detailed kinship kinds;
- production-derived relationship state/hysteresis in the Lab;
- broad speech realization coverage and EN/TL infrastructure;
- generic registered choice-provider discovery;
- Dynamic Trading ownership/adoption;
- persona/relationship replay and matrix worker support;
- existing Semantic Lab Studio Flow Graph;
- existing typed semantic click, stale/replay, privacy, and gameplay-authority boundaries.

The P8 regression evidence remains useful. P9 exists because the user-facing Simulation experience and one category-entry route are still incorrect.

## 2026-10-22 user-facing audit findings

The supplied Semantic Lab screenshots and current source show:

1. typing `whatsup` is correctly recognized as `CONVERSATION_TOPIC` / `projecthoomans:whats_up`;
2. the UI then displays the generic `Let me think about that.` response;
3. the suggestion surface contains only `Ask what's up`, requiring the player to repeat the semantic intent through a button;
4. current tests explicitly encode this second-click behavior;
5. clicking the category button already routes correctly through `Composer.RequestCategory`;
6. the authored What's Up block already contains a multi-node branching tree with translated choices, gates, outcomes, and root exits;
7. `BuildSemanticBlockProjection` exposes only the current node, so Simulation cannot visualize the complete authored branch;
8. Studio's existing Flow Graph already provides reusable zoom/pan/fit/node/edge rendering, but it only consumes semantic Flow definitions;
9. Simulation gives large visual priority to raw semantic JSON while branch structure is invisible;
10. the single-group combobox creates unnecessary nesting such as `What's up -> Ask what's up`;
11. several TL What's Up content files contain mixed-language strings; this is a later content-diagnostic issue, not the cause of the route bug.

## Superseded handoff

The former P8E **READY FOR USER LIVE TEST** statement is superseded.

The current product blocker is not persona infrastructure. It is **conversation testability and direct authored-category routing**.

## Current Exact Next Chunk — P9A

On the user's real local checkout:

1. read root `AGENTS.md` and the ContextualDialoguePersonaChoices documents in the documented order, including `SEMANTIC_LAB_CONVERSATION_VISUALIZATION.md`;
2. verify local ProjectHoomans/Core/DynamicTrading branch, HEAD, upstream/divergence, dirty/concurrent edits; existing `main` only;
3. reproduce the current worker behavior:
   ```text
   input("whatsup")
    -> CONVERSATION_TOPIC / conversation_category
    -> generic unknown-fact NPC line
    -> conversation.whats_up suggestion
   ```
4. trace `DialogueInput.Submit`, `SubmitSingle`, semantic policy/presentation, `SubmitSemanticFrame`, `Composer.RequestCategory`, worker input routing, and suggestion rebuilding;
5. change the typed recognized category path so the already-canonical `conversation_category` meaning reaches the existing category authority/composer route directly;
6. do not execute category effects in the parser itself; reuse the existing semantic-frame/category boundary;
7. preserve the root `Ask what's up` option before category entry;
8. suppress the redundant exact self-category suggestion once that typed category has just been entered;
9. replace the current tests that require a second `conversation.whats_up` click;
10. add a bounded Semantic Lab developer projection of the full selected authoritative ConversationBlock:
    - all nodes;
    - resolved NPC text;
    - authored choices;
    - enabled/locked state and safe reason;
    - outcomes;
    - targets;
    - root exits;
    - current node;
    - canonical IDs/source metadata;
11. do not broaden the normal in-game current-choice projection beyond the current node;
12. add focused worker tests for aliases/fuzzy reviewed What's Up, root-button entry, direct typed entry, hostile/busy fail-closed behavior, graph projection, stale/replay compatibility;
13. update this ledger with exact evidence and proceed immediately to P9B when P9A passes.

## P9A acceptance

The real worker must prove:

```text
PLAYER: what's up?
  -> recognized canonical category
  -> selected authored What's Up block
  -> authored opening NPC text
  -> actual opening choices
  -> no redundant "Ask what's up" self-candidate
```

The developer graph projection for the selected block must include the complete opening/details/personal/followup/closing structure while the ordinary production suggestion surface remains current-node bounded.

## Next milestones

After P9A, continue autonomously:

- **P9B:** put the live read-only conversation graph in Simulation immediately so the user can test it;
- **P9C:** refactor Studio/Simulation onto shared graph rendering primitives;
- **P9D:** make available live graph branches clickable through the same semantic click frame as normal choices;
- **P9E:** simplify Simulation layout around transcript + graph + choices + input, hide pointless single-group navigation, demote raw JSON;
- **P9F:** add graph-backed translation/source diagnostics and expose known mixed-language authored content;
- **P9G:** final direct-route/graph/Studio/persona/provider/Tk/Lua/Kahlua/persistence regressions.

See `SEMANTIC_LAB_CONVERSATION_VISUALIZATION.md` for full milestone contracts.

## Early user-test checkpoint

Do not wait for P9G before making the UI useful.

Once P9B passes, Semantic Lab should already support:

```text
launch Simulation
 -> type "what's up"
 -> see real authored NPC opening
 -> see complete branch graph
 -> see current outgoing choices
 -> click a normal choice
 -> watch current-node highlight advance
```

That is the first required visible usability milestone.

## Handoff condition

Do not report **READY FOR USER LIVE TEST** again until P9A-P9G pass.

Native Project Zomboid SP/MP remains user-owned and must remain UNTESTED unless the user supplies evidence.
