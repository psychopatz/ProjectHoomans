# Organic Combat Injury & Health Fidelity — Progress

**Primary Repository:** `/home/psychopatz/Zomboid/Workshop/ProjectHoomans` (`main`)
**Baseline Commit:** `4522d6e952708bf3ccb013ce620ad9d698a60cb1`
**Active Phase:** `H2` — Vanilla-Faithful Knox Transmission (`1`–`4`), Mortality (`1`–`7`) & Ordinary Wound Infection

## Phase Status

| Phase | Title | Status | Commit |
| --- | --- | --- | --- |
| `H0` | Baseline Audit & Durable Job Docs | `DONE` | `2b096f92e09e2cac6b292e4ba3575dc3213d900a` |
| `H1` | Multi-Dimensional Health Model & Cached Projection | `DONE` | Pending `H1` phase commit |
| `H2` | Build 42 Knox Transmission, Mortality & Ordinary Wound Infection | `NEXT` | Pending |
| `H3` | Lightweight Cold, Sickness, Fever & Thermoregulation Parity | `PENDING` | Pending |
| `H4` | Combat, Escalation, Treatment, Physiology & Post-Combat Beats | `PENDING` | Pending |
| `H5` | Director-Style Ally Reaction Arbitration | `PENDING` | Pending |
| `H6` | Beat -> Player Response -> Multi-Actor Scene Handoff | `PENDING` | Pending |
| `H7` | Bite Conflict Facts/Behavior Policy & Bounded Memory | `PENDING` | Pending |
| `H8` | EN/TL Realizations & CodeBuilder Reconciliation | `PENDING` | Pending |
| `H9` | Deterministic Tests, MP Authority & 200-NPC Scale Suite | `PENDING` | Pending |
| `H10` | Final Audit & Developer-Side Closure | `PENDING` | Pending |
| `H11` | User Live SP/MP Acceptance | `USER_OWNED` | Pending user runtime test |

## Completed in H1

- Separated physical trauma severity (`physicalSeverityRank`) from Knox transmission risk (`canTransmitKnoxFromZombie`) across all Build 42 wound tiers, mapping `Groin -> pelvis_groin` with explicit `BodyRegionFunctions`, `pelvicTrauma` mobility failure, and `Wounds.GetFunctionalImpairment`.
- Implemented dirty-state cached health/injury/physiology projection (`Wounds.GetOrBuildProjection`, `Wounds.InvalidateProjection`) exposing independent bounded dimensions (`physicalSeverityBand`, `bleedingBand`, `functionalImpairment`, `treatmentState`, `patchState`, `ordinaryInfectionBand`, `knoxExposure`, `knoxStage`, `knoxNonLethal`, `physiology`).
- Upgraded `PNC_HealthBodyCodec.lua` and `PNC_HealthCompactCodec.lua` via shared `PNC_HealthWoundCodec.lua` so all Build 42 wound flags (`stitched`, `splinted`, `cauterized`, `haveGlass`, `haveBullet`, `infectedWound`, `woundInfectionLevel`, `bandageDirty`, `zombieWound`, `body.physiology`) survive save/load without bloating default payloads.
- Verified `0 / 10` files over 2000 `o200k_base` tokens, `0` Kahlua issues across 52 Health files, and `15/15` relevant Lua smoke tests passing.
