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
## 5. Live-Acceptance Repair: Injury Reaction Ladder

A wound is both a health mutation and a semantic event. The repaired runtime uses one authoritative mutation/event path:

```text
authoritative wound mutation
  -> selected-wound truth projection + injuryRevision
  -> atomic pain Beat (injured actor)
  -> bounded witness observation arbitration
  -> optional visible-condition Beat later
  -> optional interactive injury Scene
  -> authoritative inventory/treatment/behavior action
  -> bounded high-salience memory only when warranted
```

Debug damage must inject the same normalized event as production combat/zombie damage. `debug` is provenance, not a separate silent execution path.

### Pain Beat

Immediate pain is atomic and can occur even without an audience/Scene. Semantic selection uses wound type, selected body part, physical severity, bleeding, functional impairment, panic/disposition and speech style. Realization may range from a restrained grunt to profanity or explicit wound recognition. Cooldowns are escalation-aware: repeated equal/minor hits may suppress; materially worse trauma, gunshot, bite or critical injury may preempt.

### Witness Beat

Witnessing the hit and later noticing the condition are distinct. Per observer->injured state is a compact bounded signature, not transcript history. Strong first observation resets by world-day bucket; later same-day Beats require meaningful injury/treatment/Knox/bleeding/physiology change. Candidate discovery uses existing spatial/perception indexes and Director arbitration; ordinarily one observer speaks, with rare semantically strong interjection.

### Non-colonist observation

Any eligible nearby survivor may notice observable facts (blood, open wound, limp, dirty/soaked dressing, obvious bite mark, feverish/weak state) if perception/knowledge supports it. Hidden diagnoses remain inferred/unknown unless witnessed, inspected, told or medically qualified. Faction/colonist membership changes relevance/relationship policy, not truth.

## 6. Selected-Wound Truth Firewall

Whole-body summaries and selected-wound facts are separate. Dialogue about `{slot.wound.part}` must derive treatment/function claims from that selected wound.

Forbidden unsupported examples:
- `splinted=false` -> no `splint/splinted`;
- `bandaged=false` -> no `wrapped/bandaged/dressing`;
- `stitched=false` -> no stitch claim;
- `haveGlass=false` / `haveBullet=false` -> no foreign-body claim;
- selected functional impairment not locomotor -> no `can't run/limp` claim;
- fever absent -> no fever claim;
- Knox unconfirmed/impossible -> no `turning` certainty;
- no observer knowledge -> no hidden diagnostic claim.

Quality tooling must validate these semantic claims independently from generic prose heuristics.

## 7. Semantic Microplanning, Not String Glue

Reusable composition belongs in ConvoEngine/Core when generalizable. Canonical semantics author modifiers and logical clause relations rather than locale-specific adjectives/conjunctions:

```text
CLAUSE: selected wound is bandaged
RELATION: CONTRAST
CLAUSE: speaker has limb_mobility impairment
RELATION: CONSEQUENCE
CLAUSE: request allies keep threats in front
```

EN may realize `CONTRAST` as `but/though/still`; TL owns its own valid construction. Bounded discourse focus may refer to the last unambiguous fact/referent, but ambiguity forces explicit wording. This state is transient Beat/Scene realization context only and is never durable ModData/transcript history.

## 8. Interactive Aid Contract

An observation Beat such as `You're bleeding; patch that up` may expose a Scene. Branch hard constraints query authoritative state:

- injured has/does not have bandage;
- observer has/does not have transferable bandage;
- transfer/treatment is currently valid/reachable;
- medical capability/knowledge;
- danger/combat state.

Soft utility combines directional relationship, compassion, loyalty, aggression, materialism/scarcity anxiety, medical skill and current danger. Dialogue never fabricates supplies and never performs inventory mutation itself; it invokes the existing authoritative action/transfer/treatment contract.

## 9. Robustness and Performance Are Acceptance Gates

This repair may not introduce:
- independent per-NPC/OnTick wound observers;
- full NPC/registry scans per wound;
- repeated whole-body recomputation on clean reads;
- unbounded observer history, Beat queues, Scenes or transcripts;
- runtime LLM/grammar dependency;
- client-authoritative health/item state.

Required execution shape:
- mutation increments/invalidates a compact injury revision/projection;
- self reaction is O(1) plus bounded realization;
- observer lookup is an existing bounded spatial query only when a relevant event/state transition occurs;
- observer cache is bounded and current-day/recent-state only;
- Director candidate and Scene participant caps remain bounded (`<=4` Scene actors; existing visible-offer/turn caps preserved);
- debug-off behavior has zero-ish observability overhead.
