# Phase 0B — reviewed deterministic baseline matrix

This is a characterization artifact for the existing semantic system. Every
assertion below runs the real persistent Semantic Lab Lua worker and reads the
production IR, decision, routed situation and worker traces. The matrix does
not introduce a reaction selector or change response semantics.

## Verification record

- Project Hoomans: `35c0e741` on `feat/contextual-semantic-harness-phase0a`
- PsychopatzCore: `0212491d2af3597cceaa7353e62f01ef54adca44`
- Runtime: `/usr/bin/lua5.3` Lua 5.3.6; Python 3.12.3 in the Semantic Lab
  virtual environment
- Matrix command: `python3 -m unittest tools.semantic_harness.tests.test_contextual_baseline_matrix -v` — **PASS 3/3** in 3.91s
- Existing Phase 0A focus command: `python3 -m unittest tools.semantic_harness.tests.test_wellbeing_projection -v` — **PASS 6/6**
- Conflict result: every matrix run returned `conflicts=[]`; no `audit_truncated`
  record occurred.

## Cases

| ID | Scenario and utterance | Production IR | Branch / response | Routed context and state | Effects |
| --- | --- | --- | --- | --- | --- |
| `greeting_default` | Default NPC; `hello there` | `GREET`, `GREET`, `pnc.social.greet`, confidence `1.0` | `GREET_ACKNOWLEDGED`; `semantic.greet.withdrawn` / “Hey.” | `activity=idle`, `healthState=healthy`, relationship `unknown`; state sequence `1` | `llmCalls=0`, no transport/tool calls |
| `wellbeing_injured` | `healthState=injured`, `activeBehavior=treatment`, explicit empty needs/conditions; `Are you okay?` | `QUESTION/WELLBEING`, `pnc.question.wellbeing_okay`, confidence `0.99` | `QUESTION_RECEIVED`; `semantic.question.wellbeing.injured` / “A little banged up, but I'll manage.” | `healthState=injured`, `activity=treatment`, `busy=true`; state sequence `1` | `llmCalls=0`, no transport/tool calls |
| `activity_fishing` | `activeBehavior=fishing`, explicit empty needs/conditions; `What are you doing?` | `QUESTION/ACTIVITY`, `pnc.question.activity`, confidence `0.99` | `QUESTION_RECEIVED`; `semantic.question.activity.fishing` / “I'm trying to catch something.” | `activity=fishing`, `busy=true`; state sequence `1` | `llmCalls=0`, no transport/tool calls |
| `time_default` | Default NPC; `What time is it?` | `QUESTION/TIME`, `pnc.question.time`, confidence `0.99` | `QUESTION_RECEIVED`; `semantic.question.time` / “It's 1:30 PM.” | Previous topic remains `greeting`; state sequence `1` | `llmCalls=0`, no transport/tool calls |
| `identity_exchange` | Default NPC; `who are you` → `im psycho` in one worker | `QUESTION/IDENTITY` → `INFORM/IDENTITY`, second pattern `pnc.identity.self_name_im_plain`, confidence `0.93` | `QUESTION_RECEIVED` → `IDENTITY_CLAIM_RECEIVED`; identity exchange response | First state sequence `1`; second before/after state sequences `1→2` | Intended single-player worker transport contains `SemanticIdentityRequest` and `SemanticIdentityResult`; normalized calls are `SemanticIdentityRequest` and `AdjustRelationship`; no LLM |
| `wellbeing_follow_up` | Injured/treatment NPC; `Are you okay?` → `What's wrong?` in one worker | `QUESTION/WELLBEING` → unresolved IR with omitted nil intent | `QUESTION_RECEIVED` / injured disclosure → `ASK_CLARIFICATION` / `semantic.ask_clarification` | Real state advances `1→2`; addressee remains the same NPC | `llmCalls=0`, no transport/tool calls, no duplicate event; coherent disclosure follow-up remains Phase 2 work |

The identity row records the existing authoritative transport contract, not a
claim of native multiplayer acceptance. The worker's single-player boundary
is mocked. Native SP and MP are **not tested** for this matrix.

## Review constraints

- The response IDs and situation values above are observed outputs, not JSON
  fixture expectations. The test asserts them after `PNC.Semantics.DialogueInput.Submit`
  has run through production Lua.
- `contextBefore` and `contextAfter` are inspected for every case. The first
  turn has a null state; later turns retain bounded semantic state and
  monotonically advance sequence.
- No case adds an automatic task, inventory transfer or relationship change
  except the existing identity-claim path, whose request/result and bounded
  relationship adjustment are explicitly inspected.
- The unresolved `"What's wrong?"` result is recorded as current behavior. It
  is not promoted to a successful wellbeing follow-up and is not repaired in
  Phase 0B.
