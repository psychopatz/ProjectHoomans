# Contextual Dialogue & Quest Framework — Current Progress

Updated: 2026-10-19

Repository: `psychopatz/ProjectHoomans`

Branch: `codex/contextual-dialogue-quest-framework-0a`

Upstream: `origin/docs/contextual-dialogue-quest-framework-20261018`

Base HEAD before this implementation: `3b5004889ddceace8d6d95ca2dca6260b1175919`

Core dependency: `/home/psychopatz/Zomboid/Workshop/psychopatzCore` at `50022acf90d5a39995be552b7a1e1de21b59168b`

Historical S0–S6 evidence remains preserved in `HISTORY_S0_S6_20261019.md`.

## Status

R0A, R0B, R1, R2, R3 and R4 are implemented and verified in the existing Hoomans/Core architecture. R5 is implemented through the real Semantic Lab Tk/X11 authoring path and the production Lua worker, but the repository is not yet READY FOR USER LIVE TEST because two legacy Core smoke failures remain. No Project Zomboid process, multiplayer host, mod installation or Workshop publish was used.

## Completed recovery evidence

- R0A (`a591ec7e2df1b0fe4cdf751948a587e07870c387`): the real worker recognizes `fuck you` as `INSULT`, selects `HOSTILE_REMARK_RECEIVED`, records directed social authority/transport status and reason, and presents truthful EN/TL rejection or unavailable text. Self-directed non-hostile input has no social effect; THREAT remains covered. The Simulation inspector exposes the route, authority result, rejection reason, response pool and final text.
- R0B (`dd775b0e0c5b1fe35b2c10392dd6e4545e85cfb9`): the live Interaction Explorer catalogs Core language concepts, policy branches, registered flows, capabilities, generated flows and response pools. INSULT, FOLLOW and NEEDS are searchable with their real execution routes.
- R1 (`e50a2ae318052e665bd88f7fe537230d7987744d`, `787fe2ba362e998a4f04262eb1bcb41a04f84e70`): typed `semantic.interaction_spec.v1` / collection composition and reusable shared blocks compile through the existing CodeBuilder. A `world_facts.engine_fact` block changes generated Lua and real worker behavior; it is not JSON-only validation.
- R2 (`5d335b26405be4223c27cdb1df827f2a8d993304`): Semantic Lab has Studio/Simulation workspaces, live explorer, block palette, graph/code authoring, dataset browser, generated-output controls and worker restart controls.
- R3 (`b45d95aab5e98b8a17e24700eabef72644eb54fa`): pinned WordNet 3.0 builds 29 aliases/91 forms for 14 reviewed concepts. The canonical dataset contains reviewed MASSIVE and SGD records with source version/hash, record references and imported/mapped/approved/compiled/worker-verified status. A fresh worker resolves both records to the existing weather response with no transport or side effect. Runtime never reads WordNet archives, ZIPs, URLs or full external corpora.
- R4 (`633f54a9814f9320cb9fe00b6d0aa36410fd73ef`): bounded discourse references such as `Wait there` resolve only from grounded prior context; unresolved references return clarification/rejection with no task transport. Existing memory, facts, personality, relationship, topic and EN/TL contextual tests remain green.

## R5 — Actual modular authoring acceptance

The Interaction Composer now previews canonical source plus generated Lua and EN/TL artifact diffs, requires explicit approval, persists the canonical source through the existing CodeBuilder writer, writes the generated artifacts, and requests a production-worker restart. A real Tk/X11 run invoked Preview, Approve and Generate on the existing Semantic Lab app and produced the canonical `pnc.lab.stay_with_you` definition, pattern, flow, response pool and translations.

Real worker evidence after restart:

- `stay with you` → pattern `pnc.lab.stay_with_you.stay_with_you`, authored flow `pnc.lab.stay_with_you.flow`, capability `pnc:companion.stay`, `CompanionCommand`, accepted `network_queued`, action count 1, final EN `Okay, I'll stay with you.` and TL `Sige, mananatili ako sa iyo.`.
- Denied STAY uses the binding rejection pool and truthful `I can't stay here right now.` / `Hindi ako makapananatili rito ngayon.` with no accepted action.
- Generated WAIT_AT rejection and failed/gated flows still use their authoritative generated result-node response. Greeting/identity multi-turn plans remain two-message plans.
- Missing gift generated lifecycle keys were added to EN/TL `GeneratedTaskCommands.json`, so the generated gift rejection path no longer falls back from TL to EN.

The existing response architecture was corrected so authored action flows use their configured response pool only after an accepted dispatch, while generated rejected/failed/gated result nodes remain truthful. No successful server event or relationship change is fabricated.

## Verification evidence

- Full real-Lua Python harness discovery: **218/218 PASS**.
- Semantic compiler unit suite: **16/16 PASS**.
- Focused real-worker suites: contextual social **11/11**, dataset review **7/7**, follow binding **4/4**, authoring compiler **5/5**, interaction spec **7/7**, stay/wait binding **3/3**, flow editor **9/9**, gift binding **3/3**, semantic dialogue flows **8/8**, translation integration **1/1**.
- Harness doctor: **PASS** — Python 3.12.3, Tk/display, Core path, Lua 5.3.6, worker syntax/boot/PING/CAPABILITIES.
- Existing real-Lua `pnc_semantic` suite: **66/68 PASS**. Two of the four previously reported failures are fixed by requiring `help` and `supplies` in the quest-accept patterns; bare `yes` now remains `SOCIAL_ACKNOWLEDGED` and `Sure` no longer becomes `COMMAND_ACCEPTED`.
- Remaining two failures: `pnc_semantic_local_route_smoke.lua:208` expects one greeting line while the authoritative greeting plan queues two; `pnc_semantic_inventory_dialogue_smoke.lua:282` expects queue size two while the second local inventory turn leaves three. These need a dedicated queue-ownership audit; they were not hidden or relabeled.
- `git diff --check`, changed Python compilation, changed Lua `luac5.3 -p`, EN/TL JSON parsing and changed-file `pz_verify` checks are clean.

## Boundaries and next chunk

The repository is not yet ready for user-owned Project Zomboid live testing. Native game testing remains explicitly user-owned. The next and only next chunk is **R5B — reconcile the remaining Core greeting/inventory queue ownership contract, rerun all 68 real-Lua semantic smoke tests, and only then declare READY FOR USER LIVE TEST if the queue trace and final wording are correct**.
