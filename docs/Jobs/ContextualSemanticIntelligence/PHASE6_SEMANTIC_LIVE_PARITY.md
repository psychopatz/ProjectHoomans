# Phase 6 — Semantic Lab/live semantic parity

## Scope

Semantic Lab is valid for the contextual semantic slice because its Lua
worker executes the checked-out production semantic modules. It is not a
native Project Zomboid acceptance environment. The parity claim is therefore
about the semantic production path and its bounded observations, not native
Java/UI/network behavior.

## Parity contract

The worker and live conversation share these seams:

1. `ProductionModules.lua` loads the real
   `PNC/Semantics/PNC_SemanticDialogueInput.lua` entrypoint through the test
   loader, alongside the real Core semantic module, Hoomans policy, context,
   presentation, actions and provider-fallback modules.
2. `Conversation.turn` calls the public production API
   `PNC.Semantics.DialogueInput.Submit(view, text)`. It reads
   `view.lastSemanticDialogueResult`, `view.lastSemanticActionResult` and the
   `dialogueSituation` retained by the production router; it does not recreate
   a Python parser or a second reaction selector.
3. Provider fallback is the live
   `PNC_SemanticDialogueInput_ProviderFallback.lua` module. A provider-enabled
   worker can record an attempted provider call, but rejection still follows
   the production deterministic `ASK_CLARIFICATION` path.
4. The worker replaces only explicit native boundaries: Project Zomboid UI
   constructors, the telemetry prompt, the conversation session, relationship
   storage, action responses and network transport. Unexpected production
   `require` failures abort worker startup instead of becoming silent stubs.

The contract is protected by
`tools/semantic_harness/tests/test_semantic_live_parity.py`.

## Fresh evidence — 2026-10-17

- `tools/semantic_harness/run_harness.sh --doctor --doctor-json`: **PASS**.
  Python 3.12.3, `/usr/bin/lua5.3` Lua 5.3.6, the checked-out Core and
  worker `READY/PING/CAPABILITIES` all passed.
- `python3 -m unittest tools.semantic_harness.tests.test_semantic_live_parity
  -v`: **PASS 4/4**.
- Real-worker contextual slice (parity, wellbeing projection, paraphrase,
  provider fallback, social reactions and baseline matrix): **PASS 26/26**.
- `python3 -m unittest discover -s tools/semantic_harness/tests -q`:
  **PASS 81/81** after the live discrepancy repair below.
- `tools/semantic_harness/run_harness.sh --test pnc_semantic`: **PASS 66/66**.

The provider parity cases exercised the real worker with the provider both
disabled and enabled: authored `follow me` stayed deterministic with no
provider call and the same action result; an unknown sentence stayed a
deterministic clarification with no action or transport, while the enabled
case recorded exactly one rejected provider attempt. The wellbeing and
contextual cases read the production router's returned IR, decision, bounded
context and routed situation.

## Native retest discrepancy and repair

The first controlled native conversation exposed two behavior gaps that the
original structural parity contract did not catch:

- The live text arrived as `whats wrong`. The catalog only registered
  `what's wrong` and `what is wrong`, so the follow-up became clarification.
- The harness could author `healthState="injured"`, but the live NPC health
  contract reports `normal` plus bounded body-health/HP data for a minor wound
  (and `incapacitated` for a downed NPC). The situation projection therefore
  missed the wound and could answer “I'm okay.”

The production fix adds the exact `whats wrong` alias and derives the semantic
`injured` signal from live body-wound/HP evidence or `incapacitated` state. The
Semantic Lab worker now accepts the same body-health shape, with focused
post-fix wellbeing/paraphrase coverage **13/13** and full coverage **81/81**.

## Explicit limit

This parity evidence does not accept native Project Zomboid SP/MP behavior,
Java object lifecycle, native UI rendering, engine queue/tick scheduling,
server authority or live PBrainZ provider success. Those remain open in
[`PHASE6_NATIVE_STATUS.md`](PHASE6_NATIVE_STATUS.md).
