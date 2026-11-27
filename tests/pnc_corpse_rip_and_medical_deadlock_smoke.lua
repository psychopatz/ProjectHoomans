local T = require "tests/support/test"
T.addPackagePaths({
    { "PsychopatzCore", "common" },
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "common_lua" },
})

local function assertEq(actual, expected, msg)
    if actual ~= expected then
        error(string.format("%s (expected %s, got %s)", tostring(msg), tostring(expected), tostring(actual)), 2)
    end
end

local function assertTruthy(val, msg)
    if not val then
        error(tostring(msg or "expected truthy value"), 2)
    end
end

isServer = function() return true end
isClient = function() return false end
PsychopatzCore = { RuntimeRole = { AllowsServerCode = function() return true end } }

local RipRules = require "PNC/WorldItems/PNC_WorldItemContext_RipRules"

local corpseShirt = {
    isClothing = true,
    isEquipped = function() return true end,
    getFabricType = function() return "Cotton" end,
    getDirtyness = function() return 0.5 end,
    getBloodLevel = function() return 0.4 end,
}

-- 1) Equipped clothing is protected by default (live NPC's own clothes).
assertEq(RipRules.InspectRippable(corpseShirt, "Base.Tshirt_DefaultTEXTURE_TINT", "clothing"), nil,
    "Equipped clothing must not be ripped outside corpse source")

-- 2) Worn clothing on a dead zombie corpse IS rippable into Base.RippedSheets!
local rip = RipRules.InspectRippable(corpseShirt, "Base.Tshirt_DefaultTEXTURE_TINT", "clothing", {
    sourceType = "corpse",
    allowEquipped = true,
})
assertTruthy(rip, "Corpse worn cotton shirt must be rippable")
assertEq(rip.canRip, true, "Corpse shirt canRip should be true")
assertEq(rip.outputType, "Base.RippedSheets", "Cotton shirt should rip into Base.RippedSheets")
assertEq(rip.outputCount, 2, "Cotton shirt should yield 2 ripped sheets")
assertEq(rip.requiresScissors, false, "Cotton shirt should not require scissors")

