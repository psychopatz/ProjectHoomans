-- Optional adapter for Core-owned provider leases. Project Hoomans keeps its
-- existing record, presence, and body lifecycle ownership; this adapter maps
-- the canonical Core projection into that lifecycle and back to a lease.

PNC = PNC or {}
PNC.Persistence = PNC.Persistence or {}

local Persistence = PNC.Persistence
local Adapter = Persistence.CoreProvider or {}
Persistence.CoreProvider = Adapter

local function actors(core)
    return core and core.Actors
end

local function provider(core)
    local service = actors(core)
    return service and service.Provider
end

local function owner(spec)
    return type(spec) == "table" and spec.owner or "ProjectHoomans"
end

local function displayName(actor)
    local identity = actor and actor.identity or {}
    local survivor = identity.survivor or {}
    return tostring(identity.displayName or (
        tostring(survivor.forename or "NPC") .. " "
            .. tostring(survivor.surname or "")))
end

local function position(actor)
    local world = actor and actor.world or {}
    local location = world.location or {}
    local point = location.position or {}
    return {
        x = tonumber(point.x) or 0,
        y = tonumber(point.y) or 0,
        z = tonumber(point.z) or 0,
    }
end

local function buildRecord(actor, baseRecord)
    local record = type(baseRecord) == "table" and baseRecord or {}
    local lease = actor and actor.providerLease or {}
    local point = position(actor)
    record.id = tostring(actor.actorId)
    record.name = displayName(actor)
    record.displayName = record.name
    record.identity = actor.identity
    record.appearance = actor.appearance
    record.social = actor.social
    record.personalInventory = actor.personalInventory
    record.coreActorID = tostring(actor.actorId)
    record.x = point.x
    record.y = point.y
    record.z = point.z
    record.runtime = record.runtime or {}
    record.runtime.coreActorID = tostring(actor.actorId)
    record.runtime.bodyLease = lease.leaseID
    record.runtime.coreProvider = lease.provider
    return record
end

local function bodyID(body, spec)
    local value = type(spec) == "table" and (spec.bodyID or spec.bodyId)
        or nil
    if value ~= nil and tostring(value) ~= "" and tostring(value) ~= "0" then
        return tostring(value)
    end
    if type(spec) == "table" and type(spec.bodyIDFor) == "function" then
        value = spec.bodyIDFor(body)
        if value ~= nil and tostring(value) ~= ""
            and tostring(value) ~= "0"
        then return tostring(value) end
    end
    if type(body) == "table" then
        value = body.bodyID or body.bodyId or body.id
        if value ~= nil and tostring(value) ~= "" then
            return tostring(value)
        end
        if type(body.getPersistentOutfitID) == "function" then
            value = body:getPersistentOutfitID()
            if value ~= nil and tostring(value) ~= "0" then
                return tostring(value)
            end
        end
        if type(body.getOnlineID) == "function" then
            value = body:getOnlineID()
            if value ~= nil and tonumber(value) and tonumber(value) >= 0 then
                return tostring(value)
            end
        end
    end
    return nil
end

function Adapter.BuildRecord(actor, core, baseRecord)
    local service = provider(core)
    if not service or type(service.Project) ~= "function" then
        return nil, "core_provider_unavailable"
    end
    local projection, reason = service.Project(actor)
    if not projection then return nil, reason end
    return buildRecord(projection, baseRecord), projection
end

function Adapter.Project(actor, core)
    local service = provider(core)
    if not service or type(service.Project) ~= "function" then
        return nil, "core_provider_unavailable"
    end
    return service.Project(actor)
end

function Adapter.Acquire(actor, core, spec)
    local service = provider(core)
    if not service or type(service.Acquire) ~= "function" then
        return nil, "core_provider_unavailable"
    end
    spec = type(spec) == "table" and spec or {}
    spec.provider = "DTHoomans"
    spec.owner = owner(spec)
    return service.Acquire(actor, spec)
end

