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
local draft = Model.GetDraft()
T.truthy(draft, "builder did not load the default draft")

Model.SetPlayerSource("player")
Model.SetPlayerQuery("RemoveBush")
local playerEntry
for _, entry in ipairs(Model.GetPlayerCatalogEntries()) do
    if entry.action == "RemoveBush" then
        playerEntry = entry
        break
    end
end
T.truthy(playerEntry, "player catalog did not expose RemoveBush")
T.truthy(Model.AssignAnimation("player", playerEntry),
    "builder could not assign the native player action")

Model.SetNPCState("bumped")
Model.SetNPCQuery("PNC_Shove")
local npcEntry
for _, entry in ipairs(Model.GetNPCCatalogEntries()) do
    if entry.node == "PNC_Shove" and entry.puppetOperaDirect == true then
        npcEntry = entry
        break
    end
end
T.truthy(npcEntry, "NPC catalog did not expose direct PNC_Shove")
T.truthy(Model.AssignAnimation("npc", npcEntry),
    "builder could not assign the NPC bump route")

local moved, moveReason = Model.SetActorAnchorOffset("npc", 2, 0, 0)
T.truthy(moved, "builder could not move an anchor: " .. tostring(moveReason))
T.equal(draft.anchorFrame.anchors.right.right, 2,
    "anchor edit did not update the draft")

local schemaOK, runtimeReason, normalized = Model.GetValidation()
T.truthy(schemaOK, "builder draft failed schema validation: " .. tostring(runtimeReason))
T.falsy(runtimeReason, "default builder choices lost runtime approval")
T.equal(normalized.beats[1].player.action, "RemoveBush",
    "normalized player route changed")
T.equal(normalized.beats[1].npc.bump, "PNC_Shove",
    "normalized NPC route changed")

local liveNPCs = {
    {
        id = "npc-one",
        name = "NPC One",
        distSq = 1,
    },
    {
        id = "npc-two",
        name = "NPC Two",
        distSq = 4,
    },
}
PNC.PuppetOpera.Client.GetNearbyNPCs = function() return liveNPCs end
PNC.PuppetOpera.Client.GetLocalPlayer = function()
    return {
        getX = function() return 10 end,
        getY = function() return 10 end,
        getUsername = function() return "Builder" end,
    }
end
Model.SetSelectedNPC("npc-one")
local liveRows = Model.GetLiveActorRows(8)
T.equal(#liveRows, 3, "live actor list did not include player and both NPCs")
T.equal(liveRows[1].id, "__local_player__",
    "local player was not exposed as a draggable live actor")
local added, addedID = Model.AddLiveActorToScene("npc-two", 3, 0, 0)
T.truthy(added, "builder could not drop a second live NPC on the grid")
T.equal(Model.GetActorKind(addedID), "nearby_live_npc",
    "dropped live actor did not create an NPC slot")
local bindings, bindingReason = Model.GetRuntimeActorBindings()
T.truthy(bindings, "multi-NPC bindings were not collected: " .. tostring(bindingReason))
T.equal(bindings.npc, "npc-one", "original NPC binding changed")
T.equal(bindings[addedID], "npc-two", "second NPC binding was not retained")
Model.SetSelectedNPC("npc-two")
local preservedBindings = Model.GetRuntimeActorBindings()
T.equal(preservedBindings.npc, "npc-one",
    "NPC selector refresh overwrote the original scene binding")
T.equal(preservedBindings[addedID], "npc-two",
    "NPC selector refresh lost the second scene binding")

local removedPlayer, removeReason = Model.RemoveActor("player")
T.truthy(removedPlayer, "builder could not convert the draft to two NPCs: "
    .. tostring(removeReason))
T.falsy(Model.GetActorKind("player"), "player slot was not removable")
local npcOnlySchema, npcOnlyRuntime, npcOnlyDefinition = Model.GetValidation()
T.truthy(npcOnlySchema, "two-NPC draft failed schema validation: "
    .. tostring(npcOnlyRuntime))
T.falsy(npcOnlyRuntime, "two-NPC draft was incorrectly runtime-rejected")
T.equal(npcOnlyDefinition.actors[addedID].kind, "nearby_live_npc",
    "two-NPC definition lost the added actor")

local oldID = Model.GetBlueprintID()
local duplicated, duplicate = Model.DuplicateBlueprint()
T.truthy(duplicated, "builder could not duplicate a blueprint")
T.truthy(duplicate and duplicate.id ~= oldID,
    "duplicate did not receive a new blueprint identity")
local duplicateID = Model.GetBlueprintID()
T.truthy(Model.SaveDraft(), "builder could not save duplicated draft")
T.truthy(Model.ResetDraft(), "builder could not reset duplicated draft")
T.equal(Model.GetDraft().id, duplicateID,
    "reset returned to the original blueprint baseline")

return T.finish("pnc_puppet_opera_builder_smoke")
