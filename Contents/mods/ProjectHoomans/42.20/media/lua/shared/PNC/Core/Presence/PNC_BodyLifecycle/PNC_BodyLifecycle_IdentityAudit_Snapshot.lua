-- Body identity snapshot and stable audit-line formatting.

PNC = PNC or {}
PNC.BodyLifecycle = PNC.BodyLifecycle or {}
PNC.BodyLifecycle.Internal = PNC.BodyLifecycle.Internal or {}

local Lifecycle = PNC.BodyLifecycle
local Internal = Lifecycle.Internal
local Core = PNC.Core
local Audit = Lifecycle.IdentityAudit

local function safeMember(object, name)
    local ok
    local value
    if not object then
        return nil
    end
    ok, value = pcall(function() return object[name] end)
    return ok and value or nil
end

local function safeNoArg(object, name)
    local method
    local ok
    local value
    if not object then
        return nil, false
    end
    method = safeMember(object, name)
    if not method then
        return nil, false
    end
    ok, value = pcall(method, object)
    if not ok then
        return nil, true
    end
    return value, true
end

local function valueText(value)
    if value == nil then
        return "nil"
    end
    return tostring(value)
end

local function field(name, value)
    return tostring(name) .. "=" .. valueText(value)
end

local function boolText(value)
    return value == true and "true" or "false"
end

local function readModData(zombie)
    local ok
    local value
    if not zombie or not zombie.getModData then
        return nil, false
    end
    ok, value = pcall(zombie.getModData, zombie)
    if not ok then
        return nil, true
    end
    return value, true
end

local function readBooleanVariable(zombie, name)
    if not zombie or not zombie.getVariableBoolean then
        return nil, false
    end
    local ok, result = pcall(
        zombie.getVariableBoolean, zombie, name)
    if ok then
        return result == true, true
    end
    return nil, true
end

local function readSnapshot(zombie, entry)
    local modData
    local modDataAvailable
    local outfitID
    local outfitAPI
    local populationID
    local populationAPI
    local onlineID
    local onlineAPI
    local objectID
    local objectIDAPI
    local zombieID
    local zombieIDAPI
    local persistentID
    local persistentIDAPI
    local persistentId
    local persistentIdAPI
    local x
    local y
    local z
    local dead
    local deadAPI
    local reanimated
    local reanimatedAPI
    local vehicle
    local vehicleAPI
    local attached
    local attachedOK
    local pnclive
    local pncliveAPI
    local pncactor
    local pncactorAPI

    modData, modDataAvailable = readModData(zombie)
    outfitID, outfitAPI = safeNoArg(zombie, "getPersistentOutfitID")
    populationID, populationAPI = safeNoArg(zombie, "getPersistentID")
    persistentId, persistentIdAPI = safeNoArg(zombie, "getPersistentId")
    onlineID, onlineAPI = safeNoArg(zombie, "getOnlineID")
    objectID, objectIDAPI = safeNoArg(zombie, "getID")
    zombieID, zombieIDAPI = safeNoArg(zombie, "getZombieID")
    persistentID = safeMember(zombie, "persistentId")
    persistentIDAPI = persistentIDAPI or persistentID ~= nil
    x = safeNoArg(zombie, "getX")
    y = safeNoArg(zombie, "getY")
    z = safeNoArg(zombie, "getZ")
    dead, deadAPI = safeNoArg(zombie, "isDead")
    reanimated, reanimatedAPI = safeNoArg(zombie, "isReanimatedPlayer")
    vehicle, vehicleAPI = safeNoArg(zombie, "getVehicle")
    if Internal.isBodyAttached then
        local ok, result = pcall(Internal.isBodyAttached, zombie)
        attachedOK = ok
        attached = ok and result or nil
    end
    pnclive, pncliveAPI = readBooleanVariable(zombie, "PNCLive")
    pncactor, pncactorAPI = readBooleanVariable(zombie, "PNCActor")

    return {
        auditID = entry.auditID,
        x = x,
        y = y,
        z = z,
        outfitID = outfitID,
        outfitAPI = outfitAPI,
        populationID = populationID,
        populationAPI = populationAPI,
        persistentId = persistentId,
        persistentIdAPI = persistentIdAPI,
        persistentID = persistentID,
        persistentIDAPI = persistentIDAPI,
        onlineID = onlineID,
        onlineAPI = onlineAPI,
        objectID = objectID,
        objectIDAPI = objectIDAPI,
        zombieID = zombieID,
        zombieIDAPI = zombieIDAPI,
        dead = dead,
        deadAPI = deadAPI,
        reanimated = reanimated,
        reanimatedAPI = reanimatedAPI,
        vehicle = vehicle,
        vehicleAPI = vehicleAPI,
        attached = attached,
        attachedOK = attachedOK,
        modDataAvailable = modDataAvailable,
        pncOwner = modData and modData.PNC_Owner or nil,
        pncNPC = modData and modData.PNC_NPC or nil,
        pncUUID = modData and modData.PNC_UUID or nil,
        pncLease = modData and modData.PNC_BodyLease or nil,
        pncPersistedShell = modData and modData.PNC_PersistedShell or nil,
        pncShellCarrier = modData and modData.PNC_ShellCarrier or nil,
        pncTagVersion = modData and modData.PNC_TagVersion or nil,
        pncBodyKind = modData and modData.PNC_BodyKind or nil,
        pncLive = pnclive,
        pncLiveAPI = pncliveAPI,
        pncActor = pncactor,
        pncActorAPI = pncactorAPI,
    }
