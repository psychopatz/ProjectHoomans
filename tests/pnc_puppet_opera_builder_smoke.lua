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
T.falsy(Model.GetSelectedActorID(),
    "builder should open without an implicitly selected actor")
T.equal(draft.actors.actor_1.kind, "local_player",
    "default player/NPC scene should use an explicit player actor slot")
T.equal(draft.actors.actor_2.kind, "nearby_live_npc",
    "default player/NPC scene should use an explicit NPC actor slot")

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

Model.SetNPCState("bumped")
Model.SetNPCQuery("PNC_WaveHi")
local npcEntry
for _, entry in ipairs(Model.GetNPCCatalogEntries()) do
    if entry.node == "PNC_Anim_WaveHi" and entry.puppetOperaDirect == true then
        npcEntry = entry
        break
    end
end
T.truthy(npcEntry, "NPC catalog did not expose direct PNC_WaveHi")

local liveNPCs = {
    {
        id = "npc-one",
        name = "NPC One",
        distSq = 1,
        zombie = {},
        record = {},
    },
    {
        id = "npc-two",
        name = "NPC Two",
        distSq = 4,
        zombie = {},
        record = {},
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
local boundPlayer, boundPlayerReason = Model.BindLiveActor(
    "actor_1", "__local_player__")
T.truthy(boundPlayer, "builder could not bind the local player slot: "
    .. tostring(boundPlayerReason))
local bound, bindReason = Model.BindLiveActor("actor_2", "npc-one")
T.truthy(bound, "builder could not explicitly bind the first NPC: "
    .. tostring(bindReason))
T.truthy(Model.AssignAnimation("actor_1", playerEntry),
    "builder could not assign the native player action")
T.truthy(Model.AssignAnimation("actor_2", npcEntry),
    "builder could not assign the NPC bump route")

local moved, moveReason = Model.SetActorAnchorOffset("actor_2", 2, 0, 0)
T.truthy(moved, "builder could not move an anchor: " .. tostring(moveReason))
T.equal(draft.anchorFrame.anchors.right.right, 2,
    "anchor edit did not update the draft")

local schemaOK, runtimeReason, normalized = Model.GetValidation()
T.truthy(schemaOK, "builder draft failed schema validation: " .. tostring(runtimeReason))
T.falsy(runtimeReason, "default builder choices lost runtime approval")
T.equal(normalized.beats[1].tracks.actor_1.action,
    "RemoveBush", "normalized player route changed")
T.equal(normalized.beats[1].tracks.actor_2.bump,
    "PNC_WaveHi", "normalized NPC route changed")
local sceneRows = Model.GetActorRows()
local boundSceneRow
for _, row in ipairs(sceneRows) do
    if row.id == "actor_2" then boundSceneRow = row break end
end
T.truthy(boundSceneRow and boundSceneRow.liveID == "npc-one",
    "scene actor row did not expose its bound live actor ID")
T.equal(boundSceneRow.liveName, "NPC One",
    "scene actor row did not expose its bound live actor name")
local animationTargets = Model.GetAnimationTargetRows("npc")
local sceneTarget
local previewTarget
for _, target in ipairs(animationTargets) do
    if target.key == "scene:actor_2" then sceneTarget = target end
    if target.key == "live:npc-two" then previewTarget = target end
end
T.truthy(sceneTarget and string.find(sceneTarget.label, "NPC One", 1, true),
    "NPC animation target did not name the bound scene actor")
T.truthy(previewTarget and previewTarget.previewOnly == true,
    "unbound live NPC was not exposed as a preview-only target")
T.truthy(Model.SetAnimationTarget("npc", "live:npc-two"),
    "builder could not select the explicit second NPC preview target")
T.falsy(Model.GetActorForCatalog("npc"),
    "preview-only NPC target was incorrectly treated as assignable")
T.equal(Model.GetPreviewTarget("npc").liveID, "npc-two",
    "NPC preview target resolved to the wrong live actor")
T.truthy(Model.SetAnimationTarget("npc", "scene:actor_2"),
    "builder could not restore the named scene target")
T.equal(Model.GetActorForCatalog("npc"), "actor_2",
    "named scene target was not restored as the assignment target")
Model.SelectActor("actor_1")
T.equal(Model.GetAnimationTarget("player").key, "scene:actor_1",
    "grid actor selection did not target the matching player scene slot")
Model.SelectLiveActor("npc-two")
T.falsy(Model.GetSelectedActorID(),
    "free live actor selection retained an implicit scene slot")
T.equal(Model.GetAnimationTarget("npc").key, "live:npc-two",
    "free live actor selection did not target its preview row")
local liveRows = Model.GetLiveActorRows(8)
T.equal(#liveRows, 3, "live actor list did not include player and both NPCs")
T.equal(liveRows[1].id, "__local_player__",
    "local player was not exposed as a draggable live actor")
local containerAdded, containerID = Model.AddActorContainer()
T.truthy(containerAdded, "builder could not add an empty actor container")
local added, addedID = Model.AddLiveActorToScene(
    "npc-two", 3, 0, 0, containerID)
T.truthy(added, "builder could not drop a second live NPC on the grid")
T.equal(Model.GetActorKind(addedID), "nearby_live_npc",
    "dropped live actor did not create an NPC slot")
T.truthy(Model.AssignAnimation(addedID, npcEntry),
    "builder could not assign an explicit track to the added NPC slot")
local bindings, bindingReason = Model.GetRuntimeActorBindings()
T.truthy(bindings, "multi-NPC bindings were not collected: " .. tostring(bindingReason))
T.equal(bindings.actor_1, "__local_player__", "player binding changed")
T.equal(bindings.actor_2, "npc-one", "original NPC binding changed")
T.equal(bindings[addedID], "npc-two", "second NPC binding was not retained")
Model.SetSelectedNPC("npc-two")
local preservedBindings = Model.GetRuntimeActorBindings()
T.equal(preservedBindings.actor_2, "npc-one",
    "NPC selector refresh overwrote the original scene binding")
T.equal(preservedBindings[addedID], "npc-two",
    "NPC selector refresh lost the second scene binding")

local removedPlayer, removeReason = Model.RemoveActor("actor_1")
T.truthy(removedPlayer, "builder could not convert the draft to two NPCs: "
    .. tostring(removeReason))
T.falsy(Model.GetActorKind("actor_1"), "player slot was not removable")
local npcOnlySchema, npcOnlyRuntime, npcOnlyDefinition = Model.GetValidation()
T.truthy(npcOnlySchema, "two-NPC draft failed schema validation: "
    .. tostring(npcOnlyRuntime))
T.falsy(npcOnlyRuntime, "two-NPC draft was incorrectly runtime-rejected")
T.equal(npcOnlyDefinition.actors[addedID].kind, "nearby_live_npc",
    "bound dynamic slot did not retain its resolved NPC kind")

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

local newAccepted, newDraft = Model.CreateNew()
T.truthy(newAccepted and newDraft, "builder could not create a new scene")
local firstAdded, firstID = Model.AddActorContainer()
local secondAdded, secondID = Model.AddActorContainer()
T.truthy(firstAdded and secondAdded,
    "new scene could not add its first two actor containers")
local newAnchors = newDraft.anchorFrame.anchors
T.equal(newAnchors[newDraft.actors[firstID].anchor].faceTarget, secondID,
    "first new actor anchor did not face the second actor")
T.equal(newAnchors[newDraft.actors[secondID].anchor].faceTarget, firstID,
    "second new actor anchor did not face the first actor")

return T.finish("pnc_puppet_opera_builder_smoke")
