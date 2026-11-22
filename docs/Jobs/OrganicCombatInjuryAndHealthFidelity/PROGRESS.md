# Organic Combat Injury & Health Fidelity — Progress

**Primary Repository:** `/home/psychopatz/Zomboid/Workshop/ProjectHoomans` (`main`)
**Baseline Commit:** `4522d6e952708bf3ccb013ce620ad9d698a60cb1`
**Active Phase:** `H11` — User Live Project Zomboid SP/MP Acceptance (`H0`–`H10` Developer Phases Complete)

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
| `H7` | Bite Conflict Facts/Behavior Policy & Bounded Memory | `DONE` | `85a9de85577ffb9e51013977bb732adc9a655c3d` |
| `H8` | EN/TL Realizations & CodeBuilder Reconciliation | `DONE` | `4f55f861e2571837a7670c08f18574a1962e2993` (`psychopatzCore`: `1a67819822909751090f1a68ef02faa50d667beb`) |
| `H9` | Deterministic Tests, MP Authority & 200-NPC Scale Suite | `DONE` | `15b4316eccccbdd664546ec2b941ccda093b3f34` |
| `H10` | Final Audit & Developer-Side Closure | `DONE` | Pending `H10` phase commit |
| `H11` | User Live SP/MP Acceptance | `USER_OWNED` | Ready for user runtime test |

## Developer-Side Closure Summary (`H0`–`H10`)

- **Build 42 Wound, Treatment & Region Fidelity (`H1`, `H2`):** All 17 vanilla body parts and 5 functional regions (`head_neck`, `torso`, `pelvis_groin`, `upper_limb`, `lower_limb`) are preserved across runtime and save/load codecs (`PNC_HealthWoundCodec.lua`, `PNC_HealthBodyCodec.lua`, `PNC_HealthCompactCodec.lua`). Physical trauma severity (`physicalSeverityBand`) is cleanly decoupled from Knox virus danger (`knoxExposure = "impossible" | "possible" | "confirmed"`), dirty-cached on `record.runtime.healthProjection` (`Wounds.GetOrBuildProjection`, `Wounds.InvalidateProjection`).
- **Build 42 Transmission (`1`–`4`), Mortality (`7`) & Ordinary Infection (`H2`):** Mirrors `BodyPart.java:685-837` (`1` Blood+Saliva: bite 100%, laceration 25%, scratch 7%; `2` Saliva Only: bite 100%, cut/scratch 0%; `3` Everyone's Infected; `4` None: 0%), gates Knox infection strictly to zombie wounds, implements `Mortality == 7` non-lethal fake infection fever recovery, and evolves ordinary `infectedWound` + `woundInfectionLevel` (`0..10`) with `Disinfect`, `Cauterize`, `RemoveGlass`, and `RemoveBullet`.
- **Live & Abstract Physiology Parity (`H3`):** `Wounds.UpdatePhysiology` (`PNC_NPCWounds_Physiology.lua` + `_PhysiologyEnv.lua`) evolves wetness, core/skin temperature, cold strength, fever, and sickness identically for Live (`Wounds.Update`) and Abstract (`Needs.Update` in `PNC_IndividualNeeds_Evolution.lua`) NPCs, emitting `NPC_PHYSIOLOGY_BAND_CHANGED` only on semantic band transitions.
- **Beats, Director Arbitration & Interactive Scene Handoff (`H4`–`H8`):** Upgraded `combat.wound.received_beat`, `combat.fighting.injured_callout`, `combat.wound.ally_reaction`, and `combat.injury.triage_exchange` with `bite_possible_exposure`, `bite_confirmed_symptomatic`, `bite_non_transmissible`, `pelvis_groin` variants, `with_wounds_dirty_bandage`, `post_combat_injury_check`, and physiology transitions in EN and TL (`reconcile.py --check` clean). Director-style utility arbitration selects 1 responder by default (2nd only on bite conflict or critical trauma + medic, `<= 4` participants). Player triage replies hard-filter offers via `Predicates.Evaluate`, resolve deterministic node `responsePool` replies, cancel pending Beat replies, open a bounded `Scene`, and feed `Wounds.EvaluateBiteConflictPolicy` without any `recommendedAction` in dialogue modules.
