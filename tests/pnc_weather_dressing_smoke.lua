local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "shared" },
    { "PsychopatzCore", "shared" },
})

local now = 10000
PNC = {
    Core = {
        Now = function() return now end,
        IsAuthority = function() return true end,
        DeepCopy = function(v)
            if type(v) ~= "table" then return v end
            local out = {}
            for k, val in pairs(v) do out[k] = val end
            return out
        end,
    },
    Const = { PRESENCE_LIVE = "live" },
}

local scriptItems = {
    ["Base.PonchoGreen"] = {
        getBodyLocation = function() return "Jacket" end,
        getInsulation = function() return 0.25 end,
        getWaterResistance = function() return 0.95 end,
        getBiteDefense = function() return 0 end,
        getScratchDefense = function() return 0 end,
    },
    ["Base.Jacket_Padded"] = {
        getBodyLocation = function() return "Jacket" end,
        getInsulation = function() return 0.90 end,
        getWaterResistance = function() return 0.40 end,
        getBiteDefense = function() return 0 end,
        getScratchDefense = function() return 10 end,
    },
    ["Base.Tshirt_DefaultTEXTURE"] = {
        getBodyLocation = function() return "Tshirt" end,
        getInsulation = function() return 0.15 end,
        getWaterResistance = function() return 0.10 end,
        getBiteDefense = function() return 0 end,
        getScratchDefense = function() return 0 end,
    },
}

ScriptManager = {
    instance = {
        getItem = function(_, ft) return scriptItems[ft] end,
    },
}

local Appearance = T.load("ProjectHoomans", "shared",
    "PNC/Core/Identity/PNC_Identity_Appearance.lua")

local visualRefreshes = 0
PNC.Visuals = {
    ApplyResolvedAppearance = function()
        visualRefreshes = visualRefreshes + 1
    end,
}

local Weather = T.load("ProjectHoomans", "server",
    "PNC/World/PNC_WeatherDressingService.lua")
Weather.Reset()

-- 1. Weather band hysteresis
local band, rev1 = Weather.SampleWeather(now, { tempC = 18, rain = 0.0 })
T.equal(band, "NORMAL", "mild dry weather is NORMAL")

band = Weather.SampleWeather(now + 10000, { tempC = 16, rain = 0.35 })
T.equal(band, "RAIN", "rain >= 0.25 enters RAIN band")

band = Weather.SampleWeather(now + 20000, { tempC = 16, rain = 0.18 })
T.equal(band, "RAIN", "rain hysteresis holds RAIN above 0.12")

band = Weather.SampleWeather(now + 30000, { tempC = 16, rain = 0.05 })
T.equal(band, "NORMAL", "rain <= 0.12 exits back to NORMAL")

band = Weather.SampleWeather(now + 40000, { tempC = 5.0, rain = 0.0 })
T.equal(band, "COLD", "temp <= 8C enters COLD band")

band = Weather.SampleWeather(now + 50000, { tempC = 10.0, rain = 0.0 })
T.equal(band, "COLD", "cold hysteresis holds COLD below 11C")

band = Weather.SampleWeather(now + 60000, { tempC = 29.0, rain = 0.0 })
T.equal(band, "HOT", "temp >= 28C enters HOT band")

-- 2. Non-player-owned NPC: ephemeral overlay + clean revert to default
local outdoorBody = {
    getCurrentSquare = function()
        return { isOutside = function() return true end }
    end,
}
local roamer = {
    id = "roam_1",
    alive = true,
    presenceState = "live",
    identitySeed = 0,
    appearance = { outfit = { mode = "random" }, slots = {} },
    runtime = {},
}