-- 3) Unified dirty-rag disposal onto nearby corpse for garbage collection.
local corpseAdded = {}
local sentToContainer = {}
local invAdded = {}
sendAddItemToContainer = function(cont, item)
    sentToContainer[#sentToContainer + 1] = { cont = cont, item = item }
end
local corpseContainer = {
    AddItem = function(_, ft)
        local obj = { fullType = ft }
        corpseAdded[#corpseAdded + 1] = obj
        return obj
    end,
}
local nearbyCorpse = {
    isDeadBody = true,
    getContainer = function() return corpseContainer end,
}
local hasCorpse = true
getCell = function()
    return {
        getGridSquare = function(_, x, y, z)
            if hasCorpse and x == 11 and y == 10 and z == 0 then
                return {
                    getStaticMovingObjects = function() return { nearbyCorpse } end,
                    getObjects = function() return {} end,
                }
            end
            return { getStaticMovingObjects = function() return {} end, getObjects = function() return {} end }
        end,
    }
end

PNC = {
    Treatment = { Internal = {} },
    Skills = {},
    Registry = {},
    Inventory = {
        AddItems = function(_, specs)
            invAdded[#invAdded + 1] = specs[1].type
            return true, "ok", { "item_1" }
        end,
    },
}
local Treatment = require "PNC/Core/Health/PNC_Treatment/PNC_Treatment_NPCActions"
local actor = { id = "npc_doc", x = 10, y = 10, z = 0 }

-- Dirty rag with nearby corpse -> goes onto corpse container (+ MP sync)
local ok1, reason1 = Treatment.DisposeRemovedDressing(actor, "Base.RippedSheetsDirty")
assertEq(ok1, true, "Dirty rag disposal should succeed")
assertEq(reason1, "disposed_on_corpse", "Dirty rag should be placed onto nearby corpse")
assertEq(#corpseAdded, 1, "Corpse container should receive 1 dirty rag")
assertEq(corpseAdded[1].fullType, "Base.RippedSheetsDirty", "Exact dirty rag type should be placed on corpse")
assertEq(#sentToContainer, 1, "MP server should replicate container addition")
assertEq(#invAdded, 0, "NPC inventory should not be cluttered with disposed dirty rag")

-- Clean reusable splint stick -> returned to NPC inventory even when corpse is nearby
local ok2, reason2 = Treatment.DisposeRemovedDressing(actor, "Base.WoodenStick2")
assertEq(ok2, true, "Clean item recovery should succeed")
assertEq(reason2, "returned_to_inventory", "Clean splint stick should return to NPC inventory")
assertEq(invAdded[1], "Base.WoodenStick2", "Clean splint stick should be added to inventory")

-- Dirty rag with no nearby corpse -> falls back cleanly to NPC inventory
hasCorpse = false
local ok3, reason3 = Treatment.DisposeRemovedDressing(actor, "Base.BandageDirty")
assertEq(ok3, true, "Fallback dirty bandage return should succeed")
assertEq(reason3, "returned_to_inventory", "With no corpse nearby, dirty bandage falls back to inventory")

-- 4. Verify player-parity clothing rip scene (Bob_IdleRipSheets + ClothesRipping)
--    and ClientActionProps WorldStaticModel fallback for clothing hand props.
local registeredScenes = {}
PNC.AnimationScenes = {
    Register = function(id, def) registeredScenes[id] = def end,
}
package.loaded["PNC/Core/Scavenge/PNC_ScavengeAnimationScenes"] = nil
require "PNC/Core/Scavenge/PNC_ScavengeAnimationScenes"
local ripScene = registeredScenes["scavenge.rip"]
assertEq(ripScene ~= nil, true, "scavenge.rip scene should register")
assertEq(ripScene.steps[2].id, "rip_cloth", "step 2 should be rip_cloth")
assertEq(ripScene.steps[2].bump, "RipSheets", "rip_cloth must play RipSheets (Bob_IdleRipSheets) for player parity")
assertEq(ripScene.steps[2].props.fallbackSecondary, "Base.BurlapPiece", "rip_cloth fallback prop should match vanilla RipClothing prop2")

local soundsPlayed = {}
ripScene.onStart({}, { playSound = function(_, s) soundsPlayed[#soundsPlayed + 1] = s end }, {}, ripScene.steps[2])
assertEq(soundsPlayed[1], "ClothesRipping", "rip_cloth step must play vanilla ClothesRipping sound")

-- ClientActionProps binds WorldStaticModel -> modData.staticModel when a clothing item has no StaticModel
local createdModData = {}
local createdClothingItem = {
    getFullType = function() return "Base.Tshirt_DefaultTEXTURE" end,
    getStaticModel = function() return nil end,
    getWorldStaticItem = function() return "TShirt_Ground" end,
    getModData = function() return createdModData end,
}
PNC.Equipment = {
    CreateItem = function() return createdClothingItem end,
}
local attachedOverride = {}
local fakeActions = {
    list = {},
    isEmpty = function(self) return #self.list == 0 end,
    get = function(self, idx) return self.list[idx + 1] end,
    removeElement = function(self, el)
        for i = #self.list, 1, -1 do
            if self.list[i] == el then table.remove(self.list, i) end
        end
    end,
}
ISBaseTimedAction = {
    derive = function(self)
        local cls = {}
        cls.__index = cls
        return cls
    end,
    new = function(cls, character)
        return setmetatable({
            character = character,
            create = function(self)
                self.action = {
                    setCustomRemoteTimedActionSync = function() end,
                    setOverrideHandModelsObject = function(_, p, s)
                        attachedOverride.primary = p
                        attachedOverride.secondary = s
                    end,
                    stopTimedActionAnim = function() end,
                }
            end,
        }, cls)
    end,
}
package.loaded["PNC/Core/Visuals/PNC_ActionProps"] = nil
package.loaded["PNC/ActionProps/PNC_ClientActionProps"] = nil
require "PNC/Core/Visuals/PNC_ActionProps"
local ClientActionProps = dofile("Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/ActionProps/PNC_ClientActionProps.lua")
PNC.Equipment = {
    CreateItem = function() return createdClothingItem end,
}
local mockNpcBody = {
    getCharacterActions = function() return fakeActions end,
    StartAction = function(_, a) fakeActions.list[1] = a end,
}
local attachOk, attachReason = ClientActionProps.Attach(mockNpcBody, {
    source = "visual_override",
    secondaryFullType = "Base.Tshirt_DefaultTEXTURE",
    hand = "secondary",
    sceneId = "scavenge.rip",
    revision = 1,
})
assertEq(attachOk, true, "ClientActionProps.Attach should succeed for clothing item: " .. tostring(attachReason))
assertEq(attachedOverride.secondary, createdClothingItem, "clothing item should attach to secondary hand")
assertEq(createdModData.staticModel, "TShirt_Ground", "clothing WorldStaticModel must bind to modData.staticModel so PZ renders it in hand")

print("PASS: pnc_corpse_rip_and_medical_deadlock_smoke")
