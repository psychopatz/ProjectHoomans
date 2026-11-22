# Organic Combat Injury & Health Fidelity — Architecture

## 1. Core Architectural Contract

Project Hoomans routes combat and post-combat health interactions through a single server-authoritative pipeline rather than parallel wound, dialogue, memory, treatment, or combat controllers:

```
authoritative health event
  -> normalized multi-dimensional health/injury/physiology projection (dirty-cached)
  -> immediate short-lived Beat (wound received / injured fighting / patched fighting / escalation / treatment / physiology / post-combat check)
  -> bounded Director-style reaction arbitration (ordinarily 1 responder; rare 2nd contrasting interjection; scene cap <= 4)
  -> optional interactive Scene (player offers filtered by hard constraints -> DialogueFlowKernel -> LocalResponse -> Scene)
  -> gameplay policy/decision & treatment action (Wounds.EvaluateBiteConflictPolicy / Treatment)
  -> bounded high-salience aftermath/memory provenance
```

A **Beat** is an immediate, transient semantic bark or short witness reaction (cooldown- and budget-gated, zero persistent memory spam). A **Scene** is an explicit multi-turn interaction promoted only when player input or high-salience triage conflict warrants sustained interaction (`<= 4` participants).

## 2. Authoritative 17-Part & 5-Region Functional Model

Preserve all 17 vanilla Project Zomboid body parts (`Hand_L`, `Hand_R`, `ForeArm_L`, `ForeArm_R`, `UpperArm_L`, `UpperArm_R`, `Torso_Upper`, `Torso_Lower`, `Head`, `Neck`, `Groin`, `UpperLeg_L`, `UpperLeg_R`, `LowerLeg_L`, `LowerLeg_R`, `Foot_L`, `Foot_R`), mapped to **5 functional regions** in `PNC_NPCWounds_Definitions.lua`:

| Region | Vanilla Body Parts | Functional Semantics |
| --- | --- | --- |
| `head_neck` | `Head`, `Neck` | Airway / vision / critical trauma multiplier (`1.35`), aim penalty |
| `torso` | `Torso_Upper`, `Torso_Lower` | Breathing / core vitals multiplier (`1.25`), stamina penalty |
| `pelvis_groin` | `Groin` | Pelvic / arterial / locomotion impact multiplier (`1.25`), speed & mobility penalty (`pelvicTrauma = true`) |
| `upper_limb` | `Hand_L/R`, `ForeArm_L/R`, `UpperArm_L/R` | Weapon control / swing & aim penalty |
| `lower_limb` | `UpperLeg_L/R`, `LowerLeg_L/R`, `Foot_L/R` | Lower-limb locomotion / limp & speed penalty |

## 3. Independent Multi-Dimensional Projection (`record.runtime.healthProjection`)

Rather than collapsing trauma and infection into a single `woundType -> priority` ladder, `Wounds.GetOrBuildProjection(record)` resolves and caches independent bounded dimensions, invalidated only by `Wounds.InvalidateProjection(record, reason)` on state mutations (`O(1)` read when clean):

- **Physical severity (`physicalSeverityBand`):** `"none" | "minor" | "moderate" | "severe" | "critical"` — strictly physical trauma (bullet, fracture, deep wound/glass, burn, laceration, bite tissue damage, scratch, active bleed, part HP, overall HP). Knox transmission never distorts physical severity.
- **Bleeding severity (`bleedingBand`):** `"none" | "minor" | "moderate" | "heavy" | "critical"`.
- **Functional impairment (`functionalImpairment`):** `"none" | "vision_head" | "breathing_core" | "pelvic_mobility" | "limb_mobility" | "weapon_control" | "multi_system"`.
- **Treatment & stabilization (`treatmentState`, `patchState`):** `"uninjured" | "open_untreated" | "dirty_dressing" | "bandaged" | "stitched" | "splinted" | "cauterized" | "lodged_foreign_body" | "mixed_stabilized"` and `"uninjured" | "with_wounds" | "patched_up"`.
- **Ordinary wound infection (`ordinaryInfectionBand`):** `"none" | "mild" | "moderate" | "severe"` from `infectedWound` + `woundInfectionLevel` (`0..10`), completely separate from Knox virus.
- **Knox exposure & progression (`knoxExposure`, `knoxStage`, `knoxNonLethal`):**
  - `knoxExposure = "impossible" | "possible" | "confirmed"`
  - `"impossible"` under `Transmission == 4` (None), non-zombie wounds, or cut/scratch under `Transmission == 2` (Saliva Only).
  - `"possible"` on fresh transmissible zombie wounds before symptoms confirm.
  - `"confirmed"` once Knox stage leaves `"incubating"` (`"prodrome" | "fever" | "critical" | "recovering"`).
- **Physiology (`body.physiology`):** `thermalBand`, `wetnessBand`, `coldBand`, `feverBand`, `sicknessBand` shared identically across Live (`Wounds.Update`) and Abstract (`Needs.Update`) NPCs.

## 4. Separation of Dialogue Semantics vs Gameplay Authority

Dialogue modules (`PNC_SemanticCombatTargetCallouts_*`, `ConvoEngine`) consume normalized projections and emit `biteConflictFacts` and `semanticEventFacts` only. They must never write authoritative combat/execution commands (`recommendedAction` is prohibited in dialogue). Gameplay/behavior authority (`Wounds.EvaluateBiteConflictPolicy`) independently evaluates observer disposition, relationship, Knox exposure state, and player triage orders (`activeInjuryTriageState`) to return behavior stances (`none | protect | monitor | quarantine | abandon | threaten | execute_candidate`).
