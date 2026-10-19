# Contextual Dialogue & Quest Framework — Current Progress

**Updated:** 2026-10-19

**Repository:** `psychopatz/ProjectHoomans`

**Branch:** `codex/contextual-dialogue-quest-framework-0a`

**Upstream:** `origin/docs/contextual-dialogue-quest-framework-20261018`

**Core dependency:** `/home/psychopatz/Zomboid/Workshop/psychopatzCore` at `50022acf90d5a39995be552b7a1e1de21b59168b`

**Historical implementation evidence:** `HISTORY_S0_S6_20261019.md` preserved untouched.

## Status

R0A and R0B are accepted. R1 typed/shared semantic composition is accepted for the implemented scope, including a reusable world-fact block proven in the real Lua worker. R2 has a usable first-pass Studio/Simulation workbench. R3 is accepted for the reviewed WordNet expansion and bounded real MASSIVE/SGD production slice described below. R4 is accepted for the bounded contextual-reference slice described below. Overall status remains **IN PROGRESS** and is not ready for user live testing because R5 and four legacy Lua failures remain open.

The checkout, branch, HEAD, upstream, dirty files, and Core dependency were verified before implementation. No Project Zomboid process, multiplayer host, mod installation, or Workshop publish was used.

## Completed recovery work

### R0A — Production INSULT response repair

The real worker recognizes `"fuck you"` as `INSULT` (`pnc.social.insult`, confidence `0.99`) and selects `HOSTILE_REMARK_RECEIVED`. Rejected social authority and unavailable transport now produce truthful social-specific EN/TL responses instead of the generic failure. The Simulation inspector exposes route, policy branch, authority, accepted/status, rejection reason, response pool, and final text. Self-directed non-hostile speech remains without social authority/effects; THREAT remains covered.

Implementation: `a591ec7e2df1b0fe4cdf751948a587e07870c387`.

### R0B — Live Interaction Explorer

The existing production Lua FlowEditor catalog now exposes policy branches resolved by `DialoguePolicy`, Core concepts/speech acts/triggers, 100 bounded response-pool entries, and searchable INSULT, FOLLOW, and NEEDS routes. It uses the existing runtime catalogs and does not create a duplicate parser or dispatcher.

### R1 — Actual modular semantic composition

Typed `semantic.interaction_spec.v1` definitions and `semantic.interaction_collection.v1` shared block instances now flow through the existing CodeBuilder. A shared `world_facts.engine_fact` block and typed `conditions.gate` connection change generated production Lua and real worker behavior. Two distinct generated patterns both passed the `world.time.week` gate, dispatched the existing `pnc:companion.stay` capability, emitted one real harness transport event, and selected the existing NPC response `Okay.`. No fabricated gameplay or relationship change was created.

Implementations: `e50a2ae318052e665bd88f7fe537230d7987744d`, `5d335b26405be4223c27cdb1df827f2a8d993304`, and `787fe2ba362e998a4f04262eb1bcb41a04f84e70`.

### R2 — Studio/Simulation workbench

The GUI has two primary workspaces: Studio and Simulation. Studio contains workflow selection, Flow and interaction views, Dataset Library, block palette, live Interaction Explorer, ordinary-field Interaction Composer, approval/generation controls, and worker restart. Simulation retains conversation execution traces.

### R3 — Verifiable lexical and corpus integration

Commit `b45d95aa` expands the pinned WordNet 3.0 allowlist from the original FETCH/FOLLOW subset to 14 reviewed registered concepts. The canonical build produced 29 aliases and 91 inflected forms in `PNC_SemanticGeneratedLexicon.lua`; the real Lua smoke test confirms new Core/parser matches including `assist`, `assisting`, `declined`, `locomote`, `possess`, `desire`, `concur`, and `dissent`. WordNet remains build-time only; no archive or URL is read by Lua.

The existing CodeBuilder now has two reviewed records from the official build-time sources in the canonical `common_interactions.json` source:

- MASSIVE 1.0 `en-US` train record `98`, intent `weather_query`, utterance `is it currently snowing`.
- SGD/DSTC8 `train/dialogues_090.json`, dialogue `90_00031`, turn `6`, service `Weather_1`, intent `GetWeather`, utterance `How is the weather on 9th of March?`.

