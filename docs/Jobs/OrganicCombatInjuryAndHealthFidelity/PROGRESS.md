# Organic Combat Injury & Health Fidelity — Progress

**Primary Repository:** `/home/psychopatz/Zomboid/Workshop/ProjectHoomans` (`main`)
**Baseline Commit:** `4522d6e952708bf3ccb013ce620ad9d698a60cb1`
**Reopened From:** H11 user live acceptance after contradictory runtime evidence on 2026-11-23
**Active Phase:** `H10R8` — EN/TL Variety, MP/Save/Scale/Performance Regression + Closure
**Parent Status:** `REOPENED_DEVELOPER_WORK_REQUIRED`; H11 deferred until H10R1–H10R8 pass.

## Phase Status

| Phase | Title | Status | Commit |
| --- | --- | --- | --- |
| `H0`–`H10` | Original Build 42 wound/physiology/dialogue implementation | `BASELINE_ACCEPTED_THEN_REOPENED_BY_LIVE_EVIDENCE` | through `76b7a83b4` |
| `H10R1` | Selected-Wound Truth Projection + Debug/Production Event Parity | `DONE` | `041d905217` |
| `H10R2` | Immediate Pain-Reaction Beat + Escalation/Cooldown Policy | `DONE` | H10R2 phase commit |
| `H10R3` | Witness Observation Gating + Non-Colonist Injury Awareness | `DONE` | H10R3 phase commit |
| `H10R4` | Core Semantic Microplanning: Modifiers, Clause Relations, Discourse Focus | `DONE` | H10R4 phase commit |
| `H10R5` | Interactive Injury Observation/Triage Scenes + Item-Aware Aid | `DONE` | H10R5 phase commit |
| `H10R6` | Relationship/Disposition/Inventory Outcome Policy + Action Contracts | `DONE` | H10R6 phase commit |
| `H10R7` | Semantic-Truth Quality Sweep + Negative-Claim Guards | `DONE` | H10R7 phase commit |
| `H10R8` | EN/TL Variety, MP/Save/Scale/Performance Regression + Closure | `ACTIVE` | pending |
| `H11` | User Live SP/MP Acceptance | `DEFERRED` | resumes after H10R1–H10R8 |

## Completed in H10R7

H10R7 validates structured wound claims against selected-wound facts before presentation, with a narrow text guard for older realizations. Optional harness evidence carries claims, modifiers, realized relations, referents, and authoritative wound, physiology, and inventory snapshots. Quality Sweep distinguishes same-variant reuse across context matrices from authoring duplication, semantic collisions, low variety, and variant collapse.

Nine focused Lua smokes, ten focused Core quality tests, and nine legacy quality and anti-duplication tests passed. The legacy sweep acceptance assertions still expect a smaller catalog, which H10R8 will reconcile against baseline. Continue H10R8 with broad semantic, runtime, static, authority, localization, and workload checks before H11.

## Completed in H10R6

H10R6 projects directional relationship, resolved disposition, scarcity, medical skill, role, and danger into observation and aid outcomes. The same open wound can elicit a supportive, clinical, protective, dismissive, or hostile reaction. Real aid opens a bounded gratitude follow-up and records one directed consequence through the relationship authority. Acknowledgment, decline, and no-supply chatter are transient.

Nine focused Lua smokes and a clean CodeBuilder check passed. Resume H10R7 by connecting selected-wound, clause, and action evidence to the Quality Sweep. Keep the existing R8 workload outside this phase.

## Completed in H10R5

H10R5 gives visible injury observation Beats five canonical triage replies. Existing server lease and active Beat provenance admit replies, while the existing Scene runtime binds the observer, injured NPC, and player to one bounded exchange. Aid consent revalidates selected wound, donor item, patient inventory, range, and current policy. Successful supply offers transfer an actual bandage through ServerInventory and direct care uses Treatment.

Nine focused Lua smokes passed, including generated flow validation, leased offer admission, denial, replay protection, no-supply truth, real transfer/rollback, MP loader guard, and the existing bite Scene regression. CodeBuilder reconciled cleanly against the isolated DynamicTrading snapshot. Resume H10R6 to extend relationship-sensitive wording, post-aid replies, and bounded outcome memory.

## Completed in H10R4

H10R4 extends the existing UtterancePlan with bounded semantic clauses, modifiers, logical relations, and transient referents. The fighting injury callout composes bandage and mobility language only when both facts belong to the selected wound. Ambiguity selects an explicit noun. Core owns the generic plan and locale-specific relation constructions. Hoomans owns injury constructions and wound eligibility.

