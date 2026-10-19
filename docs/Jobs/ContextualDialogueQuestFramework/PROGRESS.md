# Contextual Dialogue & Quest Framework — Current Progress

**Updated:** 2026-10-19  
**Repository:** `psychopatz/ProjectHoomans`  
**Branch:** `codex/contextual-dialogue-quest-framework-0a`  
**Upstream:** `origin/docs/contextual-dialogue-quest-framework-20261018`  
**Core dependency:** `/home/psychopatz/Zomboid/Workshop/psychopatzCore` at `50022acf90d5a39995be552b7a1e1de21b59168b`  
**Historical implementation evidence:** `HISTORY_S0_S6_20261019.md` preserved untouched.

## Status

R0A and R0B are accepted. R1 typed composition is accepted for the implemented scope, including reusable world-fact composition proven in the real Lua worker. R2 has a usable first-pass Studio/Simulation workbench and is still part of the expanded recovery. Overall status remains **IN PROGRESS** and is not ready for user live testing because R3, R4, R5, and the four legacy Lua failures remain open.

The checkout and Core dependency were verified before implementation. No Project Zomboid process, multiplayer host, mod installation, or Workshop publish was used.

## Completed recovery work

### R0A — Production INSULT response repair

The real worker recognizes `"fuck you"` as `INSULT` (`pnc.social.insult`, confidence `0.99`) and selects `HOSTILE_REMARK_RECEIVED`. Rejected social authority and unavailable transport now produce truthful social-specific EN/TL responses instead of the generic failure. The simulation inspector exposes route, policy branch, authority, accepted/status, rejection reason, response pool, and final text. Self-directed non-hostile speech remains without social authority/effects; THREAT remains covered.

Implementation: `a591ec7e2df1b0fe4cdf751948a587e07870c387`.

### R0B — Live Interaction Explorer

The existing production Lua FlowEditor catalog now exposes policy branches resolved by `DialoguePolicy`, Core concepts/speech acts/triggers, registered flows, capability bindings, generated coverage, and bounded summaries of 100 registered response pools. INSULT, FOLLOW, and NEEDS are searchable with their actual routes. No second parser, registry, or execution path was introduced.

Implementation: `dd775b0e0c5b1fe35b2c10392dd6e4545e85cfb9`.

### R1/R2 — Canonical composition and Studio foundation

`semantic.interaction_spec.v1` composes typed trigger, capability, and response-pool instances through the existing CodeBuilder. `semantic.interaction_collection.v1` adds typed `world_facts.engine_fact` and `conditions.gate` blocks. One authoritative `world.time.week` block is reused by two generated flows; changing a block changes generated Lua fingerprints; invalid connections and unapproved generation write nothing. Approved collection generation uses the existing semantic writer and requires caller restart.

The temporary overlay proof used the actual Lua worker: `stay with me` and `remain with me` matched their distinct generated patterns, both passed the `world.time.week` gate, dispatched the existing `pnc:companion.stay` capability, emitted one real harness transport event each, and selected the existing NPC response text `Okay.`. No fabricated gameplay event or relationship change was created.

Implementations: `e50a2ae318052e665bd88f7fe537230d7987744d`, `5d335b26405be4223c27cdb1df827f2a8d993304`, and `787fe2ba362e998a4f04262eb1bcb41a04f84e70`.

The GUI now has two primary workspaces, Studio and Simulation. Studio contains workflow selection, Flow + interactions, Dataset Library, Block palette, live Interaction Explorer, and an ordinary-field Interaction Composer that previews, requests approval, generates through the existing writer, and restarts the existing worker. Simulation retains conversation and execution traces.

## Verification evidence

- Full Python semantic harness discovery: `215/215 PASS`.
- Focused interaction-spec suite: `6/6 PASS`.
- Focused real-Lua social smoke: `2/2 PASS` (`pnc_semantic_social_chat_smoke`, `pnc_semantic_social_smoke`).
- Existing `pnc_semantic` suite: `64/68 PASS`; the same four legacy failures remain:
  - `pnc_semantic_gift_offer_smoke`: agreement without a live offer expected `SOCIAL_ACKNOWLEDGED`, got `COMMAND_ACCEPTED`.
  - `pnc_semantic_local_route_smoke`: local greeting expected one queued response, got two.
  - `pnc_semantic_inventory_dialogue_smoke`: second local turn expected queue size two, got three.
  - `pnc_semantic_state_response_smoke`: expected `SOCIAL_ACKNOWLEDGED`, got `COMMAND_ACCEPTED`.
- Doctor: PASS for Python 3.12.3, Tk/display, Core, Lua 5.3.6, worker syntax/boot/PING/CAPABILITIES.
- Python syntax, Lua syntax, EN/TL JSON validation, `pz-verify`, and `git diff --check`: PASS. The pre-existing response adapter remains an advisory 5,613-token file and was not split.

## Remaining product gaps

R3 still needs actual approved WordNet lexicon, generated Lua/Core registration/worker evidence, and reviewed MASSIVE/SGD imports through the embedded CodeBuilder rather than metadata-only claims. R4 contextual conversational intelligence and R5 complete developer acceptance remain open. The four legacy Lua failures above also remain open.

## ONE Next Chunk

**R3 — Meaningful dataset integration.** Expose and verify the approved WordNet lexicon and real reviewed MASSIVE/SGD corpus path through the existing CodeBuilder, including imported/mapped/approved/compiled status and production-worker parser contribution without requiring Project Zomboid or remote archives at runtime.
