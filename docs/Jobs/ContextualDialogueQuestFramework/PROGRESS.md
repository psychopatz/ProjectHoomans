# Contextual Dialogue & Quest Framework — Current Progress

**Updated:** 2026-10-19
**Repository:** `psychopatz/ProjectHoomans`
**Branch:** `codex/contextual-dialogue-quest-framework-0a`
**R0A implementation commit:** `a591ec7e2df1b0fe4cdf751948a587e07870c387`
**R0B interaction explorer commit:** `dd775b0e0c5b1fe35b2c10392dd6e4545e85cfb9`
**R1/Studio foundation commit:** `e50a2ae318052e665bd88f7fe537230d7987744d`
**R2 composer commit:** `5d335b26405be4223c27cdb1df827f2a8d993304`
**Upstream:** `origin/docs/contextual-dialogue-quest-framework-20261018`
**Core dependency:** `/home/psychopatz/Zomboid/Workshop/psychopatzCore` at `50022acf90d5a39995be552b7a1e1de21b59168b`
**Historical implementation evidence:** `HISTORY_S0_S6_20261019.md` is preserved untouched.

## Status

R0A and R0B are accepted. The first R1/R2 implementation slices are committed, but the expanded Semantic Studio recovery is still **IN PROGRESS** and is not ready for user live testing. The remaining acceptance gap is reusable configured world-fact block instances across more than one generated flow, with the full approved artifact diff and worker proof.

The checkout and Core dependency were verified before implementation. The Hoomans checkout was clean on the branch above with no concurrent agent changes present. No Project Zomboid process, multiplayer host, mod installation, or Workshop publish was used.

## Completed recovery work

### R0A — Production INSULT response repair

The real worker recognized `"fuck you"` as `INSULT` (`pnc.social.insult`, confidence `0.99`) and selected `HOSTILE_REMARK_RECEIVED`. The failure was downstream: rejected or unavailable social authority results entered the generic `ActionRejected` adapter, which only specialized FOLLOW/STOP and therefore emitted `"I couldn't do that right now."` for INSULT/THREAT.

The existing Core IR, Hoomans policy, social authority, transport, event definitions, response queue, and Simulation inspector were preserved. Social rejection/unavailable response templates, server authority markers, harness-only unavailable transport control, EN/TL translations, and bounded inspector `execution` fields were added.

Real-worker evidence:

- Authorized INSULT: deterministic policy route, server `applied`, event `player_dialogue_insult`, one relationship delta (`approval -4.36`, `respect -3.27`), final text `"Then leave me alone."`.
- Invalid lease: `rejected / invalid_lease / authority=server`, no relationship change, final text `"I heard you, but I couldn't apply that social reaction."`.
- Unavailable transport: `semantic_social_dispatch_unavailable / semantic_social_transport_unavailable`, no transport/effect, final text `"I heard you, but I couldn't send that social reaction right now."`.
- Self-directed `"I'm an idiot"`: `SELF_REFLECTION`, no social authority dispatch. THREAT and pure preview behavior remain covered.

### R0B — Live Interaction Explorer

The existing production Lua FlowEditor catalog now exposes policy branches resolved by `DialoguePolicy`, Core concepts/speech acts/triggers, registered FlowRegistry flows, capability bindings, generated coverage, and bounded summaries of the 100 registered response pools. The existing Studio surface has a searchable Interaction Explorer; INSULT, FOLLOW, and NEEDS resolve to their real policy/trigger/flow/capability/generated routes. No second parser, registry, or execution path was introduced.

### R1/R2 — Composition and Studio foundation

`semantic.interaction_spec.v1` provides typed trigger, capability, response-pool instances and typed edges through the existing CodeBuilder. Preview is effect-free; changing a response block changes generated Lua fingerprints; invalid connections and unapproved generation write nothing. An approved temporary-runtime overlay was exercised with the real Lua worker: generated “stay with me” was recognized as `STAY` and dispatched through the existing `pnc:companion.stay` capability.

The top-level GUI is now two workspaces, Studio and Simulation. Studio contains the workflow, Flow + interactions graph/codeblock editor, Dataset Library, Block palette, live Interaction Explorer, and an ordinary-field Interaction Composer that previews, approves, generates, and restarts the existing worker without hand-editing multiple JSON/Lua files. Simulation retains the conversation and raw/inspector traces.

## Verification evidence

- Python semantic harness: `213/213 PASS` on the full discovery run before the final composer-only GUI addition; post-composer focused app/spec run: `13/13 PASS`.
- Focused real Lua social smoke: `2/2 PASS` (`pnc_semantic_social_chat_smoke`, `pnc_semantic_social_smoke`).
- Existing `pnc_semantic` suite: `64/68 PASS`; the same four historical failures remain unchanged:
  - `pnc_semantic_gift_offer_smoke`: agreement without a live offer expected `SOCIAL_ACKNOWLEDGED`, got `COMMAND_ACCEPTED`.
  - `pnc_semantic_local_route_smoke`: local greeting expected one queued response, got two.
  - `pnc_semantic_inventory_dialogue_smoke`: second local turn expected queue size two, got three.
  - `pnc_semantic_state_response_smoke`: acceptance expected `SOCIAL_ACKNOWLEDGED`, got `COMMAND_ACCEPTED`.
  These remain separate legacy route/response defects and were not attributed to R0A–R2.
- Harness doctor: PASS — Python 3.12.3, Tk/display, Core path, Lua 5.3.6, worker syntax, boot, PING, and CAPABILITIES.
- Changed Lua syntax, EN/TL JSON, and Python syntax: PASS.
- `pz-verify`: zero Kahlua errors/warnings and zero hardcoded UI-string findings. The pre-existing response adapter remains an advisory 5,613-token file; it was not split.
- `git diff --check`: PASS.

## Remaining product gaps

R1 still needs a reusable world-fact/condition block instance referenced by two generated flows and a real worker acceptance check for both branches. R3 dataset integration still needs actual WordNet compiled lexicon/Core/worker evidence and reviewed broad-corpus import exposure. R4 contextual conversational intelligence and R5 complete developer acceptance remain open. The four legacy Lua failures above are also open.

## ONE Next Chunk

**R1 completion — Shared typed world-fact composition.** Extend the canonical InteractionSpec to support one configured authoritative world-fact/condition block reused by two generated flows, prove that the shared block changes both generated Lua routes, preview/diff remains pure until approval, and run both routes in the actual Lua worker without fabricated gameplay effects.