Seven focused Lua smokes passed, including generated EN/TL realization, reference fallback, negative treatment/function checks, and the MP loader guard. CodeBuilder reconciled cleanly against the isolated DynamicTrading snapshot. Resume H10R5 by adding authoritatively item-aware offer and reply branches to the observation Beat and existing triage Scene.

## Completed in H10R3

- Immediate hit witnesses use a bounded nearby roster, same-floor geometry, and LOS to the live NPC body. The solo pain Beat no longer performs a squad query.
- A live actor crossing a spatial cell can notice an existing visible injury in a nearby survivor from any faction. Discovery uses at most four nearby candidates per crossing and emits at most one observation per crossing.
- A transient per-observer cache keeps up to 12 target signatures for the current world day. Delivery commits the observation. Unchanged repeats stay quiet, and new wounds, worsening symptoms, and changes in visible treatment reopen eligibility.
- Visible-condition EN/TL wording distinguishes heavy bleeding, dirty bandages, mobility loss, visible bite marks, and tentative infection. Medical skill can influence triage wording. Inspection or disclosure is required for stronger diagnosis.
- Six focused Lua smokes passed, including the production scale and MP server-file guards. Owner-scoped generation reconciled cleanly using an isolated committed DynamicTrading snapshot. The broad Lua run still reported the six known debug, presentation, dialogue, population, and translation smoke failures. The wound-heavy performance comparison remains an H10R8 gate.

## Completed in H10R2

- New `combat.injury.pain_reaction` CodeBuilder family (18 variants, EN/TL) and `semantic.combat.injury.pain_reaction` pool (`Social_Reactions_CombatInjury_Pain.lua`); `combat_injury_pain_reaction` routed in `Reaction_Pools.lua`.
- `PNC_SemanticCombatTargetCallouts_PainPolicy.lua`: disposition/panic-aware `S.ResolvePainReactionVariant`, `S.ShouldPreemptWoundCooldown` (2.5s pain window) and `S.ShouldPreemptWoundBeat` (4.5s received-Beat window; bite, gunshot, tier, severity >= moderate, severe new region).
- `PNC_SemanticCombatTargetCallouts_PainReaction.lua`: `S.EmitImmediatePainReaction` delivers immediately even solo (self-addressee fallback), with player reply offers, fact refs and zero priority hold so the received-wound Beat still follows.
- `S.OnNPCWoundReceived` emits the pain Beat first; returns success on solo/no-audience when the pain Beat landed. Debug wounds share the path (H10R1).
- Tests: `pnc_injury_pain_reaction_smoke` (suppress/preempt/variant probes); branching smoke asserts pain Beat precedes received Beat. Pre-existing unrelated failures at `041d905217` (translation manager, dialogue flow identity, presentation class, population director, context/animation debug, lightweight sim timeout) are unchanged.

## Completed in H10R1

- Routed `Wounds.ApplyDebugWound` (`PNC_NPCWounds_Debug.lua`) through `Internal.NotifyWoundCallout` (`PNC_NPCWounds_CombatWoundHelpers.lua`) with `provenance = "debug"`, ensuring Character Health `Random Body Part` / `damage_part` debug wounds exercise the exact same semantic wound-received event pipeline as combat and zombie damage.
- Separated whole-body treatment summaries (`wholeBodyTreatmentState`, `wholeBodyPatchState`, `wholeBodyFunctionalImpairment`) from selected-wound truth (`selectedWound` with `bandaged`, `bandageDirty`, `splinted`, `stitched`, `cauterized`, `haveGlass`, `haveBullet`, `bleeding`, `ordinaryInfection`, `woundInfectionLevel`, `physicalSeverity`, `bodyPart`, `bodyRegion`, `functionalImpairment`, `locomotionImpaired`, `knoxExposure`, `knoxStage`) in `PNC_NPCWounds_SelectedWoundTruth.lua` and `PNC_NPCWounds_Projection.lua`.
- Gated `S.ResolveFightingInjuredVariant` (`PNC_SemanticCombatTargetCallouts_WoundProfile.lua`) on `selectedWound.locomotionImpaired` for `lower_limb` and `pelvis_groin` so non-locomotor lower-body wounds never select locomotion-impaired (`_severe`) variants, and removed false `splint`/`limping` wording from generic `patched_up_lower_limb` realizations.
- Added `Wounds.ValidateRealizationAgainstSelectedWound` (`PNC_NPCWounds_TruthValidation.lua`) enforcing negative semantic assertions (`TREATMENT_REALIZATION_MISMATCH`, `FUNCTION_REALIZATION_MISMATCH`, `INFECTION_REALIZATION_MISMATCH`).
