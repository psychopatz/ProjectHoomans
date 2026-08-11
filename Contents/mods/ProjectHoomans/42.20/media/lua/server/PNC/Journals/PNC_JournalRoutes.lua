if isClient and isClient() and (not isServer or not isServer()) then return end

PNC = PNC or {}
PNC.Journals = PNC.Journals or {}

local Adapter = PNC.Journals
local Events = require "PsychopatzCore/Events/PC_EventBus"
local CoreJournals = require "PsychopatzCore/Journal/PC_JournalService"
local EventTypes = require "PNC/Core/Events/PNC_EventDefinitions"

Adapter.TYPE = {
    COLONY_ACTIVITY = "projecthoomans.colonyActivity",
    NPC_HISTORY = "projecthoomans.npcHistory",
}
Adapter.NPC_CAPACITY = 32
Adapter.STORAGE_CAPACITY = 10

CoreJournals.registerType(Adapter.TYPE.COLONY_ACTIVITY, {
    storage = "boundedRing",
    capacity = Adapter.STORAGE_CAPACITY,
    persistent = true,
})
CoreJournals.registerType(Adapter.TYPE.NPC_HISTORY, {
    storage = "boundedRing",
    capacity = Adapter.NPC_CAPACITY,
    persistent = true,
})

local function worldMinute()
    local gameTime = getGameTime and getGameTime() or nil
    local hours = gameTime and gameTime.getWorldAgeHours
        and tonumber(gameTime:getWorldAgeHours()) or 0
    return math.max(0, math.floor(hours * 60 + 0.5))
end

function Adapter.IsPlayerOwnedNPC(record)
    return type(record) == "table"
        and (record.recruited == true
            or record.ownerUsername ~= nil or record.ownerOnlineID ~= nil)
end

local function markNPCDirty(record)
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "npc_journal")
    end
end

local function appendNPC(eventType, record, ...)
    if not Adapter.IsPlayerOwnedNPC(record) then return false end
    local ok = CoreJournals.append(
        Adapter.TYPE.NPC_HISTORY, record.id, eventType, worldMinute(), ...
    )
    if ok then markNPCDirty(record) end
    return ok
end

local function appendStorage(eventType, storageID, actor, typeID, quantity,
        reason, at)
    local ok = CoreJournals.append(
        Adapter.TYPE.COLONY_ACTIVITY, storageID, eventType,
        at or worldMinute(), tostring(actor or ""),
        math.floor(tonumber(typeID) or 0),
        math.max(1, math.floor(tonumber(quantity) or 1)),
        tostring(reason or "")
    )
    if ok and PNC.ColonyStorageRepository then
        PNC.ColonyStorageRepository.MarkDirty()
    end
    return ok
end

local function onFoodConsumed(record, fullType, restored)
    appendNPC(EventTypes.NPC_FOOD_CONSUMED, record,
        tostring(fullType or ""), tonumber(restored) or 0)
end

local function onDrinkConsumed(record, fullType, restored)
    appendNPC(EventTypes.NPC_DRINK_CONSUMED, record,
        tostring(fullType or ""), tonumber(restored) or 0)
end

local function onSkillLevelUp(record, skillID, level)
    appendNPC(EventTypes.NPC_SKILL_LEVEL_UP, record,
        tostring(skillID or ""), math.floor(tonumber(level) or 0))
end

local function onWounded(record, partID, woundType, damage)
    appendNPC(EventTypes.NPC_WOUNDED, record, tostring(partID or ""),
        tostring(woundType or ""), tonumber(damage) or 0)
end

local function onStorageDeposited(...)
    return appendStorage(EventTypes.STORAGE_ITEM_DEPOSITED, ...)
end

local function onStorageWithdrawn(...)
    return appendStorage(EventTypes.STORAGE_ITEM_WITHDRAWN, ...)
end

Events.subscribe(EventTypes.STORAGE_ITEM_DEPOSITED, onStorageDeposited,
    "projecthoomans.journals")
Events.subscribe(EventTypes.STORAGE_ITEM_WITHDRAWN, onStorageWithdrawn,
    "projecthoomans.journals")
Events.subscribe(EventTypes.NPC_FOOD_CONSUMED, onFoodConsumed,
    "projecthoomans.journals")
Events.subscribe(EventTypes.NPC_DRINK_CONSUMED, onDrinkConsumed,
    "projecthoomans.journals")
Events.subscribe(EventTypes.NPC_SKILL_LEVEL_UP, onSkillLevelUp,
    "projecthoomans.journals")
Events.subscribe(EventTypes.NPC_WOUNDED, onWounded,
    "projecthoomans.journals")

function Adapter.GetNPC(npcID, limit, newestFirst)
    return CoreJournals.getRecent(
        Adapter.TYPE.NPC_HISTORY, npcID, limit, newestFirst
    )
end

function Adapter.HasNPC(npcID)
    return CoreJournals.hasJournal(Adapter.TYPE.NPC_HISTORY, npcID)
end

function Adapter.RemoveNPC(npcID)
    return CoreJournals.remove(Adapter.TYPE.NPC_HISTORY, npcID)
end

function Adapter.ExportNPC(record)
    if not Adapter.IsPlayerOwnedNPC(record) then return nil end
    return CoreJournals.export(Adapter.TYPE.NPC_HISTORY, record.id)
end

function Adapter.ImportNPC(record, payload)
    if not Adapter.IsPlayerOwnedNPC(record) then return false, "not_player_owned" end
    return CoreJournals.import(Adapter.TYPE.NPC_HISTORY, record.id, payload)
end

return Adapter
