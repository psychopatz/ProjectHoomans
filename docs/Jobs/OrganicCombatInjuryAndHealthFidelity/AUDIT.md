# Organic Combat Injury & Health Fidelity — Build 42 & Codebase Audit

Baseline HEAD at H0: `4522d6e952708bf3ccb013ce620ad9d698a60cb1` (`main`).

## 1. Decompiled Build 42 Java Ground Truth

Inspected directly in `/home/psychopatz/Desktop/Projects/ZomboidDecompiler/output/source/zombie/characters/BodyDamage/`:

| Surface | Build 42 Ground Truth | ProjectHoomans Pre-H1 Gap | Resolution Phase |
| --- | --- | --- | --- |
| **17 Body Parts & Regions** | `BodyPartType` defines `Hand_L/R`, `ForeArm_L/R`, `UpperArm_L/R`, `Torso_Upper/Lower`, `Head`, `Neck`, `Groin`, `UpperLeg_L/R`, `LowerLeg_L/R`, `Foot_L/R`. | `PNC_NPCWounds_Definitions.lua` mapped `Groin = "lower_limb"`, missing distinct pelvic/arterial/groin semantics. | `H1` |
| **Wound Types & Foreign Bodies** | `BodyPart.java` tracks `scratched`, `cut` (laceration), `bitten`, `deepWound`, `haveGlass`, `stitched`, `haveBullet`, `fractureTime`/`splint`, `burnTime`, bleeding, bandaged, `bandageLife <= 0` (dirty). | Codecs (`PNC_HealthBodyCodec.lua`, `PNC_HealthCompactCodec.lua`) stripped `stitched`, `splinted`, `cauterized`, `haveGlass`, `haveBullet`, `infectedWound`, `woundInfectionLevel`, `bandageDirty`, `zombieWound` across save/load. | `H1`, `H2` |
| **Knox Transmission Modes (`ZombieLore.Transmission`)** | `BodyPart.java:685-837`: `1` (Blood+Saliva): bite 100%, cut 25%, scratch 7%; `2` (Saliva Only): bite 100%, cut/scratch 0%; `3` (Everyone's Infected): acute roll still runs + any death reanimates; `4` (None): 0%. Non-zombie wounds never infect with Knox. | `PNC_NPCWounds_Mutation.lua:136` only called `Internal.Infect` for `normalizedType == "bite"`, ignoring zombie lacerations/scratches under modes `1`/`3` and ignoring zombie vs non-zombie source. | `H2` |
| **Fake Infection (`ZombieLore.Mortality == 7`)** | `BodyDamage.java`: `Mortality == 7` sets `isFakeInfected = true` (fever rises then recovers without killing). | ProjectHoomans always drained health fatally on active Knox infection without non-lethal fever path. | `H2` |
| **Ordinary Wound Infection** | `BodyPart.java:237-343, 692, 1302-1316`: `infectedWound` + `woundInfectionLevel` (`0..10`) separate from Knox; bites immediately set `infectedWound = true`; alcohol/disinfectant lowers it; slows healing and adds pain. | `infectedWound` / `woundInfectionLevel` were not systematically evolved, disinfected, or projected separately from Knox. | `H2` |
| **Cold, Wetness, Fever, Thermoregulation** | `Thermoregulator.java:446-983`, `BodyDamage.java:716-1035`: `setPoint = 37 + SICKNESS*2`, rain wetness degrades insulation (`1 - wetness*0.75`), skin `< 33°C` accumulates cold (`ProneToIllness 1.7x`, `Resilient 0.45x`, `Outdoorsman 0.25x`), sheltered/dry recovery. | No shared `body.physiology` integration or semantic band transitions (`NPC_PHYSIOLOGY_BAND_CHANGED`) across Live & Abstract NPCs. | `H3` |

## 2. Prototype Combat Wound Worktree Audit

Pre-existing uncommitted worktree files from prior combat-wound prototype (`27 modified`, `11 untracked` paths) were audited:
- **Retain & Upgrade:** `ResponseCatalog_Core.lua` (`Catalog.MAX_VARIANTS = 32`), modular `PNC_SemanticCombatTargetCallouts_Wound{Profile,Roles,Delivery,s}.lua`, CodeBuilder `combat_wound_callouts` EN/TL sources and generated `CombatWoundCallouts.lua`, `UI_PNC_CombatInjury_*` EN/TL translations, and `tests/pnc_combat_wound_callouts_and_branching_smoke.lua`.
- **Defects Identified in Audit:**
  1. `bite_lethal` label conflated fresh bite risk with confirmed fatal certainty and assumed Knox infection at t=0.
  2. Nearest-2 responder logic in `_WoundRoles.lua` lacked Director utility scoring and wrote `"recommendedAction = hostile_eliminate_bitten"` into dialogue runtime data (`H5`, `H7`).
  3. `PNC_SemanticSpeechTransport.lua:272-329` defaulted `observerOnly = true` and omitted `responsePlanID`, `realizationID`, `poolID`, `flowID`, and `semanticEventFacts`, breaking `CombatResponseSurface` registration (`H6`).
  4. `combat_injury_interactive_exchange.json` nodes omitted `responsePool` required by `Policy_Decision.lua:21-29` (`flowResponseEligible`), and `INJURY_REPLY_OFFERS` omitted hard `constraints` (`H6`).

## 3. Existing Constraints Preserved

- `PNC_NPCWounds.lua` top-level 13-module require list must remain exact (`tests/pnc_npc_wounds_presence_boundary_smoke.lua`).
- `PNC_Compatibility_DamageContext.lua` legacy `burn -> scratch` test contract remains untouched (`tests/pnc_compatibility_damage_context_smoke.lua`).
- `psychopatzCore` and `DynamicTrading` remain untouched unless CodeBuilder whole-model fingerprint (`FoundationRegistry.lua`) requires alignment in `H8`.
## 4. H11 Live-Acceptance Reopen Audit — 2026-11-23

User runtime evidence exposed developer-side gaps after the original H10 closure:

1. **Debug wound parity failure:** `PNC_NPCWounds_Debug.ApplyDebugWound()` calls `Internal.AddWound()` + `PNC.Health.ApplyDamage()` but does not call `Internal.NotifyWoundCallout()`. The Character Health `damage_part` / `Random Body Part` debug action can therefore wound and auto-bandage an NPC without exercising immediate semantic wound reaction/interaction. Production `ApplyCombatDamage` and zombie attack paths do notify.
2. **Treatment semantic overreach:** `PNC_SemanticCombatTargetCallouts_WoundProfile.lua` collapses any bandaged selected wound into `patchState = patched_up`, while canonical `patched_up_lower_limb_severe` realizations include explicit `splint` wording. Splint must require selected-wound `splinted == true`.
3. **Cross-wound leakage risk:** cached projection `treatmentState` summarizes all wounds while `WoundProfile` chooses one selected wound for speech. Whole-body stabilization state must not authorize a treatment claim about another body part.
4. **Function claim overreach:** `ResolveFightingInjuredVariant` selects `*_lower_limb_severe` from region/severity, while wording can claim inability to run. The projection already computes `functionalImpairment`; realization must gate capability claims on that exact selected-wound/actor function state.
5. **Missing visceral pain layer:** wound delivery requests a generic secondary alert bark before the semantic wound dialogue; there is no dedicated wound-type/severity/body-part pain semantic family that reliably produces immediate `ow/fuck/I'm hit/it bit me` reactions.
6. **Witness gating gap:** responder arbitration uses a short `lastWoundReactionAt` penalty (~6s), not first meaningful observer->injured observation per world day plus injury revision/escalation.
7. **Non-colonist gap:** current `FindSquadmates()` filters via `Perception.AreWarningAllies`; stranger/non-colonist visible injury comments are not covered by the wound observer path.
8. **Interaction opportunity:** existing Beat->responsePlan->Scene infrastructure is suitable for no-bandage/offer-bandage/refuse/help branches, but must use real inventory/capability constraints and authoritative transfer/treatment actions.

The repair should preserve the successful H0–H10 health/physiology foundation and reopen only the owning layers above.
