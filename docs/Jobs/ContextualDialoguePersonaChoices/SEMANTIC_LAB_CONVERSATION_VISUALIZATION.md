# P9 — Semantic Lab Conversation Visualization & Direct Routing

**Status:** PLANNED / mandatory corrective UI phase  
**Opened:** 2026-10-22  
**Audit baseline:** ProjectHoomans remote main at `81f4fb982ff5f65024ec9003d1a0a6f08ea7d1f4`.  
**Native Project Zomboid SP/MP:** user-owned and not required for developer-side P9 acceptance.

## Product outcome

Semantic Lab Simulation must become an easy-to-read conversation testing surface.

A developer should be able to:

1. type a natural utterance;
2. immediately see the actual semantic route that fired;
3. receive the real authored NPC response without redundant self-nesting;
4. see the complete authored conversation branch as a graph;
5. see which node is current, visited, available, locked, future, or exiting to root;
6. click an available branch from either the normal choice buttons or the graph through the exact same typed semantic-click path;
7. adjust persona/relationship/runtime context and replay the same conversation quickly;
8. inspect low-level semantic traces only when needed.

The conversation and its branches are the primary UI. Raw worker JSON is secondary diagnostic evidence.

## Source findings driving P9

### Self-nested What's Up route

The semantic parser already recognizes aliases such as `whatsup`, `what's up`, and `what is up` as:

```text
subject    = CONVERSATION_TOPIC
topic      = whats_up
categoryID = projecthoomans:whats_up
route      = conversation_category
```

However, the ordinary typed-input path currently produces the generic unknown-fact response and then projects `conversation.whats_up` as a second button. The test suite explicitly codifies:

```text
input("whats up")
 -> find conversation.whats_up suggestion
 -> click suggestion
 -> enter authored block
```

This is redundant and must be replaced.

The existing semantic-frame click path already has the correct authoritative route:

```text
conversation_category
 -> DialogueInput.SubmitSemanticFrame
 -> Composer.RequestCategory
 -> server/category authority
 -> selected ConversationBlock
 -> current authored node choices
```

Typed category recognition must converge on this route directly.

### Full authored branch already exists

`30_PNC_ConversationWhatsUp.lua` already defines a real conversation tree:

```text
opening
  -> details
  -> personal

details / personal
  -> followup

followup
  -> closing
  -> $root

closing
  -> $root
```

The block includes authored choices, gates, weighted outcomes, relationship effects, translations, and audience/topic variants.

`BuildSemanticBlockProjection` currently exposes only the current node. This is correct for the bounded production player-facing suggestion projection, but insufficient for a developer visualization tool.

### Existing reusable graph renderer

Semantic Lab Studio already owns:

- `FlowEditorPane`
- `FlowEditorCanvasController`
- graph model transformation
- zoom / pan / fit
- node rendering
- internal/exit edges
- edge labels
- selected-node state
- detail / compact / overview render modes

P9 must reuse/refactor these graph primitives. Do not introduce Graphviz, a browser graph, another Tk app, or another independent graph renderer.

## Core design

### Production runtime remains bounded

Do not send the entire future branch graph to the normal in-game choice surface.

The full graph is a **Semantic Lab developer projection** built from the already-authoritative Conversation Registry plus the current runtime block/node and scenario context.

Production player-facing semantics remain:

```text
current node
 -> current eligible/disabled choices
 -> typed semantic frames
```

### Canonical developer graph view

Introduce or evolve one shared visual graph schema that both semantic flows and authored ConversationBlocks can adapt into.

Conceptual shape:

```python
{
    "schema": "semantic_lab.graph.v1",
    "graphID": "...",
    "graphKind": "semantic_flow" | "conversation_block",
    "title": "...",
    "currentNodeID": "opening",
    "visitedNodeIDs": ["opening"],
    "nodes": [
        {
            "id": "opening",
            "title": "Opening",
            "npcText": "There's been movement...",
            "state": "current",
            "metadata": {...}
        }
    ],
    "edges": [
        {
            "id": "...",
            "fromNodeID": "opening",
            "toNodeID": "details",
            "kind": "conversation_choice",
            "label": "What kind of movement?",
            "enabled": true,
            "lockedReason": null,
            "choiceID": "detail",
            "outcomeIDs": ["open", "guarded"],
            "frame": {...}   # only for currently clickable live edges
        }
    ]
}
```

