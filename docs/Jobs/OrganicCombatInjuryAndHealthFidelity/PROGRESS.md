# Organic Combat Injury & Health Fidelity — Progress

**Primary Repository:** `/home/psychopatz/Zomboid/Workshop/ProjectHoomans` (`main`)
**Baseline Commit:** `4522d6e952708bf3ccb013ce620ad9d698a60cb1`
**Active Phase:** `H8` — Compositional EN/TL Realizations & CodeBuilder Reconciliation

## Phase Status

| Phase | Title | Status | Commit |
| --- | --- | --- | --- |
| `H0` | Baseline Audit & Durable Job Docs | `DONE` | `2b096f92e09e2cac6b292e4ba3575dc3213d900a` |
| `H1` | Multi-Dimensional Health Model & Cached Projection | `DONE` | `3b659bd5c970cc139304c326a8445599ac0af36d` |
| `H2` | Build 42 Knox Transmission, Mortality & Ordinary Wound Infection | `DONE` | `52f25c9cd0fe558120c8bcc45485b55058ccf568` |
| `H3` | Lightweight Cold, Sickness, Fever & Thermoregulation Parity | `DONE` | `0d35403bc5060ec3ec7a7d4aa1f7c46da8ca31ea` |
| `H4` | Combat, Escalation, Treatment, Physiology & Post-Combat Beats | `DONE` | `e83e772070ce1f7bbf288e9c68b392b6bb92b653` |
| `H5` | Director-Style Ally Reaction Arbitration | `DONE` | `907a626ab0813d8db3f7532ff9dcdac3d020b068` |
| `H6` | Beat -> Player Response -> Multi-Actor Scene Handoff | `DONE` | `7458c3badcb5b4b710b40303c87cadb973d55154` |
| `H7` | Bite Conflict Facts/Behavior Policy & Bounded Memory | `DONE` | Pending `H7` phase commit |
| `H8` | EN/TL Realizations & CodeBuilder Reconciliation | `NEXT` | Pending |
| `H9` | Deterministic Tests, MP Authority & 200-NPC Scale Suite | `PENDING` | Pending |
| `H10` | Final Audit & Developer-Side Closure | `PENDING` | Pending |
| `H11` | User Live SP/MP Acceptance | `USER_OWNED` | Pending user runtime test |

## Completed in H7

- Removed `recommendedAction = "hostile_eliminate_bitten"` from `PNC_SemanticCombatTargetCallouts_WoundRoles.lua` and `_WoundDelivery.lua`; dialogue/callout modules now emit pure semantic `biteConflictFacts` (`challengerId`, `injuredId`, `knoxExposure`, `knoxStage`, `salivaTransmissible`, `challengerStance`, `challengerDispositions`, `relationshipApproval`, `relationshipState`, `timestamp`).
- Created `PNC_NPCWounds_BiteConflictPolicy.lua` (required from `PNC_NPCWounds_Snapshot.lua`) implementing `Wounds.EvaluateBiteConflictPolicy(observerRecord, targetRecord, context)` returning normalized stances (`none`, `protect`, `monitor`, `quarantine`, `abandon`, `threaten`, `execute_candidate`) and downgrading `execute_candidate`/`threaten` to `monitor`/`quarantine` when `activeInjuryTriageState` reflects player protection or quarantine orders.
- Created `PNC_SemanticCombatTargetCallouts_InjuryMemory.lua` (`S.RecordHighSalienceInjuryMemory`) recording bounded high-salience injury, bite-conflict, and triage-resolution memory provenance on `record.runtime.recentHighSalienceInjuryMemory` while keeping routine minor barks transient.
- Decoupled `ChoicePolicy.lua` (`+ ChoicePolicy_Scoring.lua`, `ChoicePolicy_Strategies.lua`) and `Reaction.lua` (`+ Reaction_Pools.lua`) so all 11 H7 files are `< 1960` `o200k_base` tokens with `0` Kahlua issues and `H7_PROBE_OK`.
