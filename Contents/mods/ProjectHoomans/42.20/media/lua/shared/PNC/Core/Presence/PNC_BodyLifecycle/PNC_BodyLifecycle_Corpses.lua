-- Vanilla corpse conversion, delayed finalization, and marker stamping.

PNC = PNC or {}
PNC.BodyLifecycle = PNC.BodyLifecycle or {}
PNC.BodyLifecycle.Internal = PNC.BodyLifecycle.Internal or {}

local Lifecycle = PNC.BodyLifecycle
local Internal = Lifecycle.Internal
local Core = PNC.Core
local Const = PNC.Const

local function corpseFactionSnapshot(record)
    local factionID = record and record.affiliation
        and record.affiliation.factionID or nil
    local faction
    if factionID and PNC.Factions then
        if type(PNC.Factions.GetPresentation) == "function" then
            faction = PNC.Factions.GetPresentation(factionID)
        elseif type(PNC.Factions.Get) == "function" then
            faction = PNC.Factions.Get(factionID)
        end
    end
    return factionID and tostring(factionID) or nil,
        faction and tostring(faction.name or "") or nil
end

local function findExistingCorpse(record, zombie)
    local cell = getCell and getCell() or nil
    local points = {}
    local seenPoints = {}
    local expectedToken = record and record.corpse
        and record.corpse.token or record and record.corpseToken
    local accepted
    local function addPoint(x, y, z)
        local key
        x = math.floor(tonumber(x) or 0)
        y = math.floor(tonumber(y) or 0)
        z = math.floor(tonumber(z) or 0)
        key = tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z)
        if not seenPoints[key] then
            seenPoints[key] = true
            points[#points + 1] = { x = x, y = y, z = z }
        end
    end
    if not cell or not cell.getGridSquare or not record
        or not Internal.forEachCorpse
    then
        return nil
    end
    addPoint(record and record.corpse and record.corpse.x,
        record and record.corpse and record.corpse.y,
        record and record.corpse and record.corpse.z)
    if zombie then
        addPoint(zombie.getX and zombie:getX(), zombie.getY and zombie:getY(),
            zombie.getZ and zombie:getZ())
    end
    addPoint(record.x, record.y, record.z)
    for index = 1, #points do
        local point = points[index]
        local square = cell:getGridSquare(point.x, point.y, point.z)
        if square then
            Internal.forEachCorpse(square, function(candidate)
                local modData = candidate.getModData
                    and candidate:getModData() or nil
                local markerId = modData and (
                    modData.PNC_DeathMarkerID or modData.PNC_UUID
                ) or nil
                local token = modData and modData.PNC_CorpseToken or nil
                if not accepted
                    and tostring(markerId or "") == tostring(record.id)
                    and (not expectedToken or not token
                        or tostring(token) == tostring(expectedToken))
                then
                    accepted = candidate
                end
            end)
        end
        if accepted then break end
    end
    return accepted
end

local function matchesCorpseShell(record, zombie)
    local modData = zombie and zombie.getModData
        and zombie:getModData() or nil
    local markerID = modData and (modData.PNC_UUID
        or modData.PNC_DeathMarkerID) or nil
    return markerID ~= nil
        and tostring(markerID) == tostring(record and record.id or "")
        and tostring(modData.PNC_BodyKind or "") == "corpse"
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
    modData.PNC_Owner = nil
    modData.PNC_OwnerVersion = nil
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

function Lifecycle.CreateVanillaCorpse(record, zombie, reason, deathContext)
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
    local factionID
    local factionName
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
        local identityItemsRemoved = Internal.removeManagedIdentityItems
            and Internal.removeManagedIdentityItems(existing) or 0
        local _, _, _, identityChanged =
            Internal.ensureCorpseIdentityCard(record, existing)
        local dogTagChanged = false
        if Internal.ensureCorpseFactionDogTag then
            local _, _, _, changed =
                Internal.ensureCorpseFactionDogTag(record, existing)
            dogTagChanged = changed == true
        end
        if identityItemsRemoved > 0 or identityChanged or dogTagChanged then
            Internal.transmitCorpseState(existing)
        end
        Internal.stampCorpse(record, existing, token)
        Internal.clearBodyCombat(zombie)
        Internal.removeZombie(zombie)
        record.presenceState = Const.PRESENCE_CORPSE
        Internal.detachLiveBody(record, reason or "death")
        Internal.mark(record, "corpse", "inert_loaded", reason or "death")
        runtime.corpseState = "inert_loaded"
        if PNC.CorpseAwareness
            and PNC.CorpseAwareness.ObserveCorpse
        then
            PNC.CorpseAwareness.ObserveCorpse(
                record,
                existing,
                deathContext
            )
        end
        return true, existing
    end
    if runtime.corpseState == "finalizing"
        or runtime.corpseState == "inert_loaded"
    then
        -- Reanimation/recovery can hand the authority a transient zombie at
        -- the new square while the real corpse remains at its saved square.
        -- If lookup missed both objects, retire only a body explicitly tagged
        -- to this corpse (or the still-leased live body), never an unrelated
        -- zombie. Leaving this shell alive causes weapon-state flicker and
        -- duplicate nameplate/body entries.
        if (Internal.matchesRecordBody
                and Internal.matchesRecordBody(record, zombie))
            or matchesCorpseShell(record, zombie)
        then
            Internal.clearBodyCombat(zombie)
            Internal.removeZombie(zombie)
            runtime.corpseState = "missing"
            Internal.mark(record, "corpse", "missing",
                "stale_corpse_shell_removed")
        end
        return true, nil
    end
    x = zombie.getX and zombie:getX() or record.x
    y = zombie.getY and zombie:getY() or record.y
    z = zombie.getZ and zombie:getZ() or record.z
    token = record.corpse and record.corpse.token
        or record.corpseToken or Core.GenerateID("corpse")
    createdWorldHour = record.corpse and tonumber(record.corpse.createdWorldHour) or Internal.worldHour()
    factionID, factionName = corpseFactionSnapshot(record)
    record.x = x
    record.y = y
    record.z = z
    record.corpse = {
        token = token,
        x = x,
        y = y,
        z = z,
        createdWorldHour = createdWorldHour,
        identityName = tostring(record.name or record.displayName
            or "Unknown NPC"),
        factionID = factionID,
        factionName = factionName,
    }
    if zombie.setReanimate then
        zombie:setReanimate(false)
    end
    if zombie.setReanim then
        zombie:setReanim(false)
    end
    Internal.clearBodyCombat(zombie)
    if Internal.removeManagedIdentityItems then
        Internal.removeManagedIdentityItems(zombie)
    end
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
        if Internal.removeManagedIdentityItems then
            Internal.removeManagedIdentityItems(corpse)
        end
        Internal.ensureCorpseIdentityCard(record, corpse)
        if Internal.ensureCorpseFactionDogTag then
            Internal.ensureCorpseFactionDogTag(record, corpse)
        end
        Internal.applyCorpseWornItems(corpse, wornEntries)
        Internal.stampCorpse(record, corpse, token)
        Internal.mark(record, "corpse", "inert_loaded", reason or "death")
        Internal.announceCorpse(corpse)
        if PNC.CorpseAwareness
            and PNC.CorpseAwareness.ObserveCorpse
        then
            PNC.CorpseAwareness.ObserveCorpse(
                record,
                corpse,
                deathContext
            )
        end
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
