# Contextual Dialogue Persona & Choices — Current Progress

**Updated:** 2026-10-23
**Parent status:** P9 developer-side gates passed — READY FOR USER LIVE TEST.
**Current mandatory phase:** P9G — Final regression complete.
**Current local main baseline inspected:** `07d1ab96c44ff272ccbdc45b4a3b975fea63fa6c`.
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

## P9A accepted — 2026-10-22

The real Lua worker now proves the required direct route for the reviewed aliases and bounded fuzzy form, including `whatsup`:

```text
input("whatsup")
 -> canonical CONVERSATION_TOPIC / conversation_category
 -> Composer.RequestCategory
 -> authoritative ConversationBlock
 -> authored opening NPC response and choices
 -> no conversation.whats_up self-candidate
```

The root `Ask what's up` candidate remains available before entry. Hostile category eligibility still fails closed, normal choice clicks retain stale/replay protection, and EN/TL text is resolved through the existing translation manager. The developer-only graph projection contains all five What's Up nodes, authored choices, locked reasons, weighted outcomes, collapsed next-node targets, root exits, current state, and canonical source metadata. The normal player-facing projection remains current-node bounded.

Evidence: `python3 -m unittest tools.semantic_harness.tests.test_contextual_suggestions_whats_up -v` — 7 passed; `luac5.3 -p` passed for all changed Lua files.

## P9B/P9C accepted — 2026-10-22

The existing Simulation tab now embeds a read-only `Dialogue graph` pane using the existing Flow Editor Tk canvas/controller. The real worker response supplies the selected authored ConversationBlock graph; the pane automatically fits the first selected graph, renders localized NPC text and authored choice labels, and highlights `CURRENT`, `AVAILABLE`, `LOCKED`, `FUTURE`, `VISITED`, and `ROOT EXIT` states. A normal current choice refreshes the same pane and advances the current-node highlight.

The Flow graph model now has a ConversationBlock adapter, and the shared canvas/controller owns zoom, pan, fit, edge routing, exit rendering, and node-card rendering for both production Flow graphs and read-only ConversationBlock graphs. Studio Flow Editor behavior remains covered by its existing tests plus the adapter contract.

Evidence: `xvfb-run -a python3 -m unittest tools.semantic_harness.tests.test_contextual_suggestions_s4 -v` — 5 passed; Flow Editor and ConversationBlock adapter tests passed; the GUI proof typed `whats up`, observed the real authored opening/full graph, then clicked the normal `detail` choice and observed `currentNodeID == details`.

## P9D/P9E/P9F accepted — 2026-10-22

Available current branch edges in the live graph now carry the exact canonical choice frame used by the normal suggestion buttons. Graph clicks dispatch through `worker.suggestion_click` → `DialogueInput` → `Composer.RequestChoice`; no graph path assigns `currentNodeID`. Locked/future edges remain visible and non-clickable. Worker equivalence coverage confirms the graph frame and normal choice frame are identical and produce the same authoritative `ConversationOutcome` and next node; Xvfb proof clicks a rendered edge and advances the graph.

Simulation now prioritizes the conversation transcript, live graph, and current authored choices. The graph is selected automatically when a ConversationBlock is active, cards show localized NPC text and choice labels, the choices panel is titled `Current player choices`, and single-group navigation is hidden. Runtime controls remain reachable and the existing minimum-window layout test remains green.

The graph `Diagnostics` action exposes bounded node/choice translation keys, resolved text, source bundle and canonical IDs, outcome/target metadata, lock reasons, and suspicious unresolved/mixed-language markers. It reports authored defects without rewriting translations.

Evidence: direct worker graph/button equivalence test passed; `xvfb-run -a python3 -m unittest tools.semantic_harness.tests.test_contextual_suggestions_s4 -v` — 5 passed; Flow/model diagnostics tests passed; `luac5.3 -p` passed for the modified production graph Lua.

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

## P9G accepted — 2026-10-23

P9A-P9G developer-side gates are complete. The final focused evidence is:

- direct typed What's Up entry, root entry, reviewed aliases, bounded fuzzy routing, hostile fail-closed behavior, stale/replay protection, EN/TL projection, and several authored categories: `test_contextual_suggestions_whats_up` — 9 passed;
- read-only Simulation graph, actual localized node text, current/available/future/visited/root-exit states, normal choice advancement, graph-edge advancement, minimum-window layout, and single-group navigation suppression: `xvfb-run -a python3 -m unittest tools.semantic_harness.tests.test_contextual_suggestions_s4 -v` — 5 passed;
- shared Flow Graph renderer/model and bounded graph diagnostics: `test_flow_editor` — 11 passed;
- persona, bond, Dynamic Trading provider, and Semantic Lab regression suites: 20 passed, 1 skipped;
- embedded Lua conversation/authority/translation tests: 6/6 passed;
- `luac5.3`, doctor worker boot, client/shared Kahlua verification, translation catalog validation, `compileall`, and `git diff --check`: passed;
- live worker proof: `input("whatsup")` selected `projecthoomans:whats_up_local_activity_neutral`, returned the authored opening and choices, projected all five authored nodes, and emitted no `conversation.whats_up` self-candidate;
- no full conversation graph is written to NPC ModData; graph state remains an on-demand Semantic Lab/runtime projection.

The broad Python discovery run still reports six pre-existing `ContextualSocialReactionTests` failures and then a Tk cross-thread cleanup abort; the social failure was reproduced against the detached clean `main` baseline before this P9 work and is unrelated to the changed P9 paths. Focused P9 and relevant P8 regression suites are green.

## Handoff condition

**READY FOR USER LIVE TEST** for P9 Semantic Lab developer-side behavior.

Native Project Zomboid SP/MP remains **UNTESTED / user-owned** and requires the user's live evidence.
