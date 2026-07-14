-- Corpse conversion, delayed finalization, and corpse-record supervision.

PNC = PNC or {}
PNC.BodyLifecycle = PNC.BodyLifecycle or {}
PNC.BodyLifecycle.Internal = PNC.BodyLifecycle.Internal or {}

local Lifecycle = PNC.BodyLifecycle
local Internal = Lifecycle.Internal
local Core = PNC.Core
local Const = PNC.Const

function Internal.makeCorpseInert(corpse, createdWorldHour, requestedReanimateAt)
    local reanimateAt = tonumber(requestedReanimateAt)
        or ((tonumber(createdWorldHour) or Internal.worldHour()) + 100000000)
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
    local infection
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
    infection = record.health and record.health.body and record.health.body.infection or nil
    Internal.makeCorpseInert(
        corpse,
        record.corpse and record.corpse.createdWorldHour,
        infection and infection.fatal == true and infection.reanimateAtWorldHour or nil
    )
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

function Lifecycle.ReleaseReanimatedNPC(record, zombie)
    local modData
    local variables = {
        "PNCLive", "PNCActor", "PNCAnim", "PNCMoveAnim", "PNCWalkType",
        "NoLungeTarget", "NoLungeAttack", "ZombieHitReaction", "bMoving",
        "isMoving", "Speed", "MovementSpeed", "bCrawling",
    }
    local i
    if not record or not zombie then return false end
    modData = zombie.getModData and zombie:getModData() or nil
    if modData then
        modData.PNC_ReanimatedFrom = tostring(record.id)
        modData.PNC_NPC = nil
        modData.PNC_UUID = nil
        modData.PNC_BodyKind = nil
        modData.PNC_BodyLease = nil
        modData.PNC_CorpseToken = nil
        modData.PNC_TagVersion = nil
        modData.PNC_AggroNPCId = nil
        modData.PNC_AggroNPCUntil = nil
        modData.PNC_AggroPathAt = nil
        modData.PNC_AggroPathX = nil
        modData.PNC_AggroPathY = nil
        modData.PNC_BumpReleaseAt = nil
        modData.PNC_BumpReleasePending = nil
        modData.PNC_CombatReaction = nil
    end
    for i = 1, #variables do
        if zombie.clearVariable then
            pcall(zombie.clearVariable, zombie, variables[i])
        elseif zombie.setVariable then
            pcall(zombie.setVariable, zombie, variables[i], false)
        end
    end
    if zombie.setUseless then pcall(zombie.setUseless, zombie, false) end
    if zombie.setNoTeeth then pcall(zombie.setNoTeeth, zombie, false) end
    if zombie.setZombiesDontAttack then pcall(zombie.setZombiesDontAttack, zombie, false) end
    if zombie.setReanimate then pcall(zombie.setReanimate, zombie, false) end
    if zombie.setCanWalk then pcall(zombie.setCanWalk, zombie, true) end
    if zombie.setHealth then
        local health = zombie.getHealth and tonumber(zombie:getHealth()) or 0
        if health <= 0 then pcall(zombie.setHealth, zombie, 1) end
    end
    if PNC.Network and PNC.Network.BroadcastRemoval then
        PNC.Network.BroadcastRemoval(record.id, "zombified")
    end
    if PNC.Registry and PNC.Registry.RemoveRecord then
        PNC.Registry.RemoveRecord(record.id)
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
