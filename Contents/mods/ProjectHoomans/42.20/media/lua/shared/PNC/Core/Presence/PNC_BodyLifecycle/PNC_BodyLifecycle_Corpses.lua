-- Vanilla corpse conversion, delayed finalization, and marker stamping.

PNC = PNC or {}
PNC.BodyLifecycle = PNC.BodyLifecycle or {}
PNC.BodyLifecycle.Internal = PNC.BodyLifecycle.Internal or {}

local Lifecycle = PNC.BodyLifecycle
local Internal = Lifecycle.Internal
local Core = PNC.Core
local Const = PNC.Const

local function findExistingCorpse(record, zombie)
    local cell = getCell and getCell() or nil
    local x = record and record.corpse and record.corpse.x
        or zombie and zombie.getX and zombie:getX() or record and record.x
    local y = record and record.corpse and record.corpse.y
        or zombie and zombie.getY and zombie:getY() or record and record.y
    local z = record and record.corpse and record.corpse.z
        or zombie and zombie.getZ and zombie:getZ() or record and record.z
    local square
    local expectedToken = record and record.corpse
        and record.corpse.token or record and record.corpseToken
    local accepted
    if not cell or not cell.getGridSquare or not record
        or not Internal.forEachCorpse
    then
        return nil
    end
    square = cell:getGridSquare(
        math.floor(tonumber(x) or 0),
        math.floor(tonumber(y) or 0),
        math.floor(tonumber(z) or 0)
    )
    if not square then return nil end
    Internal.forEachCorpse(square, function(candidate)
        local modData = candidate.getModData and candidate:getModData() or nil
        local markerId = modData and (
            modData.PNC_DeathMarkerID or modData.PNC_UUID
        ) or nil
        local token = modData and modData.PNC_CorpseToken or nil
        if not accepted and tostring(markerId or "") == tostring(record.id)
            and (not expectedToken or not token
                or tostring(token) == tostring(expectedToken))
        then
            accepted = candidate
        end
    end)
    return accepted
end

function Internal.makeCorpseInert(corpse, createdWorldHour)
    -- The engine owns this corpse, but an NPC body starts as an IsoZombie.
    -- Prevent that backing actor from scheduling a second local/client
    -- reanimation. The authority invokes corpse:reanimate() explicitly for
    -- infected death markers.
    local reanimateAt =
        (tonumber(createdWorldHour) or Internal.worldHour()) + 100000000
    if not corpse then
        return
    end
    if corpse.setFakeDead then
        corpse:setFakeDead(false)
    end
    if corpse.setReanimateTime then
        corpse:setReanimateTime(reanimateAt)
    end
end

function Internal.stampCorpse(record, corpse, token)
    local modData
    if not record or not corpse or not corpse.getModData then
        return false
    end
    token = tostring(token or record.corpseToken
        or record.corpse and record.corpse.token
        or Core.GenerateID("corpse"))
    modData = corpse:getModData()
    modData.PNC_NPC = nil
    modData.PNC_UUID = nil
    modData.PNC_BodyKind = nil
    modData.PNC_BodyLease = nil
    modData.PNC_PersistedShell = nil
    modData.PNC_ShellVersion = nil
    modData.PNC_BaseOutfit = nil
    modData.PNC_DeathMarkerID = tostring(record.id)
    modData.PNC_DeathName = tostring(record.name or record.displayName or "Unknown NPC")
    modData.PNC_CorpseToken = token
    modData.PNC_TagVersion = Const.BODY_TAG_VERSION
    Internal.makeCorpseInert(
        corpse,
        record.createdWorldHour
            or record.corpse and record.corpse.createdWorldHour
    )
    if record.corpse then
        record.corpse.token = token
        record.corpse.x = corpse.getX and corpse:getX() or record.x
        record.corpse.y = corpse.getY and corpse:getY() or record.y
        record.corpse.z = corpse.getZ and corpse:getZ() or record.z
        record.corpse.createdWorldHour =
            tonumber(record.corpse.createdWorldHour) or Internal.worldHour()
    else
        record.corpseToken = token
        record.x = corpse.getX and corpse:getX() or record.x
        record.y = corpse.getY and corpse:getY() or record.y
        record.z = corpse.getZ and corpse:getZ() or record.z
    end
    if record.runtime then
        Internal.ensureRuntime(record).corpseState = "inert_loaded"
    end
    if PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(record.id) == record
        and PNC.Registry.MarkDirty
    then
        PNC.Registry.MarkDirty(record, "corpse")
    elseif PNC.Registry then
        PNC.Registry.DirectoryDirty = true
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

