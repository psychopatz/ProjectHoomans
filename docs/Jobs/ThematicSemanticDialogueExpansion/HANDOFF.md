---
handoff_schema: 1
updated_at: "2026-11-22T12:35:00Z"
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
branch: "main"
phase_commit: "self"
participant_psychopatzCore_head: "569e169"
participant_dynamicTrading_head: "04febebf"
state: "CLEAN_CHECKPOINT"
parent_status: "IN_PROGRESS"
phase: "D3"
chunk: "Scene/thread boundary and domain-neutral semantic speech transport"
retrieval_tier: "verify"
---

# Session Handoff

## What became true

- **D2 Complete (CODE_VERIFIED, TEST_VERIFIED):**
  - Created `PNC/ConvoEngine/DispositionProjection.lua` (8-dim `baseDisposition`, 6-axis transient `temporaryDemeanor`, `effectiveDisposition`, unified `ResolveStyle`).
  - Converged `ActorAdapter_ProjectHoomans`, `ChoicePolicy`, `GeneratedAffordanceProvider`, `AffordanceResponder`, `PNC_SemanticCombatReactionProfile`, `PNC_SemanticBeatContext`, `SpeechStyleContext`, and `PNC_ConversationRules_Conditions` onto the single resolved numeric disposition projection (zero trait double-counting, Scene and Beat style parity).
  - Verified 0 Kahlua errors/warnings and 20+ Lua smoke suites passing.

## Resume

1. Execute **D3** (Scene/thread boundary & domain-neutral semantic speech transport):
   - `psychopatzCore`: Isolate interactive `sceneID` lane vs transient `threadID` lane and priority floor in `PsychopatzSocialFlavorClient.lua` (preserving single queue + TTS).
   - `ProjectHoomans`: Extract domain-neutral `PNC_SemanticSpeechTransport.lua`, decouple `PNC_SemanticDialogueBeats*` from `CombatTargetCallouts`, make `CombatTargetCallouts` a combat adopter, enforce interactive Scene priority floor in `ScenePresentation`/`VoiceGateway`, and add D3 gate tests.
2. Proceed sequentially through D4 -> D5 -> D5A -> D6 -> D7 -> D8, stopping at D9.
