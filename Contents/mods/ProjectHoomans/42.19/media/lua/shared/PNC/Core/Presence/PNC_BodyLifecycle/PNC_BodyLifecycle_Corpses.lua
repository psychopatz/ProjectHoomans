-- Corpse conversion, delayed finalization, and corpse-record supervision.

PNC = PNC or {}
PNC.BodyLifecycle = PNC.BodyLifecycle or {}
PNC.BodyLifecycle.Internal = PNC.BodyLifecycle.Internal or {}

local Lifecycle = PNC.BodyLifecycle
local Internal = Lifecycle.Internal
local Core = PNC.Core
local Const = PNC.Const

function Internal.makeCorpseInert(corpse, createdWorldHour)
    local reanimateAt = (tonumber(createdWorldHour) or Internal.worldHour()) + 100000000
    if not corpse then
        return
    end
    if corpse.setFakeDead then
        pcall(corpse.setFakeDead, corpse, false)
    end
    if corpse.setReanimateTime then
        pcall(corpse.setReanimateTime, corpse, reanimateAt)
    end
end

function Internal.stampCorpse(record, corpse, token)
    local modData
    if not record or not corpse or not corpse.getModData then
        return false
    end
    token = tostring(token or Core.GenerateID("corpse"))
    modData = corpse:getModData()
    modData.PNC_NPC = true
    modData.PNC_UUID = tostring(record.id)
    modData.PNC_BodyKind = "corpse"
    modData.PNC_CorpseToken = token
    modData.PNC_TagVersion = Const.BODY_TAG_VERSION
    Internal.makeCorpseInert(corpse, record.corpse and record.corpse.createdWorldHour)
    record.corpse = record.corpse or {}
    record.corpse.token = token
    record.corpse.x = corpse.getX and corpse:getX() or record.x
    record.corpse.y = corpse.getY and corpse:getY() or record.y
    record.corpse.z = corpse.getZ and corpse:getZ() or record.z
    record.corpse.createdWorldHour = tonumber(record.corpse.createdWorldHour) or Internal.worldHour()
    Internal.ensureRuntime(record).corpseState = "inert_loaded"
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "corpse")
    end
    return true
end

function Internal.scheduleCorpseFinalize(record, x, y, z, token, reason, wornEntries)
    Lifecycle.PendingCorpses[#Lifecycle.PendingCorpses + 1] = {
        npcId = tostring(record.id),
        x = math.floor(tonumber(x) or 0),
        y = math.floor(tonumber(y) or 0),
        z = math.floor(tonumber(z) or 0),
        token = token,
        reason = reason,
        attempts = 0,
        wornEntries = wornEntries,
    }
end

function Lifecycle.CreateInertCorpse(record, zombie, reason)
    local x
    local y
    local z
    local token
    local createdWorldHour
    local ok
    local corpse
    local converted = false
    local sourceWornItems
    local wornEntries
    if not record or not zombie then
        return false, nil
    end
    x = zombie.getX and zombie:getX() or record.x
    y = zombie.getY and zombie:getY() or record.y
    z = zombie.getZ and zombie:getZ() or record.z
    token = record.corpse and record.corpse.token or Core.GenerateID("corpse")
    createdWorldHour = record.corpse and tonumber(record.corpse.createdWorldHour) or Internal.worldHour()
    record.x = x
    record.y = y
    record.z = z
    record.corpse = {
        token = token,
        x = x,
        y = y,
        z = z,
        createdWorldHour = createdWorldHour,
    }
    if zombie.setReanimate then
        pcall(zombie.setReanimate, zombie, false)
    end
    if zombie.setReanim then
        pcall(zombie.setReanim, zombie, false)
    end
    Internal.clearBodyCombat(zombie)
    Internal.prepareCorpseItems(record, zombie)
    sourceWornItems = zombie.getWornItems and zombie:getWornItems() or nil
    wornEntries = Internal.captureWornEntries(sourceWornItems)
    if IsoDeadBody and IsoDeadBody.new then
        ok, corpse = pcall(IsoDeadBody.new, zombie, false, true)
        if not ok or not corpse then
            ok, corpse = pcall(IsoDeadBody.new, zombie, false)
        end
    end
    converted = corpse ~= nil
    if not corpse then
        if zombie.becomeCorpseSilently then
            ok = pcall(zombie.becomeCorpseSilently, zombie)
            converted = ok == true
        end
        if converted then
            Internal.scheduleCorpseFinalize(record, x, y, z, token, reason or "death", wornEntries)
            Internal.ensureRuntime(record).corpseState = "finalizing"
        else
            Internal.removeZombie(zombie)
            Internal.ensureRuntime(record).corpseState = "missing"
        end
    end
    record.presenceState = Const.PRESENCE_CORPSE
    Internal.detachLiveBody(record, reason or "death")
    Internal.mark(record, "corpse", "missing", reason or "death")
    if corpse then
        Internal.applyCorpseWornItems(corpse, wornEntries)
        Internal.stampCorpse(record, corpse, token)
        Internal.transmitCorpseState(corpse)
        Internal.ensureRuntime(record).corpseState = "inert_loaded"
    end
    return corpse ~= nil, corpse
end