local function createEngineCorpse(zombie)
    local constructor
    local ok
    local corpse
    if not IsoDeadBody or not IsoDeadBody.new then
        return nil, "engine_corpse_constructor_unavailable"
    end
    constructor = IsoDeadBody.new
    ok, corpse = pcall(constructor, zombie, false, true)
    if not ok then
        return nil, "engine_corpse_constructor_failed"
    end
    if not corpse then
        return nil, "engine_corpse_constructor_returned_nil"
    end
    return corpse
end

function Lifecycle.CreateVanillaCorpse(record, zombie, reason)
    local x
    local y
    local z
    local token
    local createdWorldHour
    local corpse
    local converted = false
    local failureReason
    local sourceWornItems
    local wornEntries
    local existing
    local runtime
    local sourceBodyInstanceID
    local sourceBodyOnlineID
    if not record or not zombie then
        return false, nil
    end
    runtime = Internal.ensureRuntime(record)
    existing = findExistingCorpse(record, zombie)
    if existing then
        -- A death audit can revisit the same dead record after the engine has
        -- already produced a body. Reuse that authoritative object and retire
        -- the transient zombie shell instead of converting a second corpse.
        token = record.corpse and record.corpse.token
            or record.corpseToken or Core.GenerateID("corpse")
        Internal.ensureCorpseIdentityCard(record, existing)
        Internal.stampCorpse(record, existing, token)
        Internal.clearBodyCombat(zombie)
        Internal.removeZombie(zombie)
        record.presenceState = Const.PRESENCE_CORPSE
        Internal.detachLiveBody(record, reason or "death")
        Internal.mark(record, "corpse", "inert_loaded", reason or "death")
        runtime.corpseState = "inert_loaded"
        return true, existing
    end
    if runtime.corpseState == "finalizing"
        or runtime.corpseState == "inert_loaded"
    then
        return true, nil
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
        zombie:setReanimate(false)
    end
    if zombie.setReanim then
        zombie:setReanim(false)
    end
    Internal.clearBodyCombat(zombie)
    Internal.prepareCorpseItems(record, zombie)
    sourceWornItems = zombie.getWornItems and zombie:getWornItems() or nil
    wornEntries = Internal.captureWornEntries(sourceWornItems)
    sourceBodyInstanceID = Internal.GetStartupBodyInstanceID
        and Internal.GetStartupBodyInstanceID(zombie)
        or zombie.getPersistentOutfitID
            and zombie:getPersistentOutfitID() or nil
    sourceBodyOnlineID = Internal.normalizeOnlineID(zombie)
    -- IsoDeadBody is the Build 42 engine-owned corpse constructor. It copies
    -- the prepared inventory, worn items, visuals, and ModData, removes the
    -- source zombie, and inserts one real corpse into the square. Multiplayer
    -- replication is announced explicitly below with AddCorpseToMap because
    -- this constructor does not invoke the character-death listener.
    corpse, failureReason = createEngineCorpse(zombie)
    converted = corpse ~= nil
    if not corpse then
        Internal.removeZombie(zombie)
        runtime.corpseState = "missing"
    end
    record.presenceState = Const.PRESENCE_CORPSE
    Internal.detachLiveBody(record, reason or "death")
    if corpse then
        -- Guarantee the stable quest identity on the final vanilla-owned
        -- container before the one complete-corpse MP sync.
        Internal.ensureCorpseIdentityCard(record, corpse)
        Internal.applyCorpseWornItems(corpse, wornEntries)
        Internal.stampCorpse(record, corpse, token)
        Internal.mark(record, "corpse", "inert_loaded", reason or "death")
        Internal.announceCorpse(corpse)
        runtime.corpseState = "inert_loaded"
    else
        Internal.mark(record, "corpse", "missing", reason or "death")
    end
    if isServer and isServer() == true
        and PNC.Network and PNC.Network.BroadcastBodyRemoval
    then
        -- The native AddCorpse packet does not identify the managed live-body
        -- shell. Remove that shell on every client using the IDs captured
        -- before IsoDeadBody detached the source zombie.
        PNC.Network.BroadcastBodyRemoval(
            record.id,
            sourceBodyInstanceID,
            sourceBodyOnlineID,
            reason or "death"
        )
    end
    return converted, corpse or failureReason
end
