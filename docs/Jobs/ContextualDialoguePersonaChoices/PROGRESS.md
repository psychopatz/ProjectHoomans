# Contextual Dialogue Persona & Choices — Current Progress

**Updated:** 2026-10-23
**Parent status:** REOPENED — P11 runtime-parity foundation retained; P11J native Talk shared-entry parity is mandatory.
**Current mandatory phase:** P11J4 — Regression and native handoff.
**Current remote baseline audited:** ProjectHoomans `main` at `c9385c4f2b1b86feb09ed24144896e473bd6fec8`.
**Native Project Zomboid SP/MP:** UNTESTED / user-owned.

## Stable accepted foundation

Preserve the already-implemented work:

- P10 contextual What's Up hub and structured Simulation controls;
- actor-centric Player/NPC/Relationship/World workbench;
- first-class Player/NPC needs and production traits/personality;
- dynamic durable friend promotion;
- proposal/lover relationship policy and harness simulation;
- relationship live preview and Compare;
- unified semantic Flow / Hub / ConversationBlock graph renderer;
- modular speech realization packs;
- deterministic identity/backstory/Core content work;
- shared activity logging and readable action transcript;
- production target catalog and harness Talk matrix from P11J1.

## P11J audit reconciliation

The original Talk audit was correct that a normal semantic turn is not proof of native Talk parity.

P11J1 remains accepted with `PNC.Conversation.TalkParity`, `TALK_CATALOG`,
`TALK_START`, `TALK_MATRIX`, the GUI/CLI surfaces, and these canonical cases:

```text
current · colonist · follower · neutral · hostile
```

Production mapping remains truthful: follower derives from colonist ownership and
the follow order; hostile is the production tactical type; `Hostile / Enemy` is
only a display label; and trader remains a Dynamic Trading/provider overlay.

## P11J2 — accepted developer implementation

Commit: `6818110e` — `P11J2 share native Talk start projection`.

Added the production-owned `PNC.Conversation.TalkStart` projection at:

```text
Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/Conversation/PNC_ConversationTalkStart.lua
```

The projection consumes a canonical entry, player, and runtime integration state.
It returns the target type, tactical class, ownership and follow facts,
conversation relationship and audience, availability, hostile inline/full route,
and the canonical greeting opening state.

Native Talk now follows:

```text
real entry
    ↓
shared TalkStart.Project
    ↓
Conversation.BuildDefinition
    ↓
Conversation.Open
```

The builder carries the same projection into the production definition and
conversation context. Semantic Lab keeps its scenario-to-entry conversion in
`TalkParity`, then enters the same `TalkStart.Project` boundary for `TALK_START`
and `TALK_MATRIX`. Harness classification, audience, relationship, availability,
and route policy were removed from that boundary. The harness relationship adapter
preserves the production conversation relationship resolver and adds only its
presentation receipt hook.

P11J2 evidence:

- `lua5.3 tests/pnc_conversation_talk_start_projection_smoke.lua` — PASS;
- `lua5.3 tests/pnc_conversation_audience_smoke.lua`,
  `pnc_npc_type_palette_smoke.lua`, and `pnc_conversation_smoke.lua` — PASS;
- P11J source/runtime tests proved native lifecycle, definition builder, and
  harness parity callers reference `TalkStart.Project` and the worker emits the
  shared projection schema;
- changed production Lua passed `pz_verify --kahlua --severity ERROR` with zero
  findings and `luac5.3 -p` passed;
- `git diff --check` passed.

The headless worker reports hostile inline support as unavailable unless the real
PBrainZ integration reports ready and exposes its inline target route. Native
Project Zomboid SP/MP remains **UNTESTED / user-owned**.

## P11J3 — accepted developer implementation

Commit: pending after this milestone is committed.

The shared projection now carries row-level availability and integration state.
The matrix uses clean scenario copies, restores the original scenario, and keeps
the optional Dynamic Trading provider state from becoming a Talk tactical type.
The normal catalog remains exactly:

```text
current · colonist · follower · neutral · hostile
```

The real worker evidence covers:

| Case | Projection | Route | Result |
| --- | --- | --- | --- |
| Colonist | `colonist` / `colonist` | `full_conversation` | greeting opening and first response |
| Follower | `follower` / `colonist` | `full_conversation` | follow state is derived |
| Neutral | `neutral` / `neutral` | `full_conversation` | non-owned authority preserved |
| Hostile | `hostile` / `hostile` | `hostile_full_conversation` | headless worker does not fake inline support |
| Unavailable diagnostic | production target facts | `unavailable` | reason is exposed and scenario restored |
| Trader overlay | tactical target remains neutral/colonist/etc. | unchanged | Dynamic Trading provider is an overlay |

Production projection smoke also covers the real PBrainZ ready branch as
`hostile_inline` and the unavailable branch. The headless worker only reports the
route supported by its actual loaded integrations.

P11J3 evidence:

- `python3 -m unittest tools.semantic_harness.tests.test_contextual_talk_parity_p11j -v` — **8/8 PASS**;
- `python3 -m unittest tools.semantic_harness.tests.test_contextual_talk_parity_p11j tools.semantic_harness.tests.test_contextual_dynamic_trading_p5 -q` — **12/12 PASS**;
- CLI `TALK_START` emitted `semantic.talk.parity.v1`, the shared target projection,
  opening state, first NPC response, graph path, and `SpeechStyleContext`;
- CLI `TALK_MATRIX` emitted `semantic.talk.parity.matrix.v1`, four canonical
  production rows, and `restoredScenario=true`;
- GUI Talk parity uses the same worker operations and formatter exposes route,
  availability, provider overlay, response, and graph columns;
- EN/TL tests kept routes and semantic choice IDs identical while presentation
  localization changed;
- `pnc_conversation_talk_start_projection_smoke.lua`, audience, palette, and
  conversation smokes passed;
- changed Lua passed `luac5.3 -p` and Kahlua verification; Python compilation
  and `git diff --check` passed.

## Current Exact Next Chunk — P11J4

Run the focused and impacted developer-side regression gates:

1. P11J Talk parity Python tests and Tk/Xvfb selected-target and full-matrix paths;
2. CLI `TALK_START` and `TALK_MATRIX` with compact schema/route checks;
3. conversation, NPC type palette, contextual hub, graph, relationship/bond,
   identity, inventory, and activity-log regressions;
4. EN/TL validation, `luac5.3 -p`, Kahlua verification, doctor, and
   `git diff --check`;
5. prove no new Talk-parity persistent ModData/state;
6. update this file with exact evidence, commit safely on `main`, and hand native
   Talk comparison to the user.

## Known separate relationship boundary

The server relationship proposal policy/service and Semantic Lab proposal action
exist. A separate source audit found no normal production dialogue/provider caller
of `PNC.Relationships.Propose` yet. Do not silently claim real player proposal UX
is native-complete unless that separate bounded relationship action chunk verifies
the production caller.

## Handoff condition

Do not report **READY FOR USER LIVE TEST** solely because P11J1 matrix tests pass.
After P11J2–P11J4 developer gates pass, hand native Project Zomboid SP/MP
verification to the user. Native verification remains **UNTESTED / user-owned**
until the user supplies evidence.