function Adapter.Materialize(actor, core, spec)
    local service = provider(core)
    local record
    local projection
    local reason
    local lifecycle
    local factory
    local body
    local bodyReason
    local id
    local nextActor
    local rollback
    if not service or type(service.Project) ~= "function"
        or type(service.Materialize) ~= "function"
    then
        return nil, "core_provider_unavailable"
    end
    spec = type(spec) == "table" and spec or {}
    record, projection = Adapter.BuildRecord(actor, core, spec.record)
    if not record then return nil, projection end
    record.runtime.bodyLease = projection.providerLease.leaseID
    lifecycle = spec.lifecycle or PNC.BodyLifecycle
    factory = spec.bodyFactory or spec.spawn
    if type(factory) ~= "function" and lifecycle
        and type(lifecycle.SpawnLiveBody) == "function"
    then
        factory = lifecycle.SpawnLiveBody
    end
    if type(factory) ~= "function" then return nil, "body_factory_required" end
    body, bodyReason = factory(
        record,
        spec.position or position(actor),
        spec.reason or "core_provider_materialize"
    )
    if not body then return nil, bodyReason or "body_spawn_failed" end
    id = bodyID(body, spec)
    if not id then
        rollback = spec.cleanup or spec.destroy
        if type(rollback) == "function" then rollback(body, record, spec) end
        return nil, "body_id_required"
    end
    if type(spec.applyProjection) == "function" then
        local applied = spec.applyProjection(body, projection, record)
        if applied == false then
            rollback = spec.cleanup or spec.destroy
            if type(rollback) == "function" then rollback(body, record, spec) end
            return nil, "body_projection_rejected"
        end
    end

    nextActor, reason = service.Materialize(actor, {
        provider = "DTHoomans",
        owner = owner(spec),
        bodyID = id,
        now = spec.now,
    })
    if not nextActor then
        rollback = spec.cleanup or spec.destroy
        if type(rollback) == "function" then rollback(body, record, spec) end
        return nil, reason
    end
    record.runtime.bodyLease = nextActor.providerLease.leaseID
    if lifecycle and type(lifecycle.StampLiveBody) == "function" then
        lifecycle.StampLiveBody(record, body)
    end
    if spec.registerBody == true and PNC.Registry
        and type(PNC.Registry.RegisterLiveZombie) == "function"
    then
        PNC.Registry.RegisterLiveZombie(record, body)
    end
    return {
        actor = nextActor,
        record = record,
        projection = service.Project(nextActor),
        body = body,
        bodyID = id,
        leaseID = nextActor.providerLease.leaseID,
    }
end

function Adapter.Dematerialize(actor, core, spec)
    local service = provider(core)
    local record
    local projection
    local reason
    local lifecycle
    local body
    local remover
    local removed
    local nextActor
    if not service or type(service.Project) ~= "function"
        or type(service.Dematerialize) ~= "function"
    then
        return nil, "core_provider_unavailable"
    end
    spec = type(spec) == "table" and spec or {}
    record, projection = Adapter.BuildRecord(actor, core, spec.record)
    if not record then return nil, projection end
    body = spec.body
    if not body and PNC.Registry
        and type(PNC.Registry.GetLiveZombie) == "function"
    then
        body = PNC.Registry.GetLiveZombie(actor.actorId)
    end
    if not body then return nil, "body_required" end
    lifecycle = spec.lifecycle or PNC.BodyLifecycle
    remover = spec.removeBody or spec.destroy
    if type(remover) ~= "function" and lifecycle
        and type(lifecycle.RemoveLiveBody) == "function"
    then
        remover = lifecycle.RemoveLiveBody
    end
    if type(remover) ~= "function" then return nil, "body_remover_required" end
    removed = remover(record, body, spec.reason or "core_provider_dematerialize")
    if removed == false then return nil, "body_release_failed" end

    nextActor, reason = service.Dematerialize(actor, {
        provider = "DTHoomans",
        owner = owner(spec),
        bodyID = spec.bodyID or projection.providerLease.bodyID,
        now = spec.now,
    })
    if not nextActor then return nil, reason end
    record.runtime.bodyLease = nil
    record.runtime.coreProvider = "DTHoomans"
    return {
        actor = nextActor,
        record = record,
        projection = service.Project(nextActor),
        body = body,
        bodyID = projection.providerLease.bodyID,
        leaseID = nextActor.providerLease.leaseID,
    }
end

function Adapter.Release(actor, core, spec)
    local service = provider(core)
    if not service or type(service.Release) ~= "function" then
        return nil, "core_provider_unavailable"
    end
    spec = type(spec) == "table" and spec or {}
    spec.provider = "DTHoomans"
    spec.owner = owner(spec)
    return service.Release(actor, spec)
end

return Adapter
