-- Vanilla corpse conversion, delayed finalization, and marker stamping.

PNC = PNC or {}
PNC.BodyLifecycle = PNC.BodyLifecycle or {}
PNC.BodyLifecycle.Internal = PNC.BodyLifecycle.Internal or {}

local Lifecycle = PNC.BodyLifecycle
local Internal = Lifecycle.Internal
local Core = PNC.Core
local Const = PNC.Const

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

function Lifecycle.CreateVanillaCorpse(record, zombie, reason)
    local x
    local y
    local z
    local token
    local createdWorldHour
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
        zombie:setReanimate(false)
    end
    if zombie.setReanim then
        zombie:setReanim(false)
    end
    Internal.clearBodyCombat(zombie)
    Internal.prepareCorpseItems(record, zombie)
    sourceWornItems = zombie.getWornItems and zombie:getWornItems() or nil
    wornEntries = Internal.captureWornEntries(sourceWornItems)
    -- Use the character death path first. On a multiplayer server this invokes
    -- the engine's zombie-death networking and gives every client the same
    -- corpse object ID. Constructing IsoDeadBody directly removes the source
    -- zombie locally but does not emit that death packet, leaving clients with
    -- either no corpse or an orphan corpse that reanimation cannot consume.
    if zombie.becomeCorpseSilently then
        corpse = zombie:becomeCorpseSilently()
        converted = true
    end
    -- Retain direct construction only as a compatibility fallback for engine
    -- objects that do not expose the normal conversion method or reject it.
    if not converted and IsoDeadBody and IsoDeadBody.new then
        corpse = IsoDeadBody.new(zombie, false, true)
        converted = corpse ~= nil
    end
    if not corpse then
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
        -- IsoDeadBody conversion can discard a source-body item on fallback
        -- engine paths. Guarantee the stable quest identity on the final
        -- vanilla-owned container before the one complete-corpse MP sync.
        Internal.ensureCorpseIdentityCard(record, corpse)
        Internal.applyCorpseWornItems(corpse, wornEntries)
        Internal.stampCorpse(record, corpse, token)
        Internal.transmitCorpseState(corpse)
        Internal.ensureRuntime(record).corpseState = "inert_loaded"
    end
    return converted, corpse
end

-- Compatibility for integrations written before engine-owned corpse handoff.
Lifecycle.CreateInertCorpse = Lifecycle.CreateVanillaCorpse
