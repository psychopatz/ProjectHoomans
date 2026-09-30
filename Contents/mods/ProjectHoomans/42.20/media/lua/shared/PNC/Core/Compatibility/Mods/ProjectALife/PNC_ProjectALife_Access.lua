-- Project A-Life data access and shared primitives.
--
-- Owns body/record lookup, identity recovery, and the small predicates every
-- other Project A-Life spoke needs. No relationship or damage policy lives here.

PNC = PNC or {}
PNC.Compatibility = PNC.Compatibility or {}
PNC.Compatibility.ProjectALifeAdapter =
    PNC.Compatibility.ProjectALifeAdapter or {}

local Adapter = PNC.Compatibility.ProjectALifeAdapter
local Internal = Adapter.Internal or {}
Adapter.Internal = Internal

local ActorOwnership = PNC.Compatibility.ActorOwnership

function Internal.IsProjectALifeBody(body)
    if not body or not body.getModData then return false end

    local data = body:getModData()
    if type(data) ~= "table" then return false end

    return data.ProjectALifeOwned == true or data.ProjectALifeActor == true
end

function Internal.IsAlive(body)
    if body == nil then return false end
    local ok, dead = pcall(function()
        return body.isDead and body:isDead() == true
    end)
    if ok and dead then return false end
    local aliveOk, alive = pcall(function()
        return body.isAlive == nil or body:isAlive() == true
    end)
    return aliveOk and alive == true
end

function Internal.GetPosition(body)
    if body == nil then return nil, nil, nil end
    local ok, x, y, z = pcall(function()
        return body:getX(), body:getY(), body:getZ()
    end)
    if not ok then return nil, nil, nil end
    return tonumber(x), tonumber(y), tonumber(z)
end

function Internal.RegistryRecord(uid)
    local alife = ProjectALife
    local registry = alife and alife.ActorRegistry
    if type(uid) ~= "string" or registry == nil then return nil end
    if type(registry.read) == "function" then
        local ok, record = pcall(registry.read, uid)
        if ok and type(record) == "table" then return record end
    end
    if type(registry.peek) == "function" then
        local ok, record = pcall(registry.peek, uid)
        if ok and type(record) == "table" then return record end
    end
    return nil
end

function Internal.ActiveBinding(uid, generation)
    local alife = ProjectALife
    local watchdog = alife and alife.Watchdog
    local bindings = watchdog and watchdog.bindings
    local binding = type(bindings) == "table" and bindings[uid] or nil
    if type(binding) ~= "table" or binding.shell == nil then return nil end
    if generation ~= nil
        and tonumber(binding.generation) ~= tonumber(generation)
    then
        return nil
    end
    if not Internal.IsAlive(binding.shell) then return nil end
    return binding
end

function Internal.ActorReference(uid, generation)
    local record = Internal.RegistryRecord(uid)
    if record == nil or record.lifecycle ~= "active" then return nil end
    if generation ~= nil
        and tonumber(record.generation) ~= tonumber(generation)
    then
        return nil
    end
    local binding = Internal.ActiveBinding(
        tostring(record.uid or uid), record.generation)
    if binding == nil then return nil end
    local body = binding.shell
    local x, y, z = Internal.GetPosition(body)
    return {
        provider = "ProjectALifeNPCs",
        actorId = tostring(record.uid or uid),
        id = tostring(record.uid or uid),
        generation = tonumber(record.generation) or 0,
        kind = "foreign_npc",
        actor = record,
        worldObject = body,
        factionId = record.factionId,
        x = x,
        y = y,
        z = z,
    }
end

function Internal.FactionID(record)
    local factions = PNC.Factions
    if factions and type(factions.GetFactionID) == "function" then
        local ok, id = pcall(factions.GetFactionID, record)
        if ok and id ~= nil then return tostring(id) end
    end
    return record and record.affiliation
        and record.affiliation.factionID or nil
end

function Internal.BodyFactionID(body)
    if not body or not body.getModData then return nil end
    local ok, data = pcall(body.getModData, body)
    if not ok or type(data) ~= "table" then return nil end
    if data.PNC_FactionID ~= nil then
        return tostring(data.PNC_FactionID)
    end
    if data.PNC_UUID and PNC.Registry and PNC.Registry.Get then
        return Internal.FactionID(PNC.Registry.Get(data.PNC_UUID))
    end
    return nil
end

function Internal.IsHoomansBody(body)
    if ActorOwnership == nil
        or type(ActorOwnership.IsHoomansOwned) ~= "function"
    then
        return false
    end
    local ok, owned = pcall(ActorOwnership.IsHoomansOwned, body)
    return ok and owned == true
end

function Internal.ForeignActorRecord(body)
    if not body or not body.getModData then return nil end
    local ok, data = pcall(body.getModData, body)
    if not ok or type(data) ~= "table" then return nil end
    local uid = data.ProjectALifeUID
    if type(uid) ~= "string" or uid == "" then return nil end
    return Internal.RegistryRecord(uid)
end

-- A committed attack is re-resolved before its hit frame and arrives without
-- `factionId`, so the A-Life identity has to stay recoverable from the live
-- body. Losing it made the damage-time stance lookup fall through to a wildcard
-- key and reject a target that perception had already approved.
function Internal.TargetActorRecord(target)
    if type(target) ~= "table" then return nil end
    if type(target.actor) == "table" then return target.actor end
    return Internal.ForeignActorRecord(target.worldObject)
end

function Internal.TargetFactionID(target)
    local record = Internal.TargetActorRecord(target)
    if record and record.factionId ~= nil then
        return tostring(record.factionId)
    end
    if type(target) == "table" and target.factionId ~= nil then
        return tostring(target.factionId)
    end
    return Internal.BodyFactionID(target and target.worldObject)
end

function Internal.HoomansRecord(body)
    if not body or not body.getModData then return nil end
    local ok, data = pcall(body.getModData, body)
    if not ok or type(data) ~= "table" then return nil end
    local registry = PNC.Registry
    if type(data.PNC_UUID) ~= "string"
        or registry == nil or type(registry.Get) ~= "function"
    then
        return nil
    end
    local recordOk, record = pcall(registry.Get, data.PNC_UUID)
    return recordOk and type(record) == "table" and record or nil
end

function Internal.OwnerPlayer(record)
    local core = PNC.Core
    if type(record) ~= "table" or core == nil then return nil end
    local player
    if record.ownerOnlineID ~= nil
        and type(core.ResolvePlayerByOnlineID) == "function"
    then
        local ok, value = pcall(
            core.ResolvePlayerByOnlineID, record.ownerOnlineID)
        if ok and value ~= nil then player = value end
    end
    if player == nil and record.ownerUsername ~= nil
        and type(core.ResolvePlayerByUsername) == "function"
    then
        local ok, value = pcall(
            core.ResolvePlayerByUsername, record.ownerUsername)
        if ok and value ~= nil then player = value end
    end
    return player
end

function Internal.RecentThreat(record, actorId)
    local recent = record and record.runtime and record.runtime.recentThreat
    if type(recent) ~= "table"
        or recent.kind ~= "foreign_npc"
        or tostring(recent.provider or "") ~= "ProjectALifeNPCs"
        or tostring(recent.id or "") ~= tostring(actorId or "")
    then
        return false
    end
    return (tonumber(recent.expiresAt) or 0) >= (PNC.Core
        and PNC.Core.Now and PNC.Core.Now() or 0)
end

Adapter.IsProjectALifeBody = Internal.IsProjectALifeBody
Adapter.GetHoomansFactionID = Internal.BodyFactionID
Adapter.GetTargetFactionID = Internal.TargetFactionID

return Internal