Both records carry source version/hash, source record references, canonical WEATHER mapping, negative/collision review, and imported/mapped/approved/compiled/worker-verified status. The authoring preview exposes those references and aggregate status; Dataset Library shows `imported 2 · mapped 2 · approved 2 · compiled 2 · worker verified 2`. `MASSIVE-SGD-NOTICES.md` records the licenses and source hashes. Raw corpora remain outside repository/runtime media.

After a fresh production Lua worker restart, the two utterances resolve to their distinct generated pattern IDs, select `QUESTION_RECEIVED`, produce the existing weather response text `The weather looks clear right now.`, emit no transport event, and report no side effects. This is actual worker evidence, not JSON-only validation.

### R4 — Contextual conversational intelligence slice

Commit `633f54a9` extends the existing movement catalog with `pnc.command.wait_at_reference`, so `Wait there` and `Stay there` are resolved through the existing discourse-reference resolver instead of falling through to generic clarification. The same resolver now marks an unresolved reference explicitly before policy/flow evaluation. A fresh real Lua worker proves `Wait at the campfire` → `Wait there` and `Stay there` reuse the grounded `CAMPFIRE` target, retain the existing `pnc:task.wait_at` route, produce `Okay, I'll wait there.`, and emit real task transport. An ungrounded `Wait there` is blocked with `clarification_required`, truthful `I can't wait there right now.`, no transport, and no successful action. Existing C1–C6 contextual tests continue to cover interruptions, follow-ups, topic switches, references, confirmations, grounded facts, personality/relationship state, EN/TL output, and no-effect branches.

## Verification evidence

- Full Python harness discovery: `238/238 PASS`.
- Focused interaction-spec suite: `6/6 PASS`.
- Focused dataset review/worker suite: `7/7 PASS`.
- Compiler unit suite: `8/8 PASS`.
- Generated WordNet Lua smoke: `1/1 PASS`.
- Focused real-Lua social smoke: `2/2 PASS` (`pnc_semantic_social_chat_smoke`, `pnc_semantic_social_smoke`).
- Focused movement/reference worker suite: `3/3 PASS`.
- Existing `pnc_semantic` suite: `64/68 PASS`; the same four legacy failures remain:
  - `pnc_semantic_gift_offer_smoke`: agreement without live offer expected `SOCIAL_ACKNOWLEDGED`, got `COMMAND_ACCEPTED`.
  - `pnc_semantic_local_route_smoke`: local greeting expected one queued response, got two.
  - `pnc_semantic_inventory_dialogue_smoke`: second local turn expected queue size two, got three.
  - `pnc_semantic_state_response_smoke`: expected `SOCIAL_ACKNOWLEDGED`, got `COMMAND_ACCEPTED`.
- Doctor: PASS for Python 3.12.3, Tk/display, Core, Lua 5.3.6, worker syntax/boot/PING/CAPABILITIES.
- Changed Python and Lua syntax: PASS; EN/TL generated JSON validation and `git diff --check`: PASS.
- `pz-verify`: zero errors on the semantic directory; one pre-existing `load(string)` warning and existing hardcoded-string/token-bloat advisories remain, including the generated lexicon and dialogue shards.

## Remaining defects and boundaries

The four legacy Lua failures above remain open and must not be hidden by the R3/R4 work. R5 still needs the complete in-app edit → changed source/diff → approval → generation → worker reload → conversation → revision workflow and measured resource evidence. Native Project Zomboid single-player and multiplayer behavior remain user-owned and untested.

## ONE next chunk

**R5 — Complete developer acceptance:** drive the existing Semantic Lab Studio and Simulation path end to end with an actual changed interaction: edit one supported interaction through the in-app authoring controls, preview the changed canonical source and generated Lua/EN/TL diff, approve and generate through CodeBuilder, restart the production worker, converse using the changed route, inspect final text/authority/effects, and revise or document the first remaining in-app workflow defect. Preserve the existing canonical pipeline and measure the worker/UI path without launching Project Zomboid.