Exact names may differ after implementation audit, but one common renderer contract is required.

### Conversation graph adapter

The developer graph projection should read:

- selected authoritative `ConversationBlock`;
- complete block node definitions;
- current runtime node;
- current scenario/context;
- production choice eligibility;
- production translation manager;
- production outcome/next-node definitions;
- bounded runtime visit history owned by the harness/session, not persisted to NPC ModData.

It must not own conversation state or execute effects.

### Weighted outcomes

Conversation choices may contain multiple weighted outcomes.

If multiple outcomes lead to the same target, collapse them into one visual edge and annotate the possible outcome IDs.

If outcomes lead to different targets, show distinct branches.

The graph is explanatory; actual outcome selection remains owned by the production Conversation system.

## Milestones

### P9A — Direct category routing + graph projection contract

**Goal:** correct semantics first and expose the full selected block to the harness.

Required:

- inspect the actual local typed-input submission path and semantic router;
- when a recognized input already contains `route=conversation_category`, submit that canonical semantic meaning to the existing category authority path directly;
- do not emit the generic `recognized_question_unknown_fact` response first;
- do not regenerate the same category as a self-suggestion after it has just been entered;
- preserve the root `Ask what's up` choice before the player has entered the category;
- replace tests that intentionally require the nested second click;
- add a bounded read-only full ConversationBlock graph projection for Semantic Lab;
- include resolved node text, authored choices, eligibility/lock reason, outcomes, next targets, current node, and root exits;
- keep normal in-game/current-choice projection bounded to the current node.

**Observable gate:**

Typing `whatsup` in the real worker must immediately produce:

1. selected `projecthoomans:whats_up` ConversationBlock;
2. its opening NPC text;
3. the opening node's actual choices;
4. no redundant `conversation.whats_up` self-candidate.

A worker graph request/projection must show all nodes and edges of that selected block.

### P9B — Simulation live conversation graph MVP

**Goal:** make the UI useful for the user as early as possible.

Required:

- add a read-only `Dialogue graph` surface to Simulation;
- reuse the current Tk canvas rendering primitives;
- show the selected ConversationBlock graph after direct category entry;
- highlight current node;
- distinguish at least current / available / locked / future / root-exit states;
- display resolved NPC node text and player choice labels at readable zoom levels;
- automatically fit the graph on first selected block;
- update the graph after every branch click;
- keep normal current choices visible beneath/beside the graph.

**Observable gate:**

From a clean scenario:

```text
type "what's up"
 -> NPC opening appears
 -> graph appears without opening Studio
 -> graph visibly shows opening/details/personal/followup/closing
 -> opening is highlighted
 -> current choice buttons match the graph's available outgoing choices
```

This milestone is intentionally early so the user can begin visually testing P9 before later polish.

### P9C — Shared graph renderer refactor

**Goal:** avoid two graph implementations.

Required:

- separate general graph-view rendering primitives from FlowEditor-specific editing state;
- keep Flow Editor editing behavior intact;
- add adapters:
  - semantic Flow -> shared graph view;
  - ConversationBlock -> shared graph view;
- preserve Flow Editor zoom/pan/fit/node dragging where appropriate;
- Simulation conversation graph remains read-only except live branch activation added in P9D;
- add pure-model tests for both adapters.

**Gate:** Studio Flow Graph and Simulation Dialogue Graph render through the same common graph canvas/model primitives without duplicating edge/node drawing code.

### P9D — Clickable runtime branch testing

**Goal:** let the graph become an actual testing surface without creating a test-only gameplay lane.

Required:

- currently valid conversation-choice edges/cards may be clicked;
- each clickable graph branch must carry/use the same current `semantic_click_frame` already projected to the ordinary current-choice UI;
- graph clicks call the same worker `suggestion_click`/DialogueInput path;
- no direct manipulation of `currentNodeID`;
- disabled/locked edges are visible but non-clickable with safe reason text;
- stale/replay rejection remains visible;
- visited-path highlighting updates from real accepted transitions;
- normal button click and graph click must produce equivalent semantic/action outcomes.

