local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "client" },
})

PNC = {
    Core = {
        Now = function() return 1000 end,
    },
    PuppetOpera = {
        Client = {
            GetNearbyNPCs = function() return {} end,
            GetSnapshot = function() return nil end,
            GetTrace = function() return {} end,
            GetStatus = function() return "idle", nil end,
        },
    },
}

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/PuppetOpera/PNC_PuppetOpera_Blueprints.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/PuppetOpera/PNC_PuppetOpera_Anchors.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/PuppetOpera/PNC_PuppetOpera_Trace.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/PuppetOpera/PNC_PuppetOpera.lua"
)
T.load(
    "ProjectHoomans",
    "client",
    "PNC/UI/PuppetOpera/PNC_PuppetOperaDebugModel.lua"
)

local Model = PNC.PuppetOperaDebugModel
T.truthy(Model.GetBlueprints and Model.SetBlueprintID
    and Model.CreateNew and Model.DuplicateBlueprint,
    "draft catalog and creation spokes were not attached")
T.truthy(Model.SaveDraft and Model.ResetDraft and Model.GetValidation,
    "draft persistence and validation spokes were not attached")
T.truthy(Model.ClearActorBindings,
    "draft catalog spoke did not preserve binding cleanup")

local initialID = Model.GetBlueprintID()
local initialSerial = Model.GetChangeSerial()
local accepted, reason = Model.SetBlueprintID("")
T.falsy(accepted, "empty blueprint selection was accepted")
T.equal(reason, "blueprint_not_found",
    "empty blueprint selection returned an unstable reason")
T.equal(Model.GetChangeSerial(), initialSerial,
    "rejected selection changed editor state")

local created, draft = Model.CreateNew()
T.truthy(created and draft, "new draft construction failed")
local newID = Model.GetBlueprintID()
T.equal(newID, draft.id, "new draft was not selected")
T.truthy(Model.IsDirty(newID), "new draft was not marked dirty")

local schemaOK, schemaReason = Model.GetValidation()
T.falsy(schemaOK, "empty new draft passed schema validation")
T.equal(schemaReason, "at_least_two_actors_required",
    "empty new draft returned the wrong schema reason")

Model.State.actorBindings[newID] = { actor_1 = "npc-one" }
Model.State.selectedActorID = "actor_1"
Model.State.selectedNPCID = "npc-one"
Model.State.pendingLiveActorID = "npc-one"
Model.State.animationTargets = { npc = "live:npc-one" }
Model.ClearActorBindings()
local hasBinding = false
for _ in pairs(Model.State.actorBindings[newID]) do hasBinding = true end
T.falsy(hasBinding, "binding cleanup retained stale actor bindings")
T.falsy(Model.State.selectedActorID,
    "binding cleanup retained a stale actor selection")
T.falsy(Model.State.selectedNPCID,
    "binding cleanup retained a stale NPC selection")
T.falsy(Model.State.pendingLiveActorID,
    "binding cleanup retained a pending live actor")

local duplicateAccepted, duplicate = Model.DuplicateBlueprint()
T.truthy(duplicateAccepted and duplicate, "draft duplication failed")
T.equal(Model.GetBlueprintID(), newID .. "_copy",
    "duplicate did not use the stable copy suffix")

T.truthy(Model.SetBlueprintID(newID),
    "created draft could not be reselected")
local collisionAccepted, collision = Model.DuplicateBlueprint()
T.truthy(collisionAccepted and collision, "duplicate collision handling failed")
T.equal(Model.GetBlueprintID(), newID .. "_copy2",
    "duplicate collision did not advance its bounded suffix")

local saved, saveReason = Model.SaveDraft()
T.falsy(saved, "invalid duplicate was saved")
T.equal(saveReason, "at_least_two_actors_required",
    "invalid save returned the wrong schema reason")
T.equal(Model.State.editorError, "at_least_two_actors_required",
    "invalid save did not expose its editor error")

T.truthy(Model.SetBlueprintID(initialID),
    "original blueprint could not be restored")
local original = Model.GetDraft()
T.truthy(original, "original blueprint draft was not available")
original.description = "saved description"
Model.Internal.markChanged()
local savedOriginal, savedDraft = Model.SaveDraft()
T.truthy(savedOriginal and savedDraft, "valid draft save failed")
T.falsy(Model.IsDirty(initialID), "saved draft remained dirty")
original.description = "unsaved description"
Model.Internal.markChanged()
T.truthy(Model.ResetDraft(), "saved draft reset failed")
T.equal(Model.GetDraft().description, "saved description",
    "reset did not restore the saved draft baseline")

return T.finish("pnc_puppet_opera_drafts_modules_smoke")
