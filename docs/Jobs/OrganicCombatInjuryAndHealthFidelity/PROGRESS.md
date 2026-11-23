# Organic Combat Injury & Health Fidelity — Progress

**Primary Repository:** `/home/psychopatz/Zomboid/Workshop/ProjectHoomans` (`main`)
**Baseline Commit:** `4522d6e952708bf3ccb013ce620ad9d698a60cb1`
**Reopened From:** H11 user live acceptance after contradictory runtime evidence on 2026-11-23
**Active Phase:** `H10R2` — Immediate Pain-Reaction Beat + Escalation/Cooldown Policy
**Parent Status:** `REOPENED_DEVELOPER_WORK_REQUIRED`; H11 deferred until H10R1–H10R8 pass.

## Phase Status

| Phase | Title | Status | Commit |
| --- | --- | --- | --- |
| `H0`–`H10` | Original Build 42 wound/physiology/dialogue implementation | `BASELINE_ACCEPTED_THEN_REOPENED_BY_LIVE_EVIDENCE` | through `76b7a83b4` |
| `H10R1` | Selected-Wound Truth Projection + Debug/Production Event Parity | `DONE` | Pending `H10R1` phase commit |
| `H10R2` | Immediate Pain-Reaction Beat + Escalation/Cooldown Policy | `ACTIVE` | pending |
| `H10R3` | Witness Observation Gating + Non-Colonist Injury Awareness | `PENDING` | pending |
| `H10R4` | Core Semantic Microplanning: Modifiers, Clause Relations, Discourse Focus | `PENDING` | pending |
| `H10R5` | Interactive Injury Observation/Triage Scenes + Item-Aware Aid | `PENDING` | pending |
| `H10R6` | Relationship/Disposition/Inventory Outcome Policy + Action Contracts | `PENDING` | pending |
| `H10R7` | Semantic-Truth Quality Sweep + Negative-Claim Guards | `PENDING` | pending |
| `H10R8` | EN/TL Variety, MP/Save/Scale/Performance Regression + Closure | `PENDING` | pending |
| `H11` | User Live SP/MP Acceptance | `DEFERRED` | resumes after H10R1–H10R8 |

## Completed in H10R1

- Routed `Wounds.ApplyDebugWound` (`PNC_NPCWounds_Debug.lua`) through `Internal.NotifyWoundCallout` (`PNC_NPCWounds_CombatWoundHelpers.lua`) with `provenance = "debug"`, ensuring Character Health `Random Body Part` / `damage_part` debug wounds exercise the exact same semantic wound-received event pipeline as combat and zombie damage.
- Separated whole-body treatment summaries (`wholeBodyTreatmentState`, `wholeBodyPatchState`, `wholeBodyFunctionalImpairment`) from selected-wound truth (`selectedWound` with `bandaged`, `bandageDirty`, `splinted`, `stitched`, `cauterized`, `haveGlass`, `haveBullet`, `bleeding`, `ordinaryInfection`, `woundInfectionLevel`, `physicalSeverity`, `bodyPart`, `bodyRegion`, `functionalImpairment`, `locomotionImpaired`, `knoxExposure`, `knoxStage`) in `PNC_NPCWounds_SelectedWoundTruth.lua` and `PNC_NPCWounds_Projection.lua`.
- Gated `S.ResolveFightingInjuredVariant` (`PNC_SemanticCombatTargetCallouts_WoundProfile.lua`) on `selectedWound.locomotionImpaired` for `lower_limb` and `pelvis_groin` so non-locomotor lower-body wounds never select locomotion-impaired (`_severe`) variants, and removed false `splint`/`limping` wording from generic `patched_up_lower_limb` realizations.
- Added `Wounds.ValidateRealizationAgainstSelectedWound` (`PNC_NPCWounds_TruthValidation.lua`) enforcing negative semantic assertions (`TREATMENT_REALIZATION_MISMATCH`, `FUNCTION_REALIZATION_MISMATCH`, `INFECTION_REALIZATION_MISMATCH`).
