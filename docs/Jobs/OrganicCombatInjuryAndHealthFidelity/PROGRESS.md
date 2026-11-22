# Organic Combat Injury & Health Fidelity — Progress

**Primary Repository:** `/home/psychopatz/Zomboid/Workshop/ProjectHoomans` (`main`)
**Baseline Commit:** `4522d6e952708bf3ccb013ce620ad9d698a60cb1`
**Active Phase:** `H3` — Lightweight Cold, Sickness, Fever & Thermoregulation Parity (Live + Abstract)

## Phase Status

| Phase | Title | Status | Commit |
| --- | --- | --- | --- |
| `H0` | Baseline Audit & Durable Job Docs | `DONE` | `2b096f92e09e2cac6b292e4ba3575dc3213d900a` |
| `H1` | Multi-Dimensional Health Model & Cached Projection | `DONE` | `3b659bd5c970cc139304c326a8445599ac0af36d` |
| `H2` | Build 42 Knox Transmission, Mortality & Ordinary Wound Infection | `DONE` | Pending `H2` phase commit |
| `H3` | Lightweight Cold, Sickness, Fever & Thermoregulation Parity | `NEXT` | Pending |
| `H4` | Combat, Escalation, Treatment, Physiology & Post-Combat Beats | `PENDING` | Pending |
| `H5` | Director-Style Ally Reaction Arbitration | `PENDING` | Pending |
| `H6` | Beat -> Player Response -> Multi-Actor Scene Handoff | `PENDING` | Pending |
| `H7` | Bite Conflict Facts/Behavior Policy & Bounded Memory | `PENDING` | Pending |
| `H8` | EN/TL Realizations & CodeBuilder Reconciliation | `PENDING` | Pending |
| `H9` | Deterministic Tests, MP Authority & 200-NPC Scale Suite | `PENDING` | Pending |
| `H10` | Final Audit & Developer-Side Closure | `PENDING` | Pending |
| `H11` | User Live SP/MP Acceptance | `USER_OWNED` | Pending user runtime test |

## Completed in H2

- Implemented Build 42 `ZombieLore.Transmission` (`1` Blood+Saliva: bite 100%, laceration 25%, scratch 7%; `2` Saliva Only: bite 100%, cut/scratch 0%; `3` Everyone's Infected; `4` None) and `ZombieLore.Mortality == 7` non-lethal fake fever recovery in `PNC_Sandbox_Health.lua`, `PNC_NPCWounds_Infection_Lifecycle.lua`, and `PNC_NPCWounds_Infection_Progression.lua`.
- Tagged zombie vs non-zombie wound sources (`wound.zombieWound`) in `PNC_NPCWounds_Mutation.lua` and `PNC_NPCWounds_ZombieAttack_Common.lua` so human/environment wounds never trigger Knox virus while transmissible zombie wounds mark `knoxExposure = "possible"`.
- Added Build 42 ordinary wound infection (`infectedWound`, `woundInfectionLevel` `0..10`) evolution and healing penalties in `PNC_NPCWounds_OrdinaryInfection.lua` / `PNC_NPCWounds_Update.lua`, plus `Disinfect`, `Cauterize`, `RemoveGlass`, and `RemoveBullet` in `PNC_NPCWounds_Treatment_Surgical.lua`.
- Verified `0 / 12` files over 2000 `o200k_base` tokens, `24/24` Lua smoke tests passing, and H2 transmission/Mortality-7 runtime probe `H2_PROBE_OK`.
