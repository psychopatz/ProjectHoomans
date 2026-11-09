-- Optional adapter for Core-owned provider leases. Project Hoomans keeps its
-- existing record, presence, and body lifecycle ownership; this adapter maps
-- the canonical Core projection into that lifecycle and back to a lease.

PNC = PNC or {}
PNC.Persistence = PNC.Persistence or {}

local Persistence = PNC.Persistence
local Adapter = Persistence.CoreProvider or {}
Persistence.CoreProvider = Adapter
local ActorInventoryBridge =
    require "PNC/Core/Inventory/PNC_Inventory/Persistence/PNC_Inventory_ActorBridge"

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

local ACTOR_IDENTITY_EXTENSION = "PsychopatzCore.ActorIdentity"
local AFFILIATION_EXTENSION = "PsychopatzCore.SurvivorWorld"

local function recordAffiliation(record)
    local source = type(record) == "table" and record or {}
    local affiliation = type(source.affiliation) == "table"
        and source.affiliation or {}
    local factionID = source.factionID or source.factionId
        or affiliation.factionID or affiliation.factionId
    local communityID = source.communityID or source.communityId
        or affiliation.communityID or affiliation.communityId
    local groupID = source.groupID or source.groupId
        or affiliation.groupID or affiliation.groupId
    local output = {
        factionID = factionID,
        factionName = source.factionName or affiliation.factionName,
        factionArchetypeID = source.factionArchetypeID
            or affiliation.factionArchetypeID,
        communityID = communityID,
        groupID = groupID,
        role = source.factionRole or source.role or affiliation.role,
    }
    if output.factionID == nil and output.communityID == nil
        and output.groupID == nil
    then
        return nil
    end
    return output
end

local function affiliationChanged(previous, next)
    for _, key in ipairs({
        "factionID", "factionName", "factionArchetypeID", "communityID",
        "groupID", "role",
    }) do
        if next[key] ~= nil and tostring(previous[key] or "")
            ~= tostring(next[key])
        then
            return true
        end
    end
    return false
end

-- Reconcile only records that already identify a Core actor (or use the same
-- stable ID). This is deliberately not a PNC-to-Core actor factory: ordinary
-- Hoomans records must opt into canonical Core ownership through a later,
-- explicit adoption pass rather than silently creating duplicate actors.
function Adapter.AnnotateExistingCoreRecord(record, core)
    if type(record) ~= "table" or type(core) ~= "table" then
        return nil, "record_and_core_required"
    end
    local api = actors(core)
    if not api or type(api.Resolve) ~= "function"
        or type(api.AttachIdentity) ~= "function"
    then
        return nil, "core_actor_identity_api_unavailable"
    end

    local runtime = type(record.runtime) == "table" and record.runtime or {}
    local reference = record.coreActorID or runtime.coreActorID or record.id
    local actor = api.Resolve(reference)
    if not actor then return nil, "core_actor_not_found" end
    local canonicalID = tostring(actor.actorId or actor.actorID or "")
    if canonicalID == "" then return nil, "core_actor_id_missing" end

    local currentIdentity = type(actor.extensions) == "table"
        and actor.extensions[ACTOR_IDENTITY_EXTENSION] or nil
    local hasRecordAlias = false
    local identityChanged = false
    local recordChanged = false
    for _, alias in ipairs(currentIdentity and currentIdentity.aliases or {}) do
        if tostring(alias) == tostring(record.id) then
            hasRecordAlias = true
            break
        end
    end
    local lease = actor.providerLease or {}
    local identityPatch = {}
    if record.id and tostring(record.id) ~= canonicalID
        and not hasRecordAlias
    then
        identityPatch.aliases = { tostring(record.id) }
        identityChanged = true
    end
    if type(currentIdentity) ~= "table"
        or currentIdentity.project ~= true
        or (not currentIdentity.providerID and lease.provider)
    then
        identityPatch.project = true
        if lease.provider then identityPatch.providerID = lease.provider end
        identityChanged = true
    end
    if identityChanged then
        local updated, reason = api.AttachIdentity(canonicalID, identityPatch)
        if not updated then return nil, reason end
        recordChanged = true
    end

    local affiliation = recordAffiliation(record)
    local currentAffiliation = type(actor.extensions) == "table"
        and actor.extensions[AFFILIATION_EXTENSION] or {}
    if affiliation and type(api.AttachExtension) == "function"
        and affiliationChanged(currentAffiliation, affiliation)
    then
        local updated, reason = api.AttachExtension(
            canonicalID,
            AFFILIATION_EXTENSION,
            affiliation
        )
        if not updated then return nil, reason end
        recordChanged = true
    end

    if tostring(record.coreActorID or "") ~= canonicalID
        or tostring(runtime.coreActorID or "") ~= canonicalID
    then
        recordChanged = true
    end
    record.coreActorID = canonicalID
    record.runtime = runtime
    record.runtime.coreActorID = canonicalID
    if recordChanged and PNC.Registry
        and type(PNC.Registry.MarkDirty) == "function"
    then
        PNC.Registry.MarkDirty(record, "core_actor_identity")
    end
    return true, recordChanged and canonicalID or "unchanged"
