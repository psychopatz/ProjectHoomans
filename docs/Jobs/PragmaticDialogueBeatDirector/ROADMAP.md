# Roadmap — Coherent Emergent Conversation

**Parent status:** C0–C11 + L0–L5 developer-accepted foundation.
**Accepted foundation:** preserve unless current runtime evidence disproves a specific invariant.
**Active phase:** none. Contextual evidence/memory architecture is owned by `docs/Jobs/UnifiedSemanticEvidenceArchitecture/`.

The former U0–U4 contextual expansion was moved to the dedicated Unified Semantic Evidence Architecture goal to avoid split ownership. `CONTEXTUAL_SEMANTIC_EXPANSION.md` remains evidence/history only; do not execute it as a separate roadmap.

The native/live Semantic Lab test on the saved actor `npcDanapatz_Y5KK` proved that the coherent-conversation foundation exists but several accepted gates were too shallow: generated affordances can exist in worker diagnostics without becoming the visible Response Channel, bounded relationship-memory retention can still reject an otherwise valid social interaction, and common NPC behaviors still fall back to sparse authored wording.

Do not restart C0–C11. Fix only the live-proven regressions below.

## L0 — exact live-save regression baseline

Reproduce the user case against:

- save: `Sandbox/2026-10-22_15-18-56/global_mod_data.bin`;
- NPC: `npcDanapatz_Y5KK` / Dana patz;
- input: `fuckyouuuu`.

Required baseline evidence:

- Core recovers the input to directed `INSULT`;
- generated affordances exist internally;
- visible Response Channel remains on `conversation_landing`;
- social action can reject with `memory_pruned_by_limit`;
- Director can select `behavior.warn / BOUNDARY_WARNING`;
- WARN lacks compositional realization and therefore falls back to sparse Dialogue Content.

**Status:** ACCEPTED BASELINE.

## L1 — direct-response presentation authority

**Status:** ACCEPTED.

Make the existing DialogueSuggestions authority surface the current turn's direct semantic responses in the same native Core choice surface.

Requirements:

- no second button renderer or side panel;
- generated/direct-response candidates stay in the existing semantic projection;
- a valid direct-response group outranks the root landing group after a conversational turn;
- explicit user navigation still wins while it is active;
- authored/root actions remain reachable through the existing Back/navigation model;
- native `session.choices`, TalkParity presentation, and Semantic Lab Response Channel must agree;
- generated choice display text remains presentation only; click submits the typed semantic frame.

**Gate:** on the exact Dana save after `fuckyouuuu`, the visible Response Channel contains the generated direct responses instead of only landing actions.

## L2 — relationship-memory retention decoupling

**Status:** ACCEPTED.

Apply the same semantic principle already used for conduct evidence to relationship-memory retention.

Requirements:

- immediate social meaning/reaction/effect is not rejected solely because a newly created relationship memory is pruned by a bounded memory budget;
- preserve bounded memory limits;
- distinguish:
  - interaction understood/selected;
  - relationship effect applied/clamped/none;
  - relationship memory persisted/coalesced/pruned/dropped;
  - conduct evidence persisted/coalesced/pruned/dropped;
- genuine authority/validation failures may still reject;
- presentation must not replace a valid NPC reaction with `semantic.social.interaction.rejected` merely because durable memory retention failed.

**Gate:** the saturated Dana save still receives a coherent NPC reaction and a truthful bounded-memory outcome.

## L3 — richer semantic player continuations

**Status:** ACCEPTED.

Expand generated affordances from generic repair/challenge choices into contextual conversational strategies without hardcoding a full sentence catalog.

For directed hostility, support contextually eligible strategies such as:

- positive/reparative: `CLAIM_JOKE`, `APOLOGIZE`, `DEESCALATE`;
- negative/escalating: `DOUBLE_DOWN`, `CHALLENGE`, `CALL_BLUFF`;
- neutral/deflecting: `DISMISS`, `ASK_WHY`, `CHANGE_TOPIC`;
- trait/context-induced options when grounded.

Requirements:

- strategies are typed semantic frames;
- stance is presentation/ranking metadata, not semantic authority;
- do not force one option from every lane;
- relationship, player traits, current beat/topic and world state may affect eligibility/rank;
- hidden NPC/private fields are not exposed in player-visible provenance;
- typed and button equivalents converge downstream.

**Gate:** representative hostile turns expose meaningfully different positive, negative and contextual continuations on the actual Response Channel.

## L4 — NPC microplanning, mirroring and dialogue diversity

**Status:** ACCEPTED.

Extend `UtterancePlan.FromInteraction` and compiler-owned realization data so common Director behaviors do not collapse to one bland authored line.

Cover at minimum:

- `WARN / BOUNDARY_WARNING`;
- `RETALIATE_VERBALLY / MIRROR`;
- `DEESCALATE`;
- `CHALLENGE`;
- `END_CONVERSATION`;
- reconciliation/acknowledgement paths already supported.

Requirements:

- MIRROR is contextual, not mandatory;
- behavior selection may consider aggression, confidence, panic, forgiveness, relationship tier/familiarity, recent hostility and immediate danger through existing bounded projections;
- realization may consider semantic style/relationship hints but never changes behavior meaning;
- multiple compiler-owned constructions per strategy are allowed;
- selection is deterministic for a stable turn/salt;
- canonical lexemes come from semantic evidence, never arbitrary raw player-text echo;
- unsupported composition falls back to ordinary Dialogue Content;
- EN/TL remain locale-owned; no runtime machine translation.

**Gate:** the same semantic behavior can produce several deterministic context/style-appropriate realizations, and common WARN cases no longer sound like one repeated stock sentence.

## L5 — visible-surface acceptance and live handoff

**Status:** ACCEPTED.

Run focused and broad acceptance across the real production worker and actual presentation projection.

Mandatory evidence:

- exact Dana save regression;
- generated candidates → selected group → `session.choices` → `conversationPresentation.responseChannel.rows`;
- click-frame execution parity;
- social effect independent from relationship-memory and conduct-memory retention;
- Director candidate/selection trace;
- UtterancePlan strategy/construction/lexeme provenance;
- EN/TL realization;
- bounded storage/context-health and deterministic generation;
- save source remains immutable;
- no transcript or dynamic-combination persistence;
- full semantic regression remains green.

Only then return to **READY FOR USER LIVE TEST**.

## Reopen rule

Do not rerun L0–L5 as a standing task. Reopen only the smallest owning phase when a native/live regression supplies new evidence. Internal candidate existence is still not sufficient acceptance when the visible native surface is wrong.
