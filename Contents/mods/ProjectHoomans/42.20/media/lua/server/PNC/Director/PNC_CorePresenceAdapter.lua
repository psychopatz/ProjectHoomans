-- Project Hoomans physical-provider adapter for Core SurvivorWorld presence.
-- Core owns the debug setting, session ledger, and canonical lease. Hoomans
-- owns only its record/body lifecycle and the provider-specific rollback.

if not PsychopatzCore
    or not PsychopatzCore.RuntimeRole
    or not PsychopatzCore.RuntimeRole.AllowsServerCode()
then
    return
end

PNC = PNC or {}

local Presence = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldPresence"
local CoreProvider = PNC.Persistence and PNC.Persistence.CoreProvider
local PROVIDER_ID = "ProjectHoomans"
local OWNER = "ProjectHoomans:core_presence_debug"

local function actors(core)
    return core and core.Actors or PsychopatzCore.Actors
end

local function registry(core)
    local service = actors(core)
    return service and service.DefaultRegistry or nil
end

local function actorID(actor)
    return tostring(actor and (actor.actorId or actor.actorID) or "")
end

local function recordFor(id)
    return PNC.Registry
        and type(PNC.Registry.Get) == "function"
        and PNC.Registry.Get(id) or nil
end

local function bodyID(body)
    if not body then return nil end
    if type(body.getPersistentOutfitID) == "function" then
        local value = body:getPersistentOutfitID()
        if value ~= nil and tostring(value) ~= "0" then
            return tostring(value)
        end
    end
    if type(body.getOnlineID) == "function" then
        local value = body:getOnlineID()
        if value ~= nil and tonumber(value) and tonumber(value) >= 0 then
            return tostring(value)
        end
    end
    return tostring(body.bodyID or body.bodyId or body.id or "") ~= ""
        and tostring(body.bodyID or body.bodyId or body.id) or nil
end

local function restoreLease(reg, actor, original)
    if not reg or not actor or type(original) ~= "table" then
        return nil, "provider_restore_input_required"
    end
    local Provider = actors(PsychopatzCore).Provider
    local lease, reason = Provider.Normalize(original, actorID(actor))
    if not lease then return nil, reason end
    return reg:Commit(actorID(actor), {
        providerLease = lease,
    }, actor.revision)
end

local function switchToProvider(reg, actor, spec)
    spec = type(spec) == "table" and spec or {}
    local lease = actor.providerLease or {}
    if lease.state == "materialized" then
        return nil, "body_lease_active"
    end
    if lease.state == "abstract" and lease.provider == PROVIDER_ID
        and tostring(lease.owner or "") == tostring(spec.owner or OWNER)
    then
        return actor
    end
    local transition = {
        provider = PROVIDER_ID,
        owner = spec.owner or OWNER,
        handoffFrom = lease.owner,
        authority = "server",
        now = spec.now,
    }
    if lease.state == "released" then
        return reg:AcquireProvider(actorID(actor), transition)
    end
    return reg:SwitchProvider(actorID(actor), transition)
end

local function clearDebugFlags(record)
    if not record then return end
    record.runtime = record.runtime or {}
    record.runtime.forceLive = nil
    record.runtime.forceAbstract = nil
    record.runtime.hardAbstract = nil
    record.runtime.debugPresenceOverride = nil
end

local function hydrate(actor, core)
    local record = recordFor(actorID(actor))
    if record then return record, "existing" end
    if CoreProvider and type(CoreProvider.PromoteCoreActor) == "function" then
        return CoreProvider.PromoteCoreActor(actor, core, {
            reason = "core_debug_force_live",
        })
    end
    if CoreProvider and type(CoreProvider.HydrateCoreActor) == "function" then
        return CoreProvider.HydrateCoreActor(actor, core)
    end
    return nil, "core_provider_unavailable"
end

local function canForceLive(actor, core)
    if recordFor(actorID(actor)) ~= nil then return true end
    if CoreProvider and type(CoreProvider.CanPromoteCoreActor) == "function" then
        return CoreProvider.CanPromoteCoreActor(actor, core) == true
    end
    return false
end

local function rollbackDebugPromotion(record, promoteStatus, core, reason)
    if promoteStatus == "created"
        and record
        and record.coreBacked == true
        and CoreProvider
        and type(CoreProvider.DemoteCoreActor) == "function"
    then
        CoreProvider.DemoteCoreActor(record, core, {
            force = true,
            reason = reason or "core_debug_force_live_rollback",
        })
    end
end

