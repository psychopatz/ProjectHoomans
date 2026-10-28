# Progress — Coherent Emergent Conversation

**Status:** IN PROGRESS — live-regression quality recovery.
**Accepted foundation:** C0–C11.
**Active phase:** L1 — direct-response presentation authority.
**Branch:** existing `main`.

## Current truth

The user's native Semantic Lab test disproved several acceptance assumptions without invalidating the underlying semantic architecture.

Exact reproduced case:

- save: `Sandbox/2026-10-22_15-18-56/global_mod_data.bin`;
- NPC: `npcDanapatz_Y5KK` / Dana patz;
- input: `fuckyouuuu`.

Verified runtime evidence:

- NLU recovers `fuckyouuuu` → `fuck you` → directed `INSULT`, confidence 0.90;
- generated affordances are produced: `APOLOGIZE`, `CHALLENGE`, `DISMISS`, `ASK_WHY`;
- those candidates live in `conversation_branch`;
- `buildGroups()` keeps `conversation_landing` selected because the current topic is still `greeting`;
- the actual Response Channel therefore shows only landing/root actions;
- Director selects `behavior.warn / BOUNDARY_WARNING` for Dana because WARN scores 0.65 vs RETALIATE 0.55;
- `UtterancePlan.FromInteraction()` has no WARN mapping, so common boundary reactions fall back to sparse authored Dialogue Content;
- the saved relationship memory is saturated enough that `ApplyEventMutation()` returns `memory_pruned_by_limit`;
- that rejection causes presentation to replace the semantic response with the generic social-interaction rejection line.

The earlier C6/C7 tests proved internal candidate generation and microplanning but did not require the generated candidates to become the native visible choice surface. C9 decoupled conduct evidence, but not relationship-memory retention.

## Immediate Next Chunk — L1

Fix the selected-group rule in the existing DialogueSuggestions projection so current-turn `DIRECT_RESPONSE` / `conversation_branch` responses become the native visible Response Channel after a conversational turn.

Constraints:

- keep one DialogueSuggestions/button authority;
- keep Core's existing native choice surface;
- explicit semantic navigation must still win;
- root/static actions remain reachable via existing Back/navigation;
- do not render a second generated-button surface;
- do not reparse generated display text.

Add an exact save-backed regression proving:

`fuckyouuuu` → generated direct responses → selected `conversation_branch` → native `session.choices` / TalkParity Response Channel contains those rows.

## Remaining mandatory phases

- **L2:** decouple relationship-memory retention from immediate social reaction/effect;
- **L3:** add richer typed hostility continuations such as CLAIM_JOKE and DOUBLE_DOWN;
- **L4:** expand NPC UtterancePlan coverage/diversity, including WARN and contextual MIRROR;
- **L5:** visible-surface + persistence + EN/TL integrated acceptance and user live handoff.

## Safety / architecture invariants

- no parallel parser, button engine, response engine or gameplay authority;
- no giant generated response catalog;
- no raw player-text echo into composed speech;
- no transcript persistence;
- bounded memory/storage remains bounded;
- generated files stay compiler output, not authoring surfaces;
- no Workshop publication or native-game mutation;
- source save remains read-only.

Git history is the archive for completed C0–C11 details; do not re-expand this file with old phase narratives.
