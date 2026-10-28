# Progress — Coherent Emergent Conversation

**Status:** IN PROGRESS — live-regression quality recovery.
**Accepted foundation:** C0–C11 + L1.
**Active phase:** L2 — relationship-memory retention decoupling.
**Branch:** existing `main`.

## Current truth

The exact user regression is reproduced against:

- save: `Sandbox/2026-10-22_15-18-56/global_mod_data.bin`;
- NPC: `npcDanapatz_Y5KK` / Dana patz;
- input: `fuckyouuuu`.

Current verified state:

- NLU correctly recovers directed `INSULT` at confidence 0.90;
- generated direct responses are produced by the existing DialogueSuggestions provider;
- **L1 accepted:** `conversation_branch` now becomes the actual native Response Channel after the turn;
- Back returns to `conversation_landing` and authored/root actions remain reachable;
- exact Dana save + portable L1 regression passes;
- L1/C6/C7/C8/conversation-composition focused batch: **18/18 PASS**;
- full `pnc_semantic` Lua suite: **99/99 PASS**;
- GUI-only parity module could not import under the local Homebrew Python because `_tkinter` is unavailable; this is an environment limitation, not an L1 failure.

The next live-proven defect is persistence coupling:

- Dana's relationship memory is saturated;
- `Relationships.ApplyEventMutation()` appends/prunes then returns `memory_pruned_by_limit` when the new memory does not survive;
- `SocialEventService` treats that storage outcome as failure of the whole social interaction;
- presentation then replaces the Director's semantic reaction with `semantic.social.interaction.rejected`.

## Immediate Next Chunk — L2

Decouple bounded relationship-memory retention from the immediate social interaction/effect.

Required outcome:

- relationship mutation/effect may apply or clamp even if the newly proposed durable memory is pruned;
- bounded memory limits remain unchanged;
- relationship-memory outcome is reported explicitly as persisted/coalesced/pruned/dropped;
- conduct evidence remains independently reported;
- storage capacity alone must not produce `accepted=false`;
- the valid Director/SpeechRealization response must remain the player-facing NPC reaction.

Add both a portable saturation regression and the exact Dana save-backed regression.

## Remaining mandatory phases

- **L3:** richer typed hostility continuations such as CLAIM_JOKE and DOUBLE_DOWN;
- **L4:** broader NPC UtterancePlan coverage/diversity, including WARN and contextual MIRROR;
- **L5:** visible-surface + persistence + EN/TL integrated acceptance and user live handoff.

## Safety / architecture invariants

- one parser/discourse/button/response/gameplay authority;
- no giant generated response catalog;
- no raw player-text echo into composed speech;
- no transcript persistence;
- bounded relationship/conduct storage remains bounded;
- generated files stay compiler output;
- no Workshop publication or source-save mutation.

Git history is the archive for completed phase detail; keep this file current and compact.
