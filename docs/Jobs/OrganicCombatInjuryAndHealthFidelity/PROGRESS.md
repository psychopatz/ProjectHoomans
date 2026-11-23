# Organic Combat Injury & Health Fidelity — Progress

**Primary Repository:** `/home/psychopatz/Zomboid/Workshop/ProjectHoomans` (`main`)
**Baseline Commit:** `4522d6e952708bf3ccb013ce620ad9d698a60cb1`
**Reopened From:** H11 user live acceptance after contradictory runtime evidence on 2026-11-23
**Current HEAD at reopen:** `76b7a83b4958494c511cacc5d7c21977e9967e0c`
**Active Phase:** `H10R1` — Selected-Wound Truth Projection + Debug/Production Event Parity
**Parent Status:** `REOPENED_DEVELOPER_WORK_REQUIRED`; H11 deferred until H10R1–H10R8 pass.

## Phase Status

| Phase | Title | Status | Commit |
| --- | --- | --- | --- |
| `H0`–`H10` | Original Build 42 wound/physiology/dialogue implementation | `BASELINE_ACCEPTED_THEN_REOPENED_BY_LIVE_EVIDENCE` | through `76b7a83b4` |
| `H10R1` | Selected-Wound Truth Projection + Debug/Production Event Parity | `ACTIVE` | pending |
| `H10R2` | Immediate Pain-Reaction Beat + Escalation/Cooldown Policy | `PENDING` | pending |
| `H10R3` | Witness Observation Gating + Non-Colonist Injury Awareness | `PENDING` | pending |
| `H10R4` | Core Semantic Microplanning: Modifiers, Clause Relations, Discourse Focus | `PENDING` | pending |
| `H10R5` | Interactive Injury Observation/Triage Scenes + Item-Aware Aid | `PENDING` | pending |
| `H10R6` | Relationship/Disposition/Inventory Outcome Policy + Action Contracts | `PENDING` | pending |
| `H10R7` | Semantic-Truth Quality Sweep + Negative-Claim Guards | `PENDING` | pending |
| `H10R8` | EN/TL Variety, MP/Save/Scale/Performance Regression + Closure | `PENDING` | pending |
| `H11` | User Live SP/MP Acceptance | `DEFERRED` | resumes after H10R1–H10R8 |


## Reopen Evidence — 2026-11-23 Live Acceptance

User runtime testing invalidated the previous H10 closure claim without invalidating the underlying H0–H10 foundation. Mandatory repair evidence:

- `ApplyDebugWound()` mutates wound/health state but does **not** call `Internal.NotifyWoundCallout()`, so the Character Health debug `Random Body Part` action bypasses the production semantic wound event and produces no immediate pain/interactive reaction.
- fighting-injured realization currently collapses treatment into `patchState = patched_up`; canonical wording can mention a **splint** even when the selected wound is merely bandaged.
- whole-body `treatmentState` may describe treatment on a different wound than the selected wound/body part being spoken about.
- `patched_up_lower_limb_severe` can claim `can't run fast` from coarse region+severity even when the selected wound's authoritative `functionalImpairment` does not support locomotion loss.
- current ally witness gating is a short recent-reaction penalty, not a per-observer/per-injured first-of-day + injury-revision gate.
- current responder discovery is squad/ally oriented; it does not yet support bounded non-colonist/stranger observations such as visible blood, open wounds, dirty/soaked dressings, or obvious sickness.
- immediate pain vocalization is not a dedicated semantic Beat; `SecondaryChannel` alert bark is insufficient to represent wound type/severity/body part.

These are developer-side correctness/robustness defects. H11 resumes only after the repair phases close.

## Developer-Side Closure Summary (`H0`–`H10`)

- **Build 42 Wound, Treatment & Region Fidelity (`H1`, `H2`):** All 17 vanilla body parts and 5 functional regions (`head_neck`, `torso`, `pelvis_groin`, `upper_limb`, `lower_limb`) are preserved across runtime and save/load codecs (`PNC_HealthWoundCodec.lua`, `PNC_HealthBodyCodec.lua`, `PNC_HealthCompactCodec.lua`). Physical trauma severity (`physicalSeverityBand`) is cleanly decoupled from Knox virus danger (`knoxExposure = "impossible" | "possible" | "confirmed"`), dirty-cached on `record.runtime.healthProjection` (`Wounds.GetOrBuildProjection`, `Wounds.InvalidateProjection`).
- **Build 42 Transmission (`1`–`4`), Mortality (`7`) & Ordinary Infection (`H2`):** Mirrors `BodyPart.java:685-837` (`1` Blood+Saliva: bite 100%, laceration 25%, scratch 7%; `2` Saliva Only: bite 100%, cut/scratch 0%; `3` Everyone's Infected; `4` None: 0%), gates Knox infection strictly to zombie wounds, implements `Mortality == 7` non-lethal fake infection fever recovery, and evolves ordinary `infectedWound` + `woundInfectionLevel` (`0..10`) with `Disinfect`, `Cauterize`, `RemoveGlass`, and `RemoveBullet`.
- **Live & Abstract Physiology Parity (`H3`):** `Wounds.UpdatePhysiology` (`PNC_NPCWounds_Physiology.lua` + `_PhysiologyEnv.lua`) evolves wetness, core/skin temperature, cold strength, fever, and sickness identically for Live (`Wounds.Update`) and Abstract (`Needs.Update` in `PNC_IndividualNeeds_Evolution.lua`) NPCs, emitting `NPC_PHYSIOLOGY_BAND_CHANGED` only on semantic band transitions.
- **Beats, Director Arbitration & Interactive Scene Handoff (`H4`–`H8`):** Upgraded `combat.wound.received_beat`, `combat.fighting.injured_callout`, `combat.wound.ally_reaction`, and `combat.injury.triage_exchange` with `bite_possible_exposure`, `bite_confirmed_symptomatic`, `bite_non_transmissible`, `pelvis_groin` variants, `with_wounds_dirty_bandage`, `post_combat_injury_check`, and physiology transitions in EN and TL (`reconcile.py --check` clean). Director-style utility arbitration selects 1 responder by default (2nd only on bite conflict or critical trauma + medic, `<= 4` participants). Player triage replies hard-filter offers via `Predicates.Evaluate`, resolve deterministic node `responsePool` replies, cancel pending Beat replies, open a bounded `Scene`, and feed `Wounds.EvaluateBiteConflictPolicy` without any `recommendedAction` in dialogue modules.