end

local function signature(snapshot)
    return table.concat({
        valueText(snapshot.outfitID),
        valueText(snapshot.populationID),
        valueText(snapshot.persistentId),
        valueText(snapshot.persistentID),
        valueText(snapshot.onlineID),
        valueText(snapshot.objectID),
        valueText(snapshot.zombieID),
        valueText(snapshot.pncOwner),
        valueText(snapshot.pncNPC),
        valueText(snapshot.pncUUID),
        valueText(snapshot.pncLease),
        valueText(snapshot.pncPersistedShell),
        valueText(snapshot.pncShellCarrier),
        valueText(snapshot.pncTagVersion),
        valueText(snapshot.pncBodyKind),
        valueText(snapshot.pncLive),
        valueText(snapshot.pncActor),
    }, "|")
end

local function emit(snapshot, source, recordID, extra)
    local parts = {
        "body_identity_audit",
        field("auditID", snapshot.auditID),
        field("source", source or "unknown"),
        field("record", recordID),
        field("authority", Core and Core.IsAuthority
            and boolText(Core.IsAuthority()) or "unknown"),
        field("clientOnly", Core and Core.IsClientOnly
            and boolText(Core.IsClientOnly()) or "unknown"),
        field("spawnInProgress", boolText(Internal.SpawnInProgress == true)),
        field("pos", valueText(snapshot.x) .. ","
            .. valueText(snapshot.y) .. "," .. valueText(snapshot.z)),
        field("outfitID", snapshot.outfitID),
        field("outfitAPI", boolText(snapshot.outfitAPI)),
        field("populationID", snapshot.populationID),
        field("persistentId", snapshot.persistentId),
        field("persistentID", snapshot.persistentID),
        field("onlineID", snapshot.onlineID),
        field("objectID", snapshot.objectID),
        field("zombieID", snapshot.zombieID),
        field("dead", snapshot.dead),
        field("reanimated", snapshot.reanimated),
        field("vehicle", snapshot.vehicle ~= nil),
        field("attached", snapshot.attached),
        field("modDataAPI", boolText(snapshot.modDataAvailable)),
        field("PNC_Owner", snapshot.pncOwner),
        field("PNC_NPC", snapshot.pncNPC),
        field("PNC_UUID", snapshot.pncUUID),
        field("PNC_BodyLease", snapshot.pncLease),
        field("PNC_PersistedShell", snapshot.pncPersistedShell),
        field("PNC_ShellCarrier", snapshot.pncShellCarrier),
        field("PNC_TagVersion", snapshot.pncTagVersion),
        field("PNC_BodyKind", snapshot.pncBodyKind),
        field("PNCLive", snapshot.pncLive),
        field("PNCActor", snapshot.pncActor),
    }
    local index
    for index = 1, #(extra or {}) do
        parts[#parts + 1] = tostring(extra[index])
    end
    if Core and Core.LogInfo then
        Core.LogInfo(table.concat(parts, " "))
    elseif print then
        print("[PNC][INFO] " .. table.concat(parts, " "))
    end
end

Audit.ReadSnapshot = readSnapshot
Audit.Signature = signature
Audit.Emit = emit

return Audit
