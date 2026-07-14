local ROOT = "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/"

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
        local i
        for i = 1, #entries do
            target:AddItem(entries[i]:getItem())
        end
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
local itemVisual = {
    copyFrom = function(_, source)
        assert(source, "missing source clothing visual")
        visualCopies = visualCopies + 1
    end,
}
local shirt = {
    getFullType = function() return "Base.Shirt_FormalWhite" end,
    getBodyLocation = function() return "Shirt" end,
    getContainer = function(self) return self.container end,
    getVisual = function() return itemVisual end,
}
local liveVisual = {
    getItemType = function() return "Base.Shirt_FormalWhite" end,
}
local sourceWorn = makeWornItems()
local corpseWorn = makeWornItems()
local transmitCount = 0
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
        assertEqual(corpseWorn:getItem("Shirt"), shirt, "transmitted corpse worn shirt")
        assertEqual(corpseModData.PNC_BodyKind, "corpse", "transmitted corpse body kind")
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
        sourceWorn:setItem(location, item)
    end,
    getX = function() return 10 end,
    getY = function() return 20 end,
    getZ = function() return 0 end,
    setReanimate = function() end,
    setReanim = function() end,
    setUseless = function() end,
}
local record = {
    id = "npc_corpse_clothes",
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
            assertEqual(fullType, "Base.Shirt_FormalWhite", "created corpse clothing type")
            return shirt
        end,
    },
    VisualProfiles = {
        RollAppearance = function()
            return { outfitItems = { "Base.Shirt_FormalWhite" } }
        end,
    },
    Inventory = {
        EnsureRecordInventory = function()
            return { items = {} }
        end,
    },
    Visuals = { RefreshModel = function() end },
    Registry = {
        LiveByID = { [record.id] = zombie },
        MarkDirty = function() end,
    },
}

IsoDeadBody = {
    new = function()
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
assertEqual(#inventoryValues, 1, "corpse clothing inventory count")
assertEqual(sourceWorn:getItem("Shirt"), shirt, "source worn shirt")
assertEqual(corpseWorn:getItem("Shirt"), shirt, "corpse worn shirt")
assertEqual(visualCopies, 1, "live clothing visual copy count")
assertEqual(transmitCount, 1, "multiplayer corpse transmission count")
assertEqual(corpseModData.PNC_UUID, record.id, "corpse network NPC id")
assertEqual(corpseModData.PNC_BodyKind, "corpse", "corpse network body kind")
assertEqual(record.runtime.lifecycle.corpseState, "inert_loaded", "corpse lifecycle state")

print("pnc_corpse_clothing_smoke: ok")