local function forceLive(actor, core, spec)
    spec = type(spec) == "table" and spec or {}
    local reg = registry(core)
    local original = actor and actor.providerLease
    local current
    local record
    local promoteStatus
    local body
    local reason
    local id = actorID(actor)
    if not reg or id == "" then return nil, "core_actor_registry_unavailable" end

    current, reason = switchToProvider(reg, actor, spec)
    if not current then return nil, reason end
    record, promoteStatus = hydrate(current, core)
    if not record then
        restoreLease(reg, reg:Get(id) or current, original)
        return nil, promoteStatus or "hoomans_record_unavailable"
    end
    record.runtime = record.runtime or {}
    record.runtime.forceLive = true
    record.runtime.forceAbstract = nil
    record.runtime.hardAbstract = nil
    record.runtime.debugPresenceOverride = true

    if record.presenceState == PNC.Const.PRESENCE_LIVE
        and PNC.Registry.GetLiveZombie
    then
        body = PNC.Registry.GetLiveZombie(id)
    else
        body, reason = PNC.Presence.Materialize(
            record,
            spec.reason or "core_debug_force_live"
        )
    end
    if not body then
        clearDebugFlags(record)
        rollbackDebugPromotion(record, promoteStatus, core, "core_debug_materialize_failed")
        restoreLease(reg, reg:Get(id) or current, original)
        return nil, reason or "hoomans_materialize_failed"
    end

    local idValue = bodyID(body)
    if not idValue then
        PNC.Presence.Abstract(record, "core_debug_body_id_missing")
        clearDebugFlags(record)
        rollbackDebugPromotion(record, promoteStatus, core, "core_debug_body_id_missing")
        restoreLease(reg, reg:Get(id) or current, original)
        return nil, "hoomans_body_id_missing"
    end

    local committed
    committed, reason = reg:MaterializeProvider(id, {
        provider = PROVIDER_ID,
        owner = spec.owner or OWNER,
        bodyID = idValue,
        authority = "server",
        now = spec.now,
    })
    if not committed then
        PNC.Presence.Abstract(record, "core_debug_lease_commit_failed")
        clearDebugFlags(record)
        rollbackDebugPromotion(record, promoteStatus, core, "core_debug_lease_commit_failed")
        restoreLease(reg, reg:Get(id) or current, original)
        return nil, reason or "hoomans_provider_commit_failed"
    end
    return {
        actor = committed,
        record = record,
        body = body,
        bodyID = idValue,
    }
end

local function release(actor, core, spec)
    spec = type(spec) == "table" and spec or {}
    local reg = registry(core)
    local id = actorID(actor)
    local record = recordFor(id)
    local lease = actor and actor.providerLease or {}
    local reason
    if not reg or id == "" then return nil, "core_actor_registry_unavailable" end
    if not record then return nil, "hoomans_record_unavailable" end

    if record.presenceState == PNC.Const.PRESENCE_LIVE then
        local released = PNC.Presence.Abstract(
            record,
            spec.reason or "core_debug_force_abstract"
        )
        if released == false or record.presenceState == PNC.Const.PRESENCE_LIVE then
            return nil, "hoomans_body_release_failed"
        end
    end
    clearDebugFlags(record)

    local dematerialized
    dematerialized, reason = reg:DematerializeProvider(id, {
        provider = PROVIDER_ID,
        owner = lease.owner or OWNER,
        bodyID = lease.bodyID,
        authority = "server",
        now = spec.now,
    })
    if not dematerialized then return nil, reason end

    local inventory
    if CoreProvider and type(CoreProvider.CaptureInventory) == "function" then
        inventory = CoreProvider.CaptureInventory(dematerialized, record)
    end
    if type(inventory) == "table" then
        local updated
        updated, reason = reg:Commit(id, {
            providerLease = dematerialized.providerLease,
            personalInventory = inventory,
        }, dematerialized.revision)
        if not updated then return nil, reason end
        dematerialized = updated
    end

    local demoted = false
    if record.coreBacked == true
        and CoreProvider
        and type(CoreProvider.HasActiveHoomansResponsibility) == "function"
        and type(CoreProvider.DemoteCoreActor) == "function"
    then
        local nowMs = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
        if not CoreProvider.HasActiveHoomansResponsibility(
            record, nowMs, { ignoreGrace = true }
        ) then
            demoted = CoreProvider.DemoteCoreActor(record, core, {
                force = true,
                reason = spec.reason or "core_presence_release",
            }) == true
        end
    end

    return {
        actor = reg:Get(id) or dematerialized,
        record = demoted and nil or record,
        demoted = demoted,
    }
end

Presence.RegisterProvider(PROVIDER_ID, {
    priority = 100,
    canForceLive = canForceLive,
    forceLive = forceLive,
    release = release,
})

return true
