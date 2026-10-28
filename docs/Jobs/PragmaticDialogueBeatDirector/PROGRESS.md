# Progress — Coherent Emergent Conversation

**Status:** NEW IMPROVEMENT PLANNED — contextual social-act admission and compositional understanding. Existing C0–C11 + L0–L5 implementation remains developer-accepted; the new improvement has no implementation or acceptance evidence yet.
**Developer phases:** C0–C11 + L0–L5 accepted.
**Branch:** existing `main`.
**Next exact chunk:** U0 — reproduce ungrounded apology in SAVE/fixture production worker and capture decision/effect evidence. Then continue U1–U4. Native SP/MP verification stays user-owned after developer acceptance.

## Current truth

The live regression reported against Dana is developer-fixed and accepted.

Regression anchor:

- save: `Sandbox/2026-10-22_15-18-56/global_mod_data.bin`;
- NPC: `npcDanapatz_Y5KK` / Dana patz;
- input: `fuckyouuuu`.

The accepted chain now proves:

- compact/elongated input recovers to directed `INSULT`;
- Director selects behavior independently from wording;
- common `WARN / BOUNDARY_WARNING` uses bounded compiler-owned UtterancePlan realization;
- aggressive/confident NPCs may still select contextual `RETALIATE_VERBALLY / MIRROR`;
- bounded relationship-memory and conduct-evidence pruning are reported independently and do not reject the immediate social reaction;
- current-turn generated direct responses become Core's actual Response Channel;
- hostility exposes distinct typed repair/escalation/neutral choices including `CLAIM_JOKE` and `DOUBLE_DOWN`;
- generated clicks submit `semantic_click_frame` directly;
- `CLAIM_JOKE` enters `beat.reconciliation`;
- EN/TL wording is locale-owned;
- Back restores authored/root navigation;
- source save remains immutable.

No parallel parser, button renderer, response engine, gameplay authority, transcript store, or persistent generated-combination catalog was introduced.

## Final developer acceptance

Latest paired-checkout evidence:

- combined C0–C8 + L1–L5 focused Python suite: **61/61 PASS**;
- exact integrated L5 Dana/save chain: **2/2 PASS**;
- full ProjectHoomans `pnc_semantic`: **99/99 PASS**;
- social events: **1/1 PASS**;
- conduct: **2/2 PASS**;
- conduct-saturation baseline: **1/1 PASS**;
- compiler/context-health: **13/13 PASS**;
- two consecutive Conversation generations: byte-identical;
- context-health: PASS, **0** numeric shard violations, **0** opaque shard violations;
- PsychopatzCore semantic dialogue-turn, pattern-matcher and surface-recovery suites: PASS;
- source save hash unchanged;
- Lua/Python syntax and `git diff --check`: PASS before final documentation commit.

The local Homebrew Python lacks `_tkinter`, so the Tk GUI parity module could not be imported in that interpreter. This is not treated as native visual acceptance; the exact production TalkParity / `conversationPresentation.responseChannel` projection is covered headlessly, and final native GUI/game verification remains user-owned.

## Live-test handoff

Re-test the same Dana case first. Expected visible behavior after `fuckyouuuu`:

- NPC gives a real contextual reaction, not “I couldn't apply that social reaction”;
- Response Channel switches to current-turn options such as `I'm sorry.`, `I was joking.`, `Yeah, I meant it.`, challenge/dismiss/follow-up choices;
- selecting `I was joking.` repairs into reconciliation;
- repeated WARN-style hostility can vary deterministically instead of repeating one stock line;
- a sufficiently aggressive/confident NPC may MIRROR instead of WARN.

If a native failure remains, capture the exact input/click, preceding NPC line, visible Response Channel, and relevant Conversation Inspector trace. Reopen only the owning subsystem.

## Safety

- no Workshop publication;
- no source-save mutation;
- no root `AGENTS.md` goal-state edits;
- no hand-editing generated Conversation artifacts;
- no transcript/dynamic-combination persistence.

Git history is the implementation diary; keep this file compact.