end

function Adapter.ReconcileExistingCoreRecords(core)
    if not PNC.Registry or type(PNC.Registry.ForEach) ~= "function" then
        return 0, "registry_unavailable"
    end
    local reconciled = 0
    PNC.Registry.ForEach(function(record)
        local ok = Adapter.AnnotateExistingCoreRecord(record, core)
        if ok then reconciled = reconciled + 1 end
    end)
    return reconciled, "reconciled"
end

local function projectProviderLease(record, leaseID)
    record.runtime.coreProviderLease = leaseID
    -- Provider ownership may outlive several physical MP shells. Only
    -- BodyLifecycle assigns the physical incarnation on an MP server.
    if not isServer or isServer() ~= true then record.runtime.bodyLease = leaseID end
end

local function buildRecord(actor, baseRecord)
    local record = type(baseRecord) == "table" and baseRecord or nil
    if not record and actor and PNC.Registry
        and type(PNC.Registry.Get) == "function"
    then
        record = PNC.Registry.Get(actor.actorId)
    end
    record = type(record) == "table" and record or {}
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
    projectProviderLease(record, lease.leaseID)
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

-- Core-owned actors enter Project Hoomans through this adapter instead of the
-- normal Presence.Materialize path. Keep that provider handoff on the same
-- presentation contract as every other live NPC: the body factory only
-- creates a managed shell; animation, human visuals, inventory, equipment,
-- and the lifecycle token still have to be applied before registration.
local function configureMaterializedBody(record, body, lifecycle)
    local inventoryOK
    local inventoryReason
    local token
    local tokenReason
    if not record or not body then
        return nil, "materialized_body_configuration_input_required"
    end
    if body.DoZombieStats then body:DoZombieStats() end
    record.runtime = record.runtime or {}
    record.runtime.target = nil

    if PNC.Animation and PNC.Animation.ApplyLiveSetup then
        PNC.Animation.ApplyLiveSetup(body, record)
    end
    if PNC.Visuals and PNC.Visuals.ApplyHumanVisuals then
        PNC.Visuals.ApplyHumanVisuals(body, record)
    end

    if type(body.getInventory) == "function"
        and PNC.Inventory
        and type(PNC.Inventory.MaterializeLooseInventory) == "function"
    then
        inventoryOK, inventoryReason =
            PNC.Inventory.MaterializeLooseInventory(record, body)
        if not inventoryOK then
            return nil, inventoryReason
                or "physical_inventory_materialize_failed"
        end
    end

    if PNC.Equipment and PNC.Equipment.Apply then
        PNC.Equipment.Apply(body, record)
    end
    if lifecycle and lifecycle.EnsureLiveShellIdentityToken then
        token, _, tokenReason = lifecycle.EnsureLiveShellIdentityToken(
            record, body)
        if not token
            and tokenReason ~= "not_authority"
            and Core and Core.LogWarn
        then
            Core.LogWarn("PNC live shell token unavailable npc="
                .. tostring(record.id)
                .. " reason=" .. tostring(tokenReason or "unknown"))
        end
    end
    if PNC.LiveBodyControl
        and PNC.LiveBodyControl.SetManagedBodyUseless
    then
        PNC.LiveBodyControl.SetManagedBodyUseless(body, true)
    end
    return true
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
    if projection.providerLease
        and projection.providerLease.state == "materialized"
    then
        return nil, "body_lease_active"
    end
    local hydratedInventory, hydrateReason =
        ActorInventoryBridge.HydrateRecord(record, projection)
    if not hydratedInventory then
        return nil, hydrateReason or "core_inventory_hydration_failed"
    end
    projectProviderLease(record, projection.providerLease.leaseID)
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
    local configured, configurationReason = configureMaterializedBody(
        record, body, lifecycle)
    if not configured then
        rollback = spec.cleanup or spec.destroy
        if type(rollback) == "function" then
            rollback(body, record, spec)
        end
        return nil, configurationReason
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
        authority = spec.authority,
        now = spec.now,
    })
    if not nextActor then
        rollback = spec.cleanup or spec.destroy
        if type(rollback) == "function" then rollback(body, record, spec) end
        return nil, reason
    end
    projectProviderLease(record, nextActor.providerLease.leaseID)
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
    local capturedInventory
    local captureMode
    if not service or type(service.Project) ~= "function"
        or type(service.Dematerialize) ~= "function"
    then
        return nil, "core_provider_unavailable"
    end
    spec = type(spec) == "table" and spec or {}
    record, projection = Adapter.BuildRecord(actor, core, spec.record)
    if not record then return nil, projection end
    if type(record.inventory) ~= "table" then
        local hydratedInventory
        local hydrateReason
        hydratedInventory, hydrateReason =
            ActorInventoryBridge.HydrateRecord(record, projection)
        if not hydratedInventory then
            return nil, hydrateReason
                or "core_inventory_hydration_failed"
        end
    end
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

    if body and type(body.getInventory) == "function"
        and PNC.Inventory
        and type(PNC.Inventory.CaptureLooseInventory) == "function"
    then
        local inventoryOK
        inventoryOK, reason = PNC.Inventory.CaptureLooseInventory(
            record, body)
        if not inventoryOK then
            return nil, reason or "physical_inventory_capture_failed"
        end
    end

    capturedInventory, captureMode, reason =
        ActorInventoryBridge.CaptureRecord(record, actor)
    if not capturedInventory then
        return nil, reason or captureMode
            or "core_inventory_capture_failed"
    end

    removed = remover(record, body, spec.reason or "core_provider_dematerialize")
    if removed == false then return nil, "body_release_failed" end

    nextActor, reason = service.Dematerialize(actor, {
        provider = "DTHoomans",
        owner = owner(spec),
        bodyID = spec.bodyID or projection.providerLease.bodyID,
        authority = spec.authority,
        now = spec.now,
    })
    if not nextActor then return nil, reason end
    nextActor.personalInventory = capturedInventory
    record.personalInventory = capturedInventory
    record.runtime.coreInventoryCapturedMode = captureMode
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

function Adapter.HydrateInventory(actor, record)
    return ActorInventoryBridge.HydrateRecord(record, actor)
end

function Adapter.CaptureInventory(actor, record)
    return ActorInventoryBridge.CaptureRecord(record, actor)
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

local function reconcileExistingCoreRecords()
    if isServer and isServer() ~= true then return end
    if PsychopatzCore then
        Adapter.ReconcileExistingCoreRecords(PsychopatzCore)
    end
end

if Events and Events.OnInitGlobalModData
    and type(Events.OnInitGlobalModData.Add) == "function"
    and not Adapter.ReconcileInitHookRegistered
then
    Adapter.ReconcileInitHookRegistered = true
    Events.OnInitGlobalModData.Add(reconcileExistingCoreRecords)
end

if Events and Events.OnServerStarted
    and type(Events.OnServerStarted.Add) == "function"
    and not Adapter.ReconcileServerHookRegistered
then
    Adapter.ReconcileServerHookRegistered = true
    Events.OnServerStarted.Add(reconcileExistingCoreRecords)
end

return Adapter
