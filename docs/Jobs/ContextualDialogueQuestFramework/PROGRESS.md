# Contextual Dialogue & Quest Framework — Current Progress

**Updated:** 2026-10-19
**Repository:** `psychopatz/ProjectHoomans`
**Branch:** `codex/contextual-dialogue-quest-framework-0a`
**HEAD:** `a591ec7e2df1b0fe4cdf751948a587e07870c387` (`fix semantic social rejection responses`)
**Upstream:** `origin/docs/contextual-dialogue-quest-framework-20261018`
**Core dependency:** `/home/psychopatz/Zomboid/Workshop/psychopatzCore` at `50022acf90d5a39995be552b7a1e1de21b59168b`
**Historical implementation evidence:** `HISTORY_S0_S6_20261019.md` is preserved untouched.

## Status

R0A is accepted for the recovered production Lua worker path. The expanded Semantic Studio recovery remains **IN PROGRESS** and is not ready for user live testing because R0B–R5 product gaps remain.

The checkout and Core dependency were verified before implementation. The Hoomans checkout was clean, on the branch above, with no concurrent agent changes present. No Project Zomboid process, multiplayer host, mod installation, or Workshop publish was used.

## R0A — Reproduce and repair INSULT handling

The original failure was not failed semantic recognition. The real worker recognized `"fuck you"` as `INSULT` (`pnc.social.insult`, confidence `0.99`) and the policy selected `HOSTILE_REMARK_RECEIVED`. The social authority result was then passed through the generic `ActionRejected` response adapter whenever transport or authority rejected the action. That adapter only had action-specific text for FOLLOW/STOP, so INSULT/THREAT fell through to `"I couldn't do that right now."`.

The implementation keeps the existing Core IR, policy, social authority, transport, event definitions, and response architecture. It adds only:

- social-specific rejected/unavailable response templates for INSULT, HOSTILE_REMARK, and THREATEN;
- an explicit server authority marker on social accepted/rejected results;
- harness-only transport unavailability control, which emits no fabricated server event or relationship effect;
- `execution` data in the existing Simulation conversation inspector containing route, policy/flow owner, authority result, status, request/NPC IDs, rejection reason, response template, and final text;
- EN/TL translations and focused real-worker tests.

Observed real-worker outcomes:

- Authorized `"fuck you"`: `INSULT` → `HOSTILE_REMARK_RECEIVED` → deterministic policy route → server authority `applied`, event `player_dialogue_insult`, one relationship delta (`approval -4.36`, `respect -3.27`), final NPC text `"Then leave me alone."`.
- Invalid lease: semantic turn remains accepted, social authority returns `rejected / invalid_lease / authority=server`, no relationship change, final text `"I heard you, but I couldn't apply that social reaction."`.
- Harness transport unavailable: `semantic_social_dispatch_unavailable / semantic_social_transport_unavailable`, no transport event and no relationship change, final text `"I heard you, but I couldn't send that social reaction right now."`.
- Self-directed `"I'm an idiot"`: `SELF_REFLECTION`, no social authority dispatch.
- THREAT, contextual social reactions, EN/TL response selection, and pure preview behavior remain covered by the focused worker suite.

## Verification evidence

- Focused real Lua social smoke: `2/2 PASS` (`pnc_semantic_social_chat_smoke`, `pnc_semantic_social_smoke`).
- Existing `pnc_semantic` suite: `64/68 PASS`; the same four previously reported failures remain and were not caused or fixed by R0A:
  - `pnc_semantic_gift_offer_smoke`: agreement without a live offer expected `SOCIAL_ACKNOWLEDGED`, got `COMMAND_ACCEPTED`.
  - `pnc_semantic_local_route_smoke`: local greeting expected one queued response, got two.
  - `pnc_semantic_inventory_dialogue_smoke`: second local turn expected queue size two, got three.
  - `pnc_semantic_state_response_smoke`: acceptance expected `SOCIAL_ACKNOWLEDGED`, got `COMMAND_ACCEPTED`.
  These remain separate legacy route/response defects; no root-cause claim is made for them in R0A.
- Python real-worker focused tests: `14/14 PASS` across contextual social reactions and the conversation inspector.
- Harness doctor: PASS — Python 3.12.3, Tk/display, Core path, Lua 5.3.6, worker syntax, boot, PING, and CAPABILITIES.
- Lua syntax, EN/TL JSON, and Python syntax checks: PASS.
- `pz-verify` on changed Lua: zero Kahlua errors/warnings and zero hardcoded UI-string findings. The existing response-adapter file remains above the 2,000-token advisory threshold (`5,613` estimated tokens); it was not split in R0A.
- `git diff --check`: PASS.

## Remaining product gaps

The existing recovery roadmap still applies: Flow Editor discovery does not yet expose every production policy/capability route; block validation does not yet compose selected instances into generated production Lua; dataset integration remains metadata/fixture limited; and the GUI remains fragmented rather than a unified authoring environment. These are not claimed solved by R0A.

## ONE Next Chunk

**R0B — Unified Interaction Explorer.** Discover and expose every production semantic interaction—Core language concepts, policy branches, registered flows, gameplay capabilities, response pools, and generated definitions—in the existing Semantic Lab explorer. INSULT, FOLLOW, and NEEDS must be searchable with their complete real execution routes, while preserving the current canonical runtime and Simulation inspector.