Weather.SampleWeather(now + 70000, { tempC = 15, rain = 0.40 })
local changed = Weather.EvaluateNPC(roamer, outdoorBody, now + 70000)
T.truthy(changed, "roamer applies ephemeral rain overlay")
T.truthy(roamer.runtime.weatherOverlay ~= nil, "ephemeral overlay set in runtime")
local resolvedRain = Appearance.Resolve(roamer, { "Base.Tshirt_DefaultTEXTURE" })
T.equal(#resolvedRain.items, 2, "resolved appearance includes default shirt + rain poncho")
T.equal(resolvedRain.items[2], "Base.PonchoGreen", "deterministic poncho added")

-- Steady-state O(1) skip
local changedAgain = Weather.EvaluateNPC(roamer, outdoorBody, now + 71000)
T.falsy(changedAgain, "unchanged weather revision skips in O(1)")

-- Weather clears -> instant revert to default outfit
Weather.SampleWeather(now + 80000, { tempC = 18, rain = 0.0 })
local reverted = Weather.EvaluateNPC(roamer, outdoorBody, now + 80000)
T.truthy(reverted, "roamer reverts when rain stops")
T.falsy(roamer.runtime.weatherOverlay, "ephemeral overlay cleared")
local resolvedNormal = Appearance.Resolve(roamer, { "Base.Tshirt_DefaultTEXTURE" })
T.equal(#resolvedNormal.items, 1, "reverted appearance restores exact default outfit")
T.equal(resolvedNormal.items[1], "Base.Tshirt_DefaultTEXTURE", "default item preserved")

-- 3. Player-owned colonist: strictly uses owned personal inventory + faction storage
local wornCalls = 0
local unwearCalls = 0
local colonistInv = {
    items = {
        ["item_rain_1"] = { id = "item_rain_1", type = "Base.PonchoGreen", wornSlot = nil },
    },
    worn = {},
}
local nextItemSeq = 10
PNC.Inventory = {
    EnsureRecordInventory = function(rec) return rec._inv end,
    SetWorn = function(rec, itemId, slot)
        wornCalls = wornCalls + 1
        rec._inv.worn[slot] = itemId
        rec._inv.items[itemId].wornSlot = slot
        return true
    end,
    ClearWorn = function(rec, itemId)
        unwearCalls = unwearCalls + 1
        local it = rec._inv.items[itemId]
        if it and it.wornSlot then
            rec._inv.worn[it.wornSlot] = nil
            it.wornSlot = nil
        end
        return true
    end,
    AddItems = function(rec, specs)
        local added = {}
        for i = 1, #specs do
            nextItemSeq = nextItemSeq + 1
            local id = "borrowed_" .. tostring(nextItemSeq)
            local item = { id = id, type = specs[i].type, wornSlot = nil }
            rec._inv.items[id] = item
            added[#added + 1] = item
        end
        return true, added
    end,
    RemoveItems = function(rec, ids)
        for i = 1, #ids do rec._inv.items[ids[i]] = nil end
        return true
    end,
}

local colonist = {
    id = "col_1",
    alive = true,
    recruited = true,
    colonyOwned = true,
    factionID = "fac_1",
    presenceState = "live",
    runtime = {},
    _inv = colonistInv,
}

Weather.SampleWeather(now + 90000, { tempC = 14, rain = 0.50 })
local colChanged = Weather.EvaluateNPC(colonist, outdoorBody, now + 90000)
T.truthy(colChanged, "colonist equips owned poncho from personal inventory")
T.falsy(colonist.runtime.weatherOverlay, "player-owned colonist never uses fake overlay")
T.equal(colonistInv.worn.Jacket, "item_rain_1", "owned poncho is worn in Jacket slot")

-- Revert back to personal inventory when rain stops
Weather.SampleWeather(now + 100000, { tempC = 18, rain = 0.0 })
Weather.EvaluateNPC(colonist, outdoorBody, now + 100000)
T.falsy(colonistInv.worn.Jacket, "colonist unwears poncho when rain ends")
T.truthy(colonistInv.items["item_rain_1"] ~= nil, "owned poncho remains in personal inventory")

-- 4. Player-owned colonist borrows from faction storage when personal inventory lacks cold coat
local C = require "PsychopatzCore/Inventory/PsychopatzInventoryConstants"
local storageRecords = {
    { [C.TYPE_ID] = "Base.Jacket_Padded", [C.QUANTITY] = 1 },
}
local storage = {
    id = "stor_1",
    inventory = {
        records = storageRecords,
        remove = function(self, ft, qty)
            for i = 1, #self.records do
                if self.records[i][C.TYPE_ID] == ft and self.records[i][C.QUANTITY] >= qty then
                    self.records[i][C.QUANTITY] = self.records[i][C.QUANTITY] - qty
                    return true
                end
            end
            return false
        end,
        add = function(self, entry)
            self.records[#self.records + 1] = { [C.TYPE_ID] = entry[1], [C.QUANTITY] = entry[2] }
            return true
        end,
    },
}
PNC.ColonyStorageRepository = {
    ByID = { stor_1 = storage },
    PrimaryByFaction = { fac_1 = storage },
    MarkDirty = function() end,
}

Weather.SampleWeather(now + 110000, { tempC = 3.0, rain = 0.0 })
local coldChanged = Weather.EvaluateNPC(colonist, outdoorBody, now + 110000)
T.truthy(coldChanged, "colonist borrows padded jacket from faction storage in cold weather")
T.equal(storageRecords[1][C.QUANTITY], 0, "jacket withdrawn from faction storage")
T.truthy(colonistInv.worn.Jacket ~= nil, "borrowed jacket is worn")

-- Weather warms -> returns borrowed jacket to faction storage
Weather.SampleWeather(now + 120000, { tempC = 19.0, rain = 0.0 })
Weather.EvaluateNPC(colonist, outdoorBody, now + 120000)
T.falsy(colonistInv.worn.Jacket, "borrowed jacket unworn when warm")
T.equal(#storageRecords, 2, "borrowed jacket returned to faction storage")
