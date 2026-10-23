# Contextual Dialogue Persona & Choices — Current Progress

**Updated:** 2026-10-23
**Parent status:** REOPENED — P11 runtime-parity foundation retained; P11J native Talk click-boundary repair is mandatory before native handoff.
**Current mandatory phase:** P11J4 corrective native semantic choice boundary; developer repair accepted, native Project Zomboid validation remains user-owned.
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

Commit: `6f378973` — `P11J3 complete Talk parity route matrix`.

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

## P11J4 — accepted developer gates

The P11J2 shared boundary and P11J3 route matrix passed the impacted developer
regression gates:

- P11J and Dynamic Trading parity suites: **12/12 PASS**;
- impacted P10/P11 non-GUI suites: **69 PASS**, with nine display-only tests
  skipped in the intentionally headless run;
- Tk selected-target Talk start: **PASS** for Hostile / Enemy;
- Tk full Talk matrix: **PASS** for Colonist, Follower, Neutral, and Hostile / Enemy;
- CLI `TALK_START`: `semantic.talk.parity.v1`, hostile full-conversation route,
  greeting opening, first response, semantic Flow graph, and
  `speech.style.context.v1` all present;
- CLI `TALK_MATRIX`: `semantic.talk.parity.matrix.v1`, `ok=true`,
  `restoredScenario=true`, and all four production rows present;
- `python3 -m tools.semantic_harness --no-gui --doctor --doctor-json`: required
  checks passed, including Lua, worker syntax, and worker boot; the optional
  virtual-environment check reported the system interpreter as a warning;
- EN/TL Talk parity kept target routes and semantic choice IDs identical;
- `luac5.3 -p` passed for changed Lua and `pz_verify --kahlua` reported zero
  errors;
- `python3 -m py_compile` passed for changed Python;
- `git diff --check` passed;
- Talk start/parity modules contain no `getModData`, `ModData`, or
  `GlobalModData` access; matrix-only target state is transient runtime state and
  is restored after each row and after the matrix.

The codebase graph coverage report was best-effort and marked several changed
files as missing or metadata-changed in its older generation. The implementation
claims above therefore rely on direct source inspection plus the runtime tests,
with the graph result treated as a coverage signal rather than proof of
completeness.

## P11J4 corrective native semantic choice boundary

The native screenshots exposed a real production UI boundary regression: Core's
native choice list could receive semantic rows while the conversation session was
still busy delivering its opening/response, even though Core correctly rejected
clicks in that state. A rejected or stale semantic row could also be cleared by
Core without restoring the production choice surface.

Commit: `f18e5ff6` — `fix: restore native semantic conversation choices`.

The repair keeps Core as the native renderer and keeps the canonical semantic
submission path in Project Hoomans. It defers semantic rows while the Core
session is busy, publishes the native view as the runtime semantic input host,
records accepted/rejected typed row clicks through the existing semantic audit,
and restores the production menu after rejected/stale/unavailable frames. The
runtime-only failure receipt is not persisted or sent over the network.

Evidence:

- `lua5.3 tests/pnc_semantic_dialogue_input_smoke.lua` — PASS, including a
  rendered-row action callback, rejected-click restoration, and busy-session
  deferral;
- `lua5.3 tests/pnc_conversation_smoke.lua` — PASS, including native active-view
  publication;
- `lua5.3 tests/pnc_conversation_talk_start_projection_smoke.lua` — PASS;
- `python3 -m unittest tools.semantic_harness.tests.test_contextual_talk_parity_p11j -q`
  — **8/8 PASS**;
- `luac5.3 -p` passed for changed Lua and `git diff --check` passed.

The repair has not been called a native Project Zomboid verification. The native
SP/MP conversation click path remains **UNTESTED / user-owned**.

## Native no-window diagnostic follow-up

Commit: `7e179f02` — `fix: trace and fall back native talk handoff`.

The native context-menu Talk callback now records its entry and result through
the existing semantic audit when enabled. `Conversation.Open` records the
shared Talk-start projection, inline handoff result, and full-view result. If an
optional hostile inline handoff rejects its selected target, the production
route is changed to the existing hostile full-conversation fallback so the
definition does not retain an inline-only route marker.

The persisted debug profile is configured for this investigation:

- `ProjectHoomans.SemanticDialogueAudit=true`;
- `ProjectHoomans.NativeHandoffAudit=true`;
- `ProjectHoomans.PerformanceDiagnostics=false`;
- all other unrelated diagnostics remain disabled.

All three settings are runtime-mutable and require the in-game Debug Settings
`Reload File & Apply` action before reproducing the native click. A new save is
not required for this UI and routing change.

Developer evidence: `pnc_conversation_smoke.lua`,
`pnc_semantic_dialogue_input_smoke.lua`, and
`pnc_conversation_talk_start_projection_smoke.lua` pass; changed Lua passes
`luac5.3 -p` and `git diff --check`.

## Current Exact Next Chunk — native user handoff

The developer side is ready for the user's native Project Zomboid comparison.
Use the actual context-menu Talk path for Colonist, Follower, Neutral, and
Hostile, then compare target classification, route, opening choices, first
response, hostile inline/fallback behavior, and any observable graph path against
Semantic Lab. Native SP/MP remains **UNTESTED / user-owned** until that evidence
is supplied.

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
