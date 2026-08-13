local SHARED = "Contents/mods/ProjectHoomans/42.20/media/lua/shared/"
local SERVER = "Contents/mods/ProjectHoomans/42.20/media/lua/server/"
local CORE = "../psychopatzCore/Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = SHARED .. "?.lua;" .. SERVER .. "?.lua;" .. CORE .. "?.lua;"
    .. package.path

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

isClient = function() return false end
isServer = function() return true end
getGameTime = function()
    return { getWorldAgeHours = function() return 2 end }
end

local dirtied = {}
PNC = {
    Registry = {
        MarkDirty = function(record, domain)
            dirtied[#dirtied + 1] = { record.id, domain }
        end,
    },
}

local Events = require "PsychopatzCore/Events/PC_EventBus"
local CoreJournals = require "PsychopatzCore/Journal/PC_JournalService"
local EventTypes = require "PNC/Core/Events/PNC_EventDefinitions"
local Adapter = require "PNC/Journals/PNC_JournalRoutes"
local StorageJournal = require
    "PNC/Core/Colony/Storage/PNC_ColonyStorageJournal"

equal(Adapter.STORAGE_CAPACITY, StorageJournal.MAX_ENTRIES,
    "storage journal capacity has one authority")
equal(CoreJournals.getType(Adapter.TYPE.COLONY_ACTIVITY).capacity,
    StorageJournal.MAX_ENTRIES,
    "storage journal route preserves canonical capacity")

local owned = {
    id = "owned", recruited = true, ownerUsername = "player", alive = true,
}
local worldNPC = { id = "world", recruited = false, alive = true }
local abstractNPC = { id = "abstract", recruited = false, persist = true }

Events.emit(EventTypes.NPC_FOOD_CONSUMED, worldNPC, "Base.Apple", 0.2)
Events.emit(EventTypes.NPC_DRINK_CONSUMED, abstractNPC, "Base.WaterBottle", 0.3)
equal(Adapter.HasNPC(worldNPC.id), false, "world NPC journal stays lazy")
equal(Adapter.HasNPC(abstractNPC.id), false, "abstract NPC journal stays lazy")

Events.emit(EventTypes.NPC_FOOD_CONSUMED, owned, "Base.Apple", 0.2)
Events.emit(EventTypes.NPC_DRINK_CONSUMED, owned, "Base.WaterBottle", 0.3)
Events.emit(EventTypes.NPC_SKILL_LEVEL_UP, owned, "Axe", 4)
Events.emit(EventTypes.NPC_WOUNDED, owned, "Hand_L", "laceration", 7)
equal(#Adapter.GetNPC(owned.id), 4, "owned NPC events accepted")
equal(Adapter.GetNPC(owned.id)[1][1], EventTypes.NPC_FOOD_CONSUMED,
    "semantic event ID stored")
equal(Adapter.GetNPC(owned.id)[1][3], "Base.Apple",
    "stable item identifier stored")
equal(dirtied[#dirtied][2], "npc_journal", "NPC persistence marked dirty")

for index = 1, 40 do
    Events.emit(EventTypes.NPC_SKILL_LEVEL_UP, owned, "Axe", index)
end
equal(#Adapter.GetNPC(owned.id), Adapter.NPC_CAPACITY, "NPC journal bounded")

local payload = Adapter.ExportNPC(owned)
CoreJournals.remove(Adapter.TYPE.NPC_HISTORY, owned.id)
equal(Adapter.HasNPC(owned.id), false, "NPC journal removed")
local ok, count = Adapter.ImportNPC(owned, payload)
equal(ok, true, "NPC journal restored")
equal(count, Adapter.NPC_CAPACITY, "NPC journal save round trip")

local serializedText = ""
for _, entry in ipairs(payload.entries or {}) do
    for _, value in ipairs(entry) do
        serializedText = serializedText .. tostring(value) .. "|"
    end
end
equal(string.find(serializedText, "ate an Apple", 1, true), nil,
    "rendered UI strings not persisted")

print("pnc_journal_routes_smoke: ok")