**Gate:** test at least one multi-step What's Up branch entirely through graph clicks and prove identical transport/result semantics to normal choice-button clicks.

### P9E — Simulation layout simplification

**Goal:** prioritize conversation understanding over raw diagnostics.

Target layout:

```text
+---------------- Conversation ----------------+------ Live dialogue graph ------+
| transcript / NPC text                        | full current authored tree       |
|                                               | current node highlighted         |
+-----------------------------------------------+----------------------------------+
| Current choices                                                                  |
+----------------------------------------------------------------------------------+
| input                                                           [Send]           |
+----------------------------------------------------------------------------------+
| compact scenario controls | inspector tabs                                      |
+----------------------------------------------------------------------------------+
```

Required:

- conversation + graph dominate the main viewport;
- current choices are visually adjacent to the conversation;
- hide the group selector when only one group exists;
- when multiple semantic groups exist, make selection clearer than the current nested single combobox experience;
- generic topic navigation must not visually obscure an active branch continuation;
- reduce primary-screen toolbar clutter;
- persona/runtime controls remain quickly reachable;
- raw worker JSON remains available, but behind diagnostics/inspector tabs rather than dominating the UI;
- preserve responsive behavior at the existing minimum supported window size.

**Gate:** Xvfb screenshot/geometry acceptance at minimum size and a normal desktop size proves transcript, graph, current choices, input, key scenario controls, and inspector navigation are all visible/reachable without overlapping or disappearing.

### P9F — Conversation content diagnostics

**Goal:** use the new visualization to expose broken content rather than hiding it.

Required:

- graph/inspector shows node/choice translation keys and resolved values on demand;
- add bounded diagnostics for suspicious unresolved/mixed-language authored content;
- do not auto-rewrite translations as part of semantic routing;
- record known malformed TL What's Up strings as content defects;
- support jumping from a graph node/edge to its source block/translation metadata where practical.

Examples already found during audit include mixed-language TL phrases in the What's Up bundles. These should be visible to authors and fixed as content work, not semantic-engine work.

**Gate:** diagnostics identify known malformed/mixed-language fixtures without changing semantic IDs or branch structure.

### P9G — Final regression and handoff

Required final evidence:

- direct typed category routing;
- root button category routing still works;
- alias/fuzzy reviewed What's Up routes;
- hostile/busy fail-closed behavior;
- current-node suggestion projection remains bounded;
- full developer graph is harness-only;
- graph model for multiple ConversationBlocks, not only What's Up;
- Studio Flow Graph regression;
- graph click vs normal choice click equivalence;
- stale/replay protection;
- EN/TL graph labels;
- persona/bond/relationship replay still works;
- Dynamic Trading provider regression;
- Tk/Xvfb geometry and interaction;
- Python tests;
- embedded Lua tests;
- `luac5.3`;
- Kahlua verification;
- doctor;
- translation/catalog validation;
- `git diff --check`;
- no new ModData persistence for graph state.

Only after P9A-P9G pass may the parent job again report **READY FOR USER LIVE TEST**.

## UX rules

- Never show `What's up -> What's up -> Ask what's up` when the typed utterance already selected that semantic category.
- Branch continuation choices are primary while a block is active.
- A single visible group does not need a group combobox.
- Developer graph may expose future authored structure; normal in-game choice UI may not.
- Actual runtime eligibility must be visually distinguishable from static future structure.
- Do not claim a locked future edge is currently available.
- Resolved human dialogue should be more prominent than IDs/JSON; canonical IDs remain accessible in inspector/tooltips.
- UI changes must be validated through the real worker, not screenshot-only mock data.

## Non-goals

P9 is not:

- a new conversation engine;
- a new semantic parser;
- another choice system;
- a replacement for Conversation Registry;
- a replacement for the Flow Editor;
- a browser/HTML rewrite of Semantic Lab;
- a reason to expose hidden/private facts;
- a reason to serialize full graphs into NPC ModData.
