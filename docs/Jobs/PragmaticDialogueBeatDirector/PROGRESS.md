# Progress — Coherent Emergent Conversation

**Status:** IN PROGRESS — live-regression quality recovery.
**Accepted foundation:** C0–C11 + L1 + L2 + L3.
**Active phase:** L4 — NPC microplanning, mirroring and dialogue diversity.
**Branch:** existing `main`.

## Current truth

The exact Dana regression remains the acceptance anchor.

Accepted recovery:

- **L1:** current-turn generated direct responses are the native Response Channel; Back restores authored/root navigation;
- **L2:** relationship-memory and conduct-evidence capacity no longer reject an otherwise valid social interaction;
- **L3:** hostility now exposes typed `CLAIM_JOKE` and `DOUBLE_DOWN` strategies alongside apology/challenge/dismiss/follow-up, using compiler-owned EN/TL constructions;
- `CLAIM_JOKE` is a repair semantic frame and enters `beat.reconciliation`;
- `DOUBLE_DOWN` is a hostile semantic frame and remains in `beat.argument_escalation`;
- exact Dana surface includes the new repair/escalation choices;
- L3/C6-C7/L1/L2 focused batch: **16/16 PASS**;
- full `pnc_semantic`: **99/99 PASS**.

The remaining quality defect is NPC realization. Dana commonly selects `behavior.warn / BOUNDARY_WARNING`; `UtterancePlan.FromInteraction()` does not map WARN, so the response falls back to sparse authored Dialogue Content. MIRROR works only when `RETALIATE_VERBALLY` wins and currently has one construction per locale.

## Immediate Next Chunk — L4

Expand the existing UtterancePlan/SpeechRealization authority rather than adding response definitions.

Required first slice:

- map `WARN / BOUNDARY_WARNING` to a compositional WARN strategy;
- retain contextual `RETALIATE_VERBALLY / MIRROR`, `DEESCALATE`, reconciliation and acknowledgement mappings;
- add several bounded EN/TL WARN constructions and more than one MIRROR/retort construction where semantically safe;
- construction selection is deterministic for stable semantic/style/relationship/turn context;
- style/relationship hints may choose wording but may not change semantic intent;
- canonical lexemes remain semantic-derived; raw input is never concatenated;
- unsupported composition still falls back to Dialogue Content;
- Inspector/response projection exposes the selected construction/strategy.

Director behavior arbitration remains separate from realization. Do not force MIRROR for every insult; Dana may legitimately WARN while a more aggressive/confident NPC retaliates.

## Remaining mandatory phase

- **L5:** visible-surface + persistence + EN/TL integrated acceptance, deterministic generation/context-health, broad regression and user live-test handoff.

## Safety / architecture invariants

- one parser/discourse/button/response/gameplay authority;
- one SpeechRealization authority;
- no giant generated response catalog;
- no raw player-text echo;
- no transcript persistence;
- bounded relationship/conduct storage remains bounded;
- generated files stay compiler output;
- no Workshop publication or source-save mutation.

Git history is the archive for completed phase detail; keep this file current and compact.
