local ROOT = "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/"
local SHARED_ROOT = "Contents/mods/ProjectHoomans/42.20/media/lua/shared/"
local CORE_SHARED_ROOT =
    "../psychopatzCore/Contents/mods/PsychopatzCore/42.19/media/lua/shared/"

package.path = CORE_SHARED_ROOT .. "?.lua;" .. SHARED_ROOT .. "?.lua;" .. package.path

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected) .. " actual=" .. tostring(actual))
    end
end

local function makeList(values)
    return {
        size = function() return #values end,
        get = function(_, index) return values[index + 1] end,
    }
end

local inventoryValues = {}
local container = {}
function container:getItems()
    return makeList(inventoryValues)
end
function container:AddItem(item)
    local i
    for i = 1, #inventoryValues do
        if inventoryValues[i] == item then
            item.container = self
            return item
        end
    end
    inventoryValues[#inventoryValues + 1] = item
    item.container = self
    return item
end

local function makeWornItems()
    local entries = {}
    local worn = {}
    function worn:size() return #entries end
    function worn:get(index) return entries[index + 1] end
    function worn:clear() entries = {} end
    function worn:setItem(location, item)
        local i
        assert(type(location) ~= "string", "Build 42 requires typed ItemBodyLocation")
        assertEqual(item:getContainer(), container, "worn item container ordering")
        for i = #entries, 1, -1 do
            if entries[i]:getLocation() == location then
                table.remove(entries, i)
            end
        end
        entries[#entries + 1] = {
            getLocation = function() return location end,
            getItem = function() return item end,
        }
    end
    function worn:addItemsToItemContainer(target)
        error("worn items were redundantly re-added to their existing container")
    end
    function worn:getItem(location)
        local i
        for i = 1, #entries do
            if entries[i]:getLocation() == location then
                return entries[i]:getItem()
            end
        end
        return nil
    end
    return worn
end

local visualCopies = 0
local shirtBodyLocation = setmetatable({}, {
    __tostring = function() return "Shirt" end,
})
local itemVisual = {
    copyFrom = function(_, source)
        assert(source, "missing source clothing visual")
        visualCopies = visualCopies + 1
    end,
}
local shirt = {
    getFullType = function() return "Base.Shirt_FormalWhite" end,
    getBodyLocation = function() return shirtBodyLocation end,
    getContainer = function(self) return self.container end,
    getVisual = function() return itemVisual end,
}
local cardModData = {}
local identityCardCreateCount = 0
local identityCard = {
    getFullType = function() return "Base.IDcard" end,
    getContainer = function(self) return self.container end,
    setName = function(self, value) self.customName = value end,
    getModData = function() return cardModData end,
}
local liveVisual = {
    getItemType = function() return "Base.Shirt_FormalWhite" end,
}
local sourceWorn = makeWornItems()
local corpseWorn = makeWornItems()
local transmitCount = 0
local engineDeathCount = 0
local directCorpseCount = 0
local corpseModData = {}
local corpse = {
    getContainer = function() return container end,
    getWornItems = function() return corpseWorn end,
    getModData = function() return corpseModData end,
    getX = function() return 10 end,
    getY = function() return 20 end,
    getZ = function() return 0 end,
    setFakeDead = function() end,
    setReanimateTime = function() end,
    transmitCompleteItemToClients = function()
        assertEqual(corpseWorn:getItem(shirtBodyLocation), shirt, "transmitted corpse worn shirt")
        assertEqual(corpseModData.PNC_DeathMarkerID, "npc_corpse_clothes",
            "transmitted death marker identity")
        transmitCount = transmitCount + 1
    end,
}
local zombie = {
    getInventory = function() return container end,
    getWornItems = function() return sourceWorn end,
    getItemVisuals = function() return makeList({ liveVisual }) end,
    getPrimaryHandItem = function() return nil end,
    getSecondaryHandItem = function() return nil end,
    setWornItem = function(_, location, item)
        if tostring(location or "") == "Shirt" then location = shirtBodyLocation end
        sourceWorn:setItem(location, item)
    end,
    getX = function() return 10 end,
    getY = function() return 20 end,
    getZ = function() return 0 end,
    setReanimate = function() end,
    setReanim = function() end,
    setUseless = function() end,
    becomeCorpseSilently = function()
        engineDeathCount = engineDeathCount + 1
        -- Reproduce an engine conversion that occasionally omits a source-body
        -- item. Finalization must restore the card on the returned corpse.
        local i
        for i = #inventoryValues, 1, -1 do
            if inventoryValues[i] == identityCard then
                table.remove(inventoryValues, i)
            end
        end
        identityCard.container = nil
        return corpse
    end,
}
local record = {
    id = "npc_corpse_clothes",
    name = "Corpse Clothes",
    x = 10,
    y = 20,
    z = 0,
    alive = false,
    presenceState = "corpse",
    presenceRevision = 0,
    runtime = { bodyLease = "lease" },
    equipment = { worn = {}, attached = {} },
}

PNC = {
    Core = {
        Now = function() return 1000 end,
        GenerateID = function(prefix) return prefix .. "_test" end,
    },
    Const = {
        PRESENCE_CORPSE = "corpse",
        PRESENCE_ABSTRACT = "abstract",
        BODY_TAG_VERSION = 1,
    },
    Equipment = {
        CreateItem = function(fullType)
            if fullType == "Base.Shirt_FormalWhite" then return shirt end
            if fullType == "Base.IDcard" then
                identityCardCreateCount = identityCardCreateCount + 1
                return identityCard
            end
            error("unexpected corpse item type " .. tostring(fullType))
        end,
    },
    VisualProfiles = {
        RollAppearance = function()
            return { outfitItems = { "Base.Shirt_FormalWhite" } }
        end,
    },
    Inventory = {
        EnsureRecordInventory = function()
            return {
                items = {
                    identity = {
                        type = "Base.IDcard",
                        customName = "ID Card: Corpse Clothes",
                        identityNPCId = record.id,
                        identityNPCName = "Corpse Clothes",
                    },
                },
            }
        end,
    },
    Visuals = { RefreshModel = function() end },
    Registry = {
        LiveByID = { [record.id] = zombie },
        GetDeathMarker = function(id)
            return tostring(id) == record.id and record or nil
        end,
        MarkDirty = function() end,
    },
}

IsoDeadBody = {
    new = function()
        directCorpseCount = directCorpseCount + 1
        return corpse
    end,
}
isServer = function() return true end
getGameTime = function()
    return { getWorldAgeHours = function() return 5 end }
end

dofile(ROOT .. "Presence/PNC_BodyLifecycle.lua")

local created, result = PNC.BodyLifecycle.CreateInertCorpse(record, zombie, "test_death")
assertEqual(created, true, "corpse creation")
assertEqual(result, corpse, "created corpse instance")
assertEqual(engineDeathCount, 1, "engine-networked death conversion count")
assertEqual(directCorpseCount, 0, "direct corpse fallback bypassed engine death")
assertEqual(#inventoryValues, 2, "corpse inventory count")
assertEqual(identityCard.customName, "ID Card: Corpse Clothes", "physical ID card name")
assertEqual(cardModData.PNC_IDCard, true, "physical ID card marker")
assertEqual(cardModData.PNC_IDCardNPCId, record.id, "physical ID card NPC UUID")
assertEqual(identityCardCreateCount, 2, "lost ID card recreated after corpse conversion")
assertEqual(sourceWorn:getItem(shirtBodyLocation), shirt, "source worn shirt")
assertEqual(corpseWorn:getItem(shirtBodyLocation), shirt, "corpse worn shirt")
assertEqual(visualCopies, 1, "live clothing visual copy count")
assertEqual(transmitCount, 1, "multiplayer corpse transmission count")
assertEqual(corpseModData.PNC_NPC, nil, "corpse released from NPC ownership")
assertEqual(corpseModData.PNC_UUID, nil, "corpse released from NPC UUID")
assertEqual(corpseModData.PNC_DeathMarkerID, record.id, "corpse death marker id")
assertEqual(record.runtime.lifecycle.corpseState, "inert_loaded", "corpse lifecycle state")

-- Delayed becomeCorpseSilently finalization must apply the same guarantee using
-- only the compact death marker after the full live record is retired.
for index = #inventoryValues, 1, -1 do
    if inventoryValues[index] == identityCard then
        table.remove(inventoryValues, index)
    end
end
identityCard.container = nil
local corpseSquare = {
    getDeadBodys = function() return makeList({ corpse }) end,
    getStaticMovingObjects = function() return makeList({}) end,
}
getCell = function()
    return {
        getGridSquare = function() return corpseSquare end,
    }
end
PNC.BodyLifecycle.PendingCorpses = {
    {
        npcId = record.id,
        x = 10,
        y = 20,
        z = 0,
        token = corpseModData.PNC_CorpseToken,
        attempts = 0,
        wornEntries = PNC.BodyLifecycle.Internal.captureWornEntries(sourceWorn),
    },
}
PNC.BodyLifecycle.Internal.pumpPendingCorpses()
assertEqual(#PNC.BodyLifecycle.PendingCorpses, 0, "delayed corpse finalized")
assertEqual(#inventoryValues, 2, "delayed corpse restored identity card")
assertEqual(identityCardCreateCount, 3, "delayed corpse recreated identity card")
assertEqual(transmitCount, 2, "delayed corpse single completed-state transmission")

print("pnc_corpse_clothing_smoke: ok")
