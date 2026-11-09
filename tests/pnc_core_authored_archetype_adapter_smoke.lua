local T = require "tests/support/test"

T.addPackagePaths()

local Actors = require "PsychopatzCore/Actors/PsychopatzActors"
PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Actors = Actors

PNC = {}
T.load("ProjectHoomans", "shared", "PNC/Core/Base/PNC_Core.lua")
T.load("ProjectHoomans", "shared",
    "PNC/Core/Archetypes/Registry/PNC_Archetypes.lua")
T.load("ProjectHoomans", "shared",
    "PNC/Core/Archetypes/Registry/PNC_ArchetypeLoader.lua")

for _, id in ipairs({ "General", "Farmer", "Mechanic", "Doctor", "Foreman", "Scavenger" }) do
    T.truthy(Actors.Archetypes:Get(id),
        "default authored archetype bridged: " .. id)
end

local definition = Actors.Archetypes:Get("Doctor")
T.truthy(definition, "Core adapter registration")
T.equal(definition.id, "projecthoomans.doctor",
    "Core canonical Hoomans archetype ID")
local bandage
for _, item in ipairs(definition.inventory.items) do
    if item.fullType == "Base.Bandage" then bandage = item end
end
T.truthy(bandage, "Core item contract full type")
T.equal(bandage.quantity, 4, "Core item contract quantity")
T.equal(definition.extensions["projecthoomans.archetype"].allowedJobs.MedicalCare,
    true, "Hoomans extension preserved")

local plan, planReason = Actors.Archetypes:ResolvePlan("Doctor", {
    seed = "doctor-core-plan",
})
T.truthy(plan, planReason)
T.equal(plan.archetypeID, "projecthoomans.doctor",
    "Core plan uses the canonical Hoomans ID")
T.truthy(plan.bagType, "Core plan selects the authored bag choices")
T.equal(plan.appearanceItems[1].type, plan.appearanceItems[1].fullType,
    "Core plan exposes canonical appearance item specs")
T.equal(plan.inventory.items[2].fullType, "Base.Bandage",
    "Core plan exposes canonical supply items")

local actorRegistry = Actors.NewRegistry()
local actor, actorReason = actorRegistry:Create({
    actorId = "pnc:doctor:portrait",
    archetypeID = "Doctor",
    identitySeed = "doctor-portrait",
})
T.truthy(actor, actorReason)
local portrait, portraitReason = Actors.Presentation.BuildPortrait(actor)
T.truthy(portrait, portraitReason)
T.equal(portrait.actorID, actor.actorId,
    "Hoomans authored actor uses the Core portrait contract")
T.equal(
    portrait.appearance.outfitItemSpecs[1].type,
    actor.appearance.resolved.outfitItemSpecs[1].type,
    "Hoomans portrait uses the same authored clothing projection"
)

T.finish("pnc_core_authored_archetype_adapter_smoke")
