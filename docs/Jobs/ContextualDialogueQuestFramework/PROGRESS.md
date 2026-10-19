# Contextual Dialogue & Quest Framework — Current Progress

Updated: 2026-10-19

Repository: `psychopatz/ProjectHoomans`

Branch: `codex/contextual-dialogue-quest-framework-0a`

Upstream: `origin/docs/contextual-dialogue-quest-framework-20261018`

Base HEAD before Semantic Lab recovery: `3b5004889ddceace8d6d95ca2dca6260b1175919`

Earlier R5 implementation commit: `25f7bd38785f89454876514d5e79fbd31d0ab824`

R5B final real-Lua acceptance commit: `23d1cd1106cf9fe301c705ff62c64052b549a957`

Core dependency: `/home/psychopatz/Zomboid/Workshop/psychopatzCore` at `50022acf90d5a39995be552b7a1e1de21b59168b`

Historical S0–S6 evidence remains preserved in `HISTORY_S0_S6_20261019.md`.

## Status

R0A, R0B, R1, R2, R3, R4, R5 and R5B are implemented and verified in the existing Hoomans/Core architecture. Semantic Lab is **READY FOR USER LIVE TEST**. Native Project Zomboid testing remains user-owned; no Project Zomboid process, multiplayer host, mod installation or Workshop publish was used.

## Completed recovery evidence

- R0A (`a591ec7e2df1b0fe4cdf751948a587e07870c387`): the real worker recognizes `fuck you` as `INSULT`, selects `HOSTILE_REMARK_RECEIVED`, records directed social authority/transport status and reason, and presents truthful EN/TL rejection or unavailable text. Self-directed non-hostile input has no social effect; THREAT remains covered. The Simulation inspector exposes route, authority result, rejection reason, response pool and final text.
- R0B (`dd775b0e0c5b1fe35b2c10392dd6e4545e85cfb9`): the live Interaction Explorer catalogs Core language concepts, policy branches, registered flows, capabilities, generated flows and response pools. INSULT, FOLLOW and NEEDS are searchable with their real execution routes.
- R1 (`e50a2ae318052e665bd88f7fe537230d7987744d`, `787fe2ba362e998a4f04262eb1bcb41a04f84e70`): typed `semantic.interaction_spec.v1` / collection composition and reusable shared blocks compile through the existing CodeBuilder. A `world_facts.engine_fact` block changes generated Lua and real worker behavior; it is not JSON-only validation.
- R2 (`5d335b26405be4223c27cdb1df827f2a8d993304`): Semantic Lab has Studio/Simulation workspaces, live explorer, block palette, graph/code authoring, dataset browser, generated-output controls and worker restart controls.
- R3 (`b45d95aab5e98b8a17e24700eabef72644eb54fa`): pinned WordNet 3.0 builds 29 aliases/91 forms for 14 reviewed concepts. The canonical dataset contains reviewed MASSIVE and SGD records with source version/hash, record references and imported/mapped/approved/compiled/worker-verified status. A fresh worker resolves both records to the existing weather response with no transport or side effect. Runtime never reads WordNet archives, ZIPs, URLs or full external corpora.
- R4 (`633f54a9814f9320cb9fe00b6d0aa36410fd73ef`): bounded discourse references such as `Wait there` resolve only from grounded prior context; unresolved references return clarification/rejection with no task transport. Existing memory, facts, personality, relationship, topic and EN/TL contextual tests remain green.

## R5 — Actual modular authoring acceptance

The Interaction Composer previews canonical source plus generated Lua and EN/TL artifact diffs, requires explicit approval, persists the canonical source through the existing CodeBuilder writer, writes the generated artifacts, and requests a production-worker restart. A real Tk/X11 run invoked Preview, Approve and Generate on the existing Semantic Lab app and produced the canonical `pnc.lab.stay_with_you` definition, pattern, flow, response pool and translations.

Real worker evidence after restart:

- `stay with you` → pattern `pnc.lab.stay_with_you.stay_with_you`, authored flow `pnc.lab.stay_with_you.flow`, capability `pnc:companion.stay`, `CompanionCommand`, accepted `network_queued`, action count 1, final EN `Okay, I'll stay with you.` and TL `Sige, mananatili ako sa iyo.`.
- Denied STAY uses the binding rejection pool and truthful `I can't stay here right now.` / `Hindi ako makapananatili rito ngayon.` with no accepted action.
- Generated WAIT_AT rejection and failed/gated flows still use their authoritative generated result-node response. Greeting/identity multi-turn plans remain two-message plans.
- Missing gift generated lifecycle keys were added to EN/TL `GeneratedTaskCommands.json`, so the generated gift rejection path no longer falls back from TL to EN.

## R5B — Final real-Lua repair

- Quest-accept patterns now require the semantic anchors `help` and `supplies`; bare `yes` and `Sure` remain social acknowledgements instead of becoming `COMMAND_ACCEPTED`.
- Inventory pending-limit rejection no longer queues a misleading generic action-failure line beside the next authoritative inventory result.
- The greeting flow now has a rain-aware response-plan variant, preserving grounded weather context while retaining its two-message plan. The local Core smoke contract now checks the real two-turn queue and current contextual wording.

## Verification evidence

- Full real-Lua Python harness discovery: **218/218 PASS**.
- Semantic compiler unit suite: **16/16 PASS**.
- Existing real-Lua `pnc_semantic` suite: **68/68 PASS**. The four previously reported failures are resolved: gift/state acceptance classification, greeting queue ownership/context, and inventory queue ownership.
- Focused real-worker suites: contextual social **11/11**, dataset review **7/7**, follow binding **4/4**, authoring compiler **5/5**, interaction spec **7/7**, stay/wait binding **3/3**, flow editor **9/9**, gift binding **3/3**, semantic dialogue flows **8/8**, translation integration **1/1**.
- Harness doctor: **PASS** — Python 3.12.3, Tk/display, Core path, Lua 5.3.6, worker syntax/boot/PING/CAPABILITIES.
- `git diff --check`, changed Python compilation, changed Lua `luac5.3 -p`, EN/TL JSON parsing and changed-file `pz_verify` checks are clean.

## Boundaries and next chunk

The next and only next chunk is **user-owned Project Zomboid live testing**: exercise the documented Semantic Lab workflow in the native game and report any native-runtime discrepancy. The agent must not launch Project Zomboid, host multiplayer, install mods or publish to Workshop.
