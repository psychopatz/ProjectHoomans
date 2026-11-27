-- Optional adapter for Core-owned provider leases. Project Hoomans keeps its
-- existing record, presence, and body lifecycle ownership; this adapter maps
-- the canonical Core projection into that lifecycle and back to a lease.

PNC = PNC or {}
PNC.Persistence = PNC.Persistence or {}

local Persistence = PNC.Persistence
local Adapter = Persistence.CoreProvider or {}
Persistence.CoreProvider = Adapter
local Types = PNC.Types
local OptionalPolicy = PNC.OptionalProviderPolicy
local ActorInventoryBridge =
    require "PNC/Core/Inventory/PNC_Inventory/Persistence/PNC_Inventory_ActorBridge"
local CoreActorExtension =
    require "PNC/Core/Persistence/PNC_CoreActorExtension"
local Json = require "PsychopatzCore/Serialization/PsychopatzJson"

local OUTCOME_WRITTEN = Persistence.OUTCOME_WRITTEN or "WRITTEN"
local OUTCOME_TERMINAL =
    Persistence.OUTCOME_TERMINAL or "TERMINAL_OR_NOT_APPLICABLE"
local OUTCOME_RETRYABLE =
    Persistence.OUTCOME_RETRYABLE or "RETRYABLE_FAILURE"

Adapter.Metrics = Adapter.Metrics or {
    promotions = 0,
    demotions = 0,
    syncs = 0,
    startupRestores = 0,
    demotePumps = 0,
}
Adapter.LastDemotePumpAt = tonumber(Adapter.LastDemotePumpAt) or 0

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

local function providerID(spec)
    local value = type(spec) == "table" and spec.provider or nil
    value = tostring(value or "")
    return value ~= "" and value or "ProjectHoomans"
end

local function survivorWorldPresence()
    local presence = PsychopatzCore
        and PsychopatzCore.SurvivorWorldPresence or nil
    if not presence then
        presence = require
            "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldPresence"
    end
    return presence
end

local function ensureAbstractLease(actor, record)
    local lease = actor and actor.providerLease or {}
    if lease.state ~= "released" then return actor end

    local runtime = type(record.runtime) == "table" and record.runtime or {}
    local requested = tostring(runtime.coreProvider or "")
    if requested ~= "DTAbstract" and requested ~= "ProjectHoomans" then
        requested = "ProjectHoomans"
    end
    local adopted, reason = survivorWorldPresence().EnsureAbstract(
        actor.actorId,
        {
            provider = requested,
            owner = requested .. ":abstract",
            now = PNC.Core.Now(),
        }
    )
    if not adopted then return nil, reason end
    return adopted
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

local function cloneTable(value)
    if PNC.Core and type(PNC.Core.DeepCopy) == "function" then
        return PNC.Core.DeepCopy(value)
    end
    if type(value) ~= "table" then return value end
    local out = {}
    for k, v in pairs(value) do
        out[k] = cloneTable(v)
    end
    return out
end

local function tablesEqual(left, right)
    if left == right then return true end
    if type(left) ~= type(right) then return false end
    if type(left) ~= "table" then return false end
    for k, v in pairs(left) do
        if not tablesEqual(v, right[k]) then return false end
    end
    for k, _ in pairs(right) do
        if left[k] == nil then return false end
    end
    return true
end

local function recordAffiliation(source)
    local affiliation = type(source.affiliation) == "table"
        and cloneTable(source.affiliation) or {}
    -- A normalized Hoomans affiliation can explicitly clear membership.
    -- Older/provider records may only have the denormalized fields.
    if not affiliation.membershipStatus then
        affiliation.factionID = affiliation.factionID or source.factionID
        affiliation.communityID = affiliation.communityID or source.communityID
        affiliation.role = affiliation.role or source.factionRole or source.role
    end
    affiliation.groupID = source.groupID or affiliation.groupID
    if not (affiliation.factionID or affiliation.communityID or affiliation.groupID)
        and affiliation.membershipStatus ~= "unaffiliated"
    then
        return nil
    end
    if affiliation.factionID then
        affiliation.factionName = source.factionName or affiliation.factionName
        affiliation.factionArchetypeID =
            source.factionArchetypeID or affiliation.factionArchetypeID
    end
    return affiliation
end

-- Reconcile Hoomans records against the canonical Core actor registry. The
-- stable Hoomans record ID is the adoption key; Core's idempotent Ensure seam
-- prevents a reload or provider hot-plug from replacing an enriched actor.
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
    if record.coreBacked ~= true and affiliation
        and (affiliation.factionID or affiliation.communityID or affiliation.groupID)
        and currentAffiliation.factionID == nil
        and currentAffiliation.communityID == nil
        and currentAffiliation.groupID == nil
        and type(api.AttachExtension) == "function"
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
    if record.coreBacked ~= true or record.persistenceAuthority ~= "core_extension" then
        recordChanged = true
    end
    record.coreBacked = true
    record.persistenceAuthority = "core_extension"
    record.coreActorID = canonicalID
    record.coreRevision = tonumber(actor.revision) or record.coreRevision
    record.runtime = runtime
    record.runtime.coreActorID = canonicalID
    local liveState = PNC.Const and PNC.Const.PRESENCE_LIVE or "live"
    local hasLiveBody = record.presenceState == liveState
        or (PNC.Registry and type(PNC.Registry.GetLiveZombie) == "function"
            and PNC.Registry.GetLiveZombie(record.id) ~= nil)
    local expectedPresence
    if lease.state == "materialized" then
        expectedPresence = liveState
    elseif lease.state == "abstract" and not hasLiveBody then
        expectedPresence = PNC.Const.PRESENCE_ABSTRACT
    end
    if expectedPresence ~= nil
        and record.presenceState ~= expectedPresence
    then
        record.presenceState = expectedPresence
        recordChanged = true
    end
    if recordChanged and PNC.Registry
        and type(PNC.Registry.MarkDirty) == "function"
    then
        PNC.Registry.MarkDirty(record, "core_actor_identity")
    end
    return true, recordChanged and canonicalID or "unchanged"
end

function Adapter.EnsureActor(record, core)
    if type(record) ~= "table" or type(core) ~= "table" then
        return nil, "record_and_core_required"
    end
    if not record.id or tostring(record.id) == "" then
        return nil, "record_id_required"
    end
    if record.coreBacked ~= true and record.persistenceSourceVersion ~= nil then
        return nil, "local_record_already_persisted"
    end

    local api = actors(core)
    if not api then return nil, "core_actor_api_unavailable" end

    local runtime = type(record.runtime) == "table" and record.runtime or {}
    local reference = record.coreActorID
        or runtime.coreActorID
        or record.id
    local actor = type(api.Resolve) == "function"
        and api.Resolve(reference) or nil
    if not actor and type(api.Get) == "function" then
        actor = api.Get(reference)
    end

    if not actor then
        local ensure = api.Ensure
        if type(ensure) ~= "function"
            and api.DefaultRegistry
            and type(api.DefaultRegistry.Ensure) == "function"
        then
            ensure = function(spec)
                return api.DefaultRegistry:Ensure(spec)
            end
        end
        if type(ensure) ~= "function" then
            return nil, "core_actor_ensure_unavailable"
        end

        local resolvedFemale = record.isFemale == true
            or (type(record.identity) == "table"
                and record.identity.isFemale == true)
        local rawAppearance
        if record.appearanceAuthored and type(record.appearance) == "table" then
            rawAppearance = record.appearance
        elseif type(record.runtime) == "table"
            and type(record.runtime.appearanceCache) == "table"
        then
            rawAppearance = record.runtime.appearanceCache
        elseif PNC.Identity and type(PNC.Identity.RollAppearance) == "function" then
            rawAppearance = PNC.Identity.RollAppearance(record)
        end
        local ensureAppearance
        if type(rawAppearance) == "table" then
            if type(rawAppearance.policy) == "table"
                or rawAppearance.schemaVersion ~= nil
            then
                ensureAppearance = rawAppearance
            else
                local resolvedCopy = cloneTable(rawAppearance)
                resolvedCopy.gender = resolvedCopy.gender
                    or (resolvedFemale and "female" or "male")
                local policySchema = (api.Factory
                    and tonumber(api.Factory.APPEARANCE_POLICY_SCHEMA)) or 2
                ensureAppearance = {
                    policy = {
                        schemaVersion = policySchema,
                        mode = "authored",
                        skinTexture = resolvedCopy.skinTexture,
                        skinColor = cloneTable(resolvedCopy.skinColor),
                        hairModel = resolvedCopy.hairModel,
                        hairColor = cloneTable(resolvedCopy.hairColor),
                        beardModel = resolvedCopy.beardModel,
                        hairStubble = resolvedCopy.hairStubble,
                        beardStubble = resolvedCopy.beardStubble,
                        chestHair = resolvedCopy.chestHair,
                        outfit = resolvedCopy.outfit,
                    },
                    resolved = resolvedCopy,
                }
            end
        end

        actor = ensure({
            actorId = tostring(record.id),
            ownerMod = "ProjectHoomans",
            identitySeed = record.identitySeed,
            identity = record.identity,
            isFemale = resolvedFemale,
            displayName = record.displayName or record.name,
            appearance = ensureAppearance,
            archetypeID = record.archetypeID or "core.survivor",
            world = {
                location = {
                    position = {
                        x = tonumber(record.x) or 0,
                        y = tonumber(record.y) or 0,
                        z = tonumber(record.z) or 0,
                    },
                },
            },
            source = {
                provider = "ProjectHoomans",
                recordID = tostring(record.id),
            },
        })
        if not actor then
            return nil, "core_actor_ensure_failed"
        end
    end

    local reason
    actor, reason = ensureAbstractLease(actor, record)
    if not actor then return nil, reason end

    local ok, result = Adapter.AnnotateExistingCoreRecord(record, core)
    if ok and PNC.Persistence and PNC.Persistence.CoreSocial then
        local coreSocial = PNC.Persistence.CoreSocial
        if type(coreSocial.SeedEmptyCoreSocial) == "function" then
            coreSocial.SeedEmptyCoreSocial(record, core)
        elseif type(coreSocial.EnsureRuntimeView) == "function" then
            coreSocial.EnsureRuntimeView(record, core)
        end
    end
    return ok, result
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
    if PNC.Persistence and PNC.Persistence.CoreSocial
        and type(PNC.Persistence.CoreSocial.FromCoreSocial) == "function"
        and type(actor.social) == "table"
    then
        record.social = PNC.Persistence.CoreSocial.FromCoreSocial(
            actor.social,
            record.social
        ) or actor.social
    else
        record.social = actor.social
    end
    record.personalInventory = actor.personalInventory
    record.coreActorID = tostring(actor.actorId)
    record.x = point.x
    record.y = point.y
    record.z = point.z
    record.runtime = record.runtime or {}
    if OptionalPolicy then
        OptionalPolicy.ClearUnavailable(record)
    end
    record.runtime.coreActorID = tostring(actor.actorId)
    projectProviderLease(record, lease.leaseID)
    record.runtime.coreProvider = lease.provider
    if lease.state == "materialized" then
        record.presenceState = PNC.Const.PRESENCE_LIVE
    elseif lease.state == "abstract" then
        record.presenceState = PNC.Const.PRESENCE_ABSTRACT
    end
    return record
end

local function survivorWorldAffiliation(actor)
    local extensions = actor
        and type(actor.extensions) == "table"
        and actor.extensions or {}
    local affiliation = extensions[AFFILIATION_EXTENSION]
    return type(affiliation) == "table" and affiliation or nil
end

local function coreActorDefinition(actor, projected)
    local affiliation = survivorWorldAffiliation(actor) or {}
    local identity = actor and actor.identity or {}
    local world = projected and projected.world or actor and actor.world or {}
    local location = world and world.location or {}
    local point = location and location.position or {}
    local lease = actor and actor.providerLease or {}
    return {
        id = tostring(actor.actorId),
        displayName = projected and projected.displayName
            or identity.displayName,
        identitySeed = identity.identitySeed,
        identity = identity,
        appearance = projected and projected.appearance
            or actor.appearance,
        personalInventory = projected and projected.personalInventory
            or actor.personalInventory,
        archetypeID = actor.archetypeID
            or identity.archetypeID
            or "core.survivor",
        tacticalClass = "neutral",
        x = tonumber(point.x) or 0,
        y = tonumber(point.y) or 0,
        z = tonumber(point.z) or 0,
        coreActorID = tostring(actor.actorId),
        factionID = affiliation.factionID,
        factionName = affiliation.factionName,
        factionArchetypeID = affiliation.factionArchetypeID,
        factionRole = affiliation.role,
        communityID = affiliation.communityID,
        groupID = affiliation.groupID,
        runtime = {
            coreActorID = tostring(actor.actorId),
            coreProviderLease = lease.leaseID,
            coreProvider = lease.provider,
            coreProviderState = lease.state,
            coreProviderBodyID = lease.bodyID,
        },
    }
end

local function applyCoreActorProjection(record, actor, projected, options)
    options = type(options) == "table" and options or {}
    local definition = coreActorDefinition(actor, projected)
    local changed = false
    local isLive = record.presenceState == (PNC.Const and PNC.Const.PRESENCE_LIVE or "live")
        or (PNC.Registry and PNC.Registry.GetLiveZombie
            and PNC.Registry.GetLiveZombie(definition.id) ~= nil)
    local function assign(key, value)
        if value ~= nil and record[key] ~= value then
            record[key] = value
            changed = true
        end
    end

    assign("name", definition.displayName)
    assign("displayName", definition.displayName)
    assign("identitySeed", definition.identitySeed)
    assign("identity", definition.identity)
    assign("appearance", definition.appearance)
    assign("personalInventory", definition.personalInventory)
    assign("archetypeID", definition.archetypeID)
    if not isLive then
        assign("x", definition.x)
        assign("y", definition.y)
        assign("z", definition.z)
    end
    assign("coreActorID", definition.coreActorID)
    assign("factionID", definition.factionID)
    assign("factionName", definition.factionName)
    assign("factionArchetypeID", definition.factionArchetypeID)
    assign("factionRole", definition.factionRole)
    assign("communityID", definition.communityID)
    assign("groupID", definition.groupID)
    if (not record.runtime or not record.runtime.coreAffiliationDirty)
        and PNC.FactionTypes and PNC.FactionTypes.NormalizeAffiliation
    then
        local affiliation = PNC.FactionTypes.NormalizeAffiliation(
            survivorWorldAffiliation(actor)
        )
        if not tablesEqual(record.affiliation, affiliation) then
            record.affiliation = affiliation
            changed = true
        end
    end
    if record.coreBacked ~= true then
        record.coreBacked = true
        changed = true
    end
    if record.persistenceAuthority ~= "core_extension" then
        record.persistenceAuthority = "core_extension"
        changed = true
    end

    record.runtime = record.runtime or {}
    for key, value in pairs(definition.runtime) do
        if value ~= nil and record.runtime[key] ~= value then
            record.runtime[key] = value
            changed = true
        end
    end
    record.coreRevision = tonumber(actor.revision) or tonumber(record.coreRevision) or 1
    local expectedPresence = definition.runtime.coreProviderState
        == "materialized"
        and PNC.Const.PRESENCE_LIVE
        or PNC.Const.PRESENCE_ABSTRACT
    if (not isLive or expectedPresence == PNC.Const.PRESENCE_LIVE)
        and record.presenceState ~= expectedPresence
    then
        record.presenceState = expectedPresence
        changed = true
    end
    if record.runtime.lifecycle == nil then
        record.runtime.lifecycle = {
            phase = expectedPresence == PNC.Const.PRESENCE_LIVE
                and "live" or "abstract",
            bodyState = expectedPresence == PNC.Const.PRESENCE_LIVE
                and "bound" or "missing",
            lastReason = "core_actor_promoted",
            lastTransitionAt = PNC.Core.Now(),
            lastAuditAt = 0,
            lastError = nil,
            corpseState = "none",
        }
        changed = true
    end
    if options.markDirty == true
        and changed
        and PNC.Registry
        and type(PNC.Registry.MarkDirty) == "function"
    then
        PNC.Registry.MarkDirty(record, "core_actor_hydration")
    end
    return record, changed
end

local function coreRegistry(core)
    local service = actors(core or PsychopatzCore)
    return service and service.DefaultRegistry or nil
end

local function resolveCanonicalActor(actorOrID, core)
    local reg = coreRegistry(core)
    local api = actors(core or PsychopatzCore)
    if type(actorOrID) == "table" then
        local id = tostring(actorOrID.actorId or actorOrID.actorID or "")
        if id == "" then return nil, "core_actor_id_missing" end
        if reg and type(reg.Get) == "function" then
            local live = reg:Get(id)
            if live then return live, id end
        end
        return actorOrID, id
    end
    local id = actorOrID ~= nil and tostring(actorOrID) or ""
    if id == "" then return nil, "actor_id_required" end
    local actor = reg and type(reg.Get) == "function" and reg:Get(id) or nil
    if not actor and api and type(api.Resolve) == "function" then
        actor = api.Resolve(id)
        if actor then
            id = tostring(actor.actorId or actor.actorID or id)
        end
    end
    if not actor then return nil, "core_actor_not_found" end
    return actor, id
end

local function hasInventoryBridgeDeps()
    return PNC.Inventory
        and PNC.Inventory.Internal
        and type(PNC.Inventory.Internal.createBaseInventory) == "function"
end

function Adapter.IsAliveCoreActor(actorID, core)
    if actorID == nil or tostring(actorID) == "" then return false end
    local reg = coreRegistry(core)
    if not reg then return false end
    local id = tostring(actorID)
    if type(reg.HasActiveActor) == "function" then
        return reg:HasActiveActor(id) == true
    end
    if type(reg.Has) == "function" then
        return reg:Has(id) == true
    end
    return type(reg.Get) == "function" and reg:Get(id) ~= nil
end

function Adapter.IsRetiredCoreActor(actorID, core)
    if actorID == nil or tostring(actorID) == "" then return false end
    local reg = coreRegistry(core)
    if not reg then return false end
    local id = tostring(actorID)
    if type(reg.GetTombstone) == "function" then
        return reg:GetTombstone(id) ~= nil
    end
    return (type(reg.tombstones) == "table" and reg.tombstones[id] ~= nil)
        or (type(reg.tombstoneAliases) == "table" and reg.tombstoneAliases[id] ~= nil)
end

function Adapter.GetCoreActorExtension(actorID, core)
    if actorID == nil or tostring(actorID) == "" then return nil end
    local reg = coreRegistry(core)
    if not reg then return nil end
    local id = tostring(actorID)
    if type(reg.GetExtension) == "function" then
        return reg:GetExtension(id, CoreActorExtension.EXTENSION_ID)
    end
    local actor = type(reg.Get) == "function" and reg:Get(id) or nil
    local exts = actor and type(actor.extensions) == "table"
        and actor.extensions or nil
    return exts and cloneTable(exts[CoreActorExtension.EXTENSION_ID]) or nil
end

function Adapter.CanPromoteCoreActor(actorOrID, core)
    core = core or PsychopatzCore
    local actor = resolveCanonicalActor(actorOrID, core)
    if type(actor) ~= "table" then
        return false, "core_actor_not_found"
    end
    if OptionalPolicy and not OptionalPolicy.ShouldProject(actor) then
        return false, "optional_provider_unavailable"
    end
    local exts = type(actor.extensions) == "table" and actor.extensions or {}
    local lease = type(actor.providerLease) == "table" and actor.providerLease or {}
    if survivorWorldAffiliation(actor)
        or exts[CoreActorExtension.EXTENSION_ID] ~= nil
        or lease.state == "abstract"
        or lease.state == "materialized"
    then
        return true
    end
    return false, "not_survivor_world_actor"
end

local AI_BUILDING_CACHE_TTL_MS = 300000
local AI_BUILDING_CACHE_MAX = 32

local function isPlayerOwnedRecord(record)
    if type(record) ~= "table" then return false end
    return record.recruited == true
        or record.colonyOwned == true
        or record.ownerUsername ~= nil
        or record.ownerOnlineID ~= nil
        or record.ownerCharacterUUID ~= nil
end

local function aiBuildingCacheKey(record, actor, x, y, z)
    local sw = type(actor) == "table"
        and type(actor.extensions) == "table"
        and actor.extensions[AFFILIATION_EXTENSION] or nil
    local communityID = (type(sw) == "table" and sw.communityID)
        or record.communityID
    if communityID ~= nil and tostring(communityID) ~= "" then
        return "community:" .. tostring(communityID)
    end
    local groupID = (type(sw) == "table" and sw.groupID) or record.groupID
    if groupID ~= nil and tostring(groupID) ~= "" then
        return "group:" .. tostring(groupID)
    end
    return "cell:"
        .. tostring(math.floor((tonumber(x) or 0) / 32)) .. ":"
        .. tostring(math.floor((tonumber(y) or 0) / 32)) .. ":"
        .. tostring(math.floor(tonumber(z) or 0))
end

local function resolveCachedAIShelterSite(cacheKey, x, y, z, nowMs)
    local resolver = PNC.CommunitySiteResolver
    if not resolver or type(resolver.FindAvailableNear) ~= "function" then
        return nil
    end
    Adapter._aiBuildingOrderCache = Adapter._aiBuildingOrderCache or {}
    local cache = Adapter._aiBuildingOrderCache
    local cached = cache[cacheKey]
    if cached and (nowMs - (tonumber(cached.at) or 0)) < AI_BUILDING_CACHE_TTL_MS then
        return cached.site
    end
    local count = 0
    for _ in pairs(cache) do count = count + 1 end
    if count >= AI_BUILDING_CACHE_MAX then
        Adapter._aiBuildingOrderCache = {}
        cache = Adapter._aiBuildingOrderCache
    end
    local siteFilter = nil
    local mobileInternal = PNC.MobileGroupDirectorInternal
    if mobileInternal
        and type(mobileInternal.PlayerOwnershipSnapshot) == "function"
        and type(mobileInternal.ShelterFilter) == "function"
    then
        local okSnap, snap = pcall(mobileInternal.PlayerOwnershipSnapshot)
        if okSnap and snap then
            local okFilter, filter = pcall(mobileInternal.ShelterFilter, snap)
            if okFilter and type(filter) == "function" then
                siteFilter = filter
            end
        end
    end
    local ok, site = pcall(resolver.FindAvailableNear, x, y, z, {
        searchRadius = 64,
        searchStep = 8,
        siteFilter = siteFilter,
    })
    local chosen = (ok and type(site) == "table" and site.kind == "building"
        and type(site.home) == "table") and site or nil
    cache[cacheKey] = {
        site = chosen,
        at = nowMs,
    }
    return chosen
end

-- Core-bootstrapped AI community/group actors arrive without a Hoomans
-- orderSpec. Without one, JobSystem defaults to GuardAnchor on a single
-- outdoor tile. Assign a standard roam/shelter order so they path into
-- nearby buildings (both abstracted via MetaGrid and materialized) and
-- participate in AmbientVisitService + RoamAmbient + RoamingSeat.
local function assignDefaultAIOrder(record, actor, nowMs)
    if type(record) ~= "table" or record.orderSpec ~= nil
        or isPlayerOwnedRecord(record)
    then
        return false
    end
    local x = tonumber(record.x) or tonumber(record.anchorX)
    local y = tonumber(record.y) or tonumber(record.anchorY)
    local z = tonumber(record.z) or tonumber(record.anchorZ) or 0
    if not x or not y then return false end
    local Const = PNC.Const or {}
    local cacheKey = aiBuildingCacheKey(record, actor, x, y, z)
    local site = resolveCachedAIShelterSite(cacheKey, x, y, z, nowMs)
    if site and site.home then
        record.orderSpec = {
            kind = Const.ORDER_ROAM or "roam",
            roamMode = Const.ROAM_MODE_SHELTER or "shelter",
            ambientMobile = true,
            ambientObjective = "shelter",
            ambientSourceID = cacheKey,
            shelterSiteID = site.id,
            shelterBounds = site.bounds and cloneTable(site.bounds) or nil,
            x = tonumber(site.home.x) or x,
            y = tonumber(site.home.y) or y,
            z = tonumber(site.home.z) or z,
            radius = math.max(4, tonumber(site.home.radius) or 10),
            reachedDistance = 3,
            moveMode = "walk",
            ephemeralDefault = true,
        }
        return true
    end
    record.orderSpec = {
        kind = Const.ORDER_ROAM or "roam",
        roamMode = Const.ROAM_MODE_AREA or "area",
        x = x,
        y = y,
        z = z,
        radius = tonumber(Const.ROAM_DEFAULT_RADIUS) or 16,
        moveMode = "walk",
        ephemeralDefault = true,
    }
    return true
end

function Adapter.PromoteCoreActor(actorOrID, core, options)
    core = core or PsychopatzCore
    options = type(options) == "table" and options or {}
    if type(core) ~= "table" then
        return nil, "actor_and_core_required"
    end
    local actor, actorID = resolveCanonicalActor(actorOrID, core)
    if not actor then return nil, actorID end

    if OptionalPolicy and not OptionalPolicy.ShouldProject(actor) then
        local unavailable = PNC.Registry
            and type(PNC.Registry.Get) == "function"
            and PNC.Registry.Get(actorID) or nil
        if unavailable then
            OptionalPolicy.MarkUnavailable(
                unavailable, "optional_provider_unavailable")
        end
        return nil, "optional_provider_unavailable"
    end

    local exts = type(actor.extensions) == "table" and actor.extensions or {}
    local lease = type(actor.providerLease) == "table" and actor.providerLease or {}
    if not survivorWorldAffiliation(actor)
        and exts[CoreActorExtension.EXTENSION_ID] == nil
        and lease.state ~= "abstract"
        and lease.state ~= "materialized"
        and options.allowUnscoped ~= true
    then
        return nil, "not_survivor_world_actor"
    end

    if not PNC.Registry or type(PNC.Registry.Get) ~= "function"
        or type(PNC.Registry.AddRecord) ~= "function"
    then
        return nil, "pnc_registry_unavailable"
    end

    local projected, reason = Adapter.Project(actor, core)
    if not projected then return nil, reason end

    local existing = PNC.Registry.Data and PNC.Registry.Data[actorID] or nil
    if existing then
        applyCoreActorProjection(existing, actor, projected, {
            markDirty = options.markDirty == true,
        })
        return existing, "existing"
    end

    if PNC.Registry.RemoveRuntimeView then
        PNC.Registry.RemoveRuntimeView(actorID)
    end

    if not Types or type(Types.NewRecord) ~= "function" then
        return nil, "pnc_record_types_unavailable"
    end
    local record
    record, reason = Types.NewRecord(
        coreActorDefinition(actor, projected)
    )
    if not record then return nil, reason end
    record.coreBacked = true
    record.coreActorID = actorID
    record.persistenceAuthority = "core_extension"

    applyCoreActorProjection(record, actor, projected, { markDirty = false })

    if PNC.Persistence and PNC.Persistence.CoreSocial
        and type(PNC.Persistence.CoreSocial.FromCoreSocial) == "function"
        and type(actor.social) == "table"
    then
        local coreSocial = PNC.Persistence.CoreSocial.FromCoreSocial(
            actor.social,
            record.social
        )
        if type(coreSocial) == "table" then
            record.social = coreSocial
        end
    end
    if type(actor.persona) == "table" then
        record.persona = cloneTable(actor.persona)
    end
    if type(actor.knowledge) == "table" then
        record.knowledge = cloneTable(actor.knowledge)
    end

    if hasInventoryBridgeDeps() and type(actor.personalInventory) == "table" then
        local inv, invErr = ActorInventoryBridge.HydrateRecord(record, projected)
        if not inv then
            return nil, invErr or "core_inventory_hydration_failed"
        end
    end

    local hoomansExt = exts[CoreActorExtension.EXTENSION_ID]
    if type(hoomansExt) == "table" then
        CoreActorExtension.Apply(record, hoomansExt)
    end

    record.runtime = record.runtime or {}
    local nowMs = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
    record.runtime.promotedAt = nowMs
    record.runtime.promotionReason = tostring(options.reason or "demand")

    assignDefaultAIOrder(record, actor, nowMs)

    if not PNC.Registry.AddRecord(record) then
        return nil, "pnc_core_actor_record_add_failed"
    end
    if PNC.AutonomyScorer
        and type(PNC.AutonomyScorer.HydrateOnPromotion) == "function"
    then
        local elapsedHours = math.max(0,
            tonumber(actor.elapsedOfflineHours or actor.offlineHours) or 0)
        if elapsedHours == 0 and actor.lastSimulatedAt
            and actor.worldAgeHours
        then
            elapsedHours = math.max(0,
                (tonumber(actor.worldAgeHours) or 0)
                - (tonumber(actor.lastSimulatedAt) or 0))
        end
        PNC.AutonomyScorer.HydrateOnPromotion(record, elapsedHours, nowMs)
    end
    Adapter.Metrics.promotions = (tonumber(Adapter.Metrics.promotions) or 0) + 1
    return record, "created"
end

function Adapter.HydrateCoreActor(actor, core)
    if type(actor) ~= "table" or type(core) ~= "table" then
        return nil, "actor_and_core_required"
    end
    return Adapter.PromoteCoreActor(actor, core, { reason = "explicit_hydrate" })
end

local ACTIVE_ORDER_KINDS = {
    follow = true,
    patrol = true,
    guard = true,
    work = true,
    facility = true,
    facility_activity = true,
    escort = true,
    travel = true,
}

function Adapter.HasActiveHoomansResponsibility(record, now, options)
    if type(record) ~= "table" then
        return false, "invalid_record"
    end
    options = type(options) == "table" and options or {}
    now = tonumber(now) or (PNC.Core and PNC.Core.Now and PNC.Core.Now()) or 0
    local runtime = type(record.runtime) == "table" and record.runtime or {}
    local lifecycle = type(runtime.lifecycle) == "table"
        and runtime.lifecycle or {}

    local liveState = PNC.Const and PNC.Const.PRESENCE_LIVE or "live"
    if record.presenceState == liveState
        or (PNC.Registry and PNC.Registry.GetLiveZombie
            and PNC.Registry.GetLiveZombie(record.id) ~= nil)
    then
        return true, "live_body"
    end
    if lifecycle.phase == "materializing" or lifecycle.phase == "releasing"
        or runtime.bodyLease ~= nil
    then
        return true, "body_transition"
    end
    if runtime.forceLive == true
        or runtime.debugPresenceOverride == true
        or runtime.abstractFollowMaterializeRequested == true
        or runtime.presenceHandoffRequested == true
        or (type(runtime.vehiclePassenger) == "table"
            and runtime.vehiclePassenger.active == true)
        or (type(runtime.conversationScene) == "table"
            and runtime.conversationScene.active == true)
    then
        return true, "explicit_runtime_hold"
    end
    if record.recruited == true
        or (record.ownerUsername ~= nil and tostring(record.ownerUsername) ~= "")
        or (record.ownerCharacterUUID ~= nil
            and tostring(record.ownerCharacterUUID) ~= "")
        or (type(record.generation) == "table"
            and tostring(record.generation.source or "")
                == "starting_companion_trait")
    then
        return true, "companion_owner"
    end
    if runtime.target ~= nil
        or runtime.attackAction ~= nil
        or (tonumber(runtime.inCombatUntil) or 0) > now
    then
        return true, "active_combat"
    end
    if type(record.health) == "table"
        and (record.health.state == "incapacitated"
            or record.health.state == "downed")
    then
        return true, "incapacitated"
    end
    local activeJob = tostring(record.activeJob or "")
    if activeJob ~= ""
        and activeJob ~= "Idle"
        and activeJob ~= "None"
        and activeJob ~= "GuardAnchor"
        and activeJob ~= "HuntNearestPlayer"
    then
        return true, "active_job"
    end
    local orderKind = type(record.orderSpec) == "table"
        and tostring(record.orderSpec.kind or "") or ""
    if ACTIVE_ORDER_KINDS[orderKind] then
        return true, "active_order:" .. orderKind
    end
    if type(record.travel) == "table" and record.travel.active == true then
        return true, "active_travel"
    end
    if record.alive == false then
        return true, "dead_pending_retirement"
    end

    if options.ignoreGrace ~= true then
        local graceMs = tonumber(
            PNC.Const and PNC.Const.CORE_DEMOTE_GRACE_MS
        ) or 2000
        local promotedAt = tonumber(runtime.promotedAt) or 0
        local abstractedAt = tonumber(runtime.abstractedAt) or 0
        local eligibleAt = tonumber(runtime.demoteEligibleAt) or 0
        if now < promotedAt + graceMs
            or (abstractedAt > 0 and now < abstractedAt + graceMs)
            or (eligibleAt > 0 and now < eligibleAt)
        then
            return true, "demote_grace_window"
        end
    end

    if options.ignoreProximity ~= true
        and PNC.Core and type(PNC.Core.ForEachPlayer) == "function"
    then
        local keepRadius = tonumber(
            PNC.Const and PNC.Const.ABSTRACT_DISTANCE
        ) or 40
        local keepRadiusSq = keepRadius * keepRadius
        local nearPlayer = false
        PNC.Core.ForEachPlayer(function(player)
            if nearPlayer or not player or type(player.getX) ~= "function" then
                return
            end
            local dx = (tonumber(record.x) or 0) - tonumber(player:getX())
            local dy = (tonumber(record.y) or 0) - tonumber(player:getY())
            if (dx * dx + dy * dy) <= keepRadiusSq then
                nearPlayer = true
            end
        end)
        if nearPlayer then
            return true, "near_player"
        end
    end

    return false, "eligible_for_demotion"
end

local function isServerAuthority()
    if PNC.Core and type(PNC.Core.IsAuthority) == "function" then
        return PNC.Core.IsAuthority() == true
    end
    local clientOnly = type(isClient) == "function" and isClient() == true
        and (type(isServer) ~= "function" or isServer() ~= true)
    return not clientOnly
end

local function worldAgeHours()
    if type(getGameTime) == "function" then
        local gt = getGameTime()
        if gt and type(gt.getWorldAgeHours) == "function" then
            local hours = tonumber(gt:getWorldAgeHours())
            if hours and hours == hours then return math.max(0, hours) end
        end
    end
    return 0
end

local function resolveLiveBodyID(record, body)
    if body ~= nil then
        if type(body.getPersistentOutfitID) == "function" then
            local ok, value = pcall(body.getPersistentOutfitID, body)
            if ok and value ~= nil and tostring(value) ~= ""
                and tostring(value) ~= "0"
            then
                return tostring(value)
            end
        end
        if type(body.getOnlineID) == "function" then
            local ok, value = pcall(body.getOnlineID, body)
            if ok and value ~= nil and tonumber(value)
                and tonumber(value) >= 0
            then
                return tostring(value)
            end
        end
        if type(body) == "table" then
            local value = body.bodyID or body.bodyId or body.id
            if value ~= nil and tostring(value) ~= ""
                and tostring(value) ~= "0"
            then
                return tostring(value)
            end
        end
    end
    if type(record) == "table" then
        local runtime = type(record.runtime) == "table" and record.runtime or nil
        local fallback = record.liveBodyInstanceID
            or record.liveBodyPopulationID
            or (runtime and runtime.bodyLease)
            or (record.id and ("live:" .. tostring(record.id)))
        if fallback ~= nil and tostring(fallback) ~= ""
            and tostring(fallback) ~= "0"
        then
            return tostring(fallback)
        end
    end
    return nil
end

local function markProjectionDirty(core, reason)
    local sync = core and core.ActorProjectionSync or nil
    if sync and type(sync.MarkDirty) == "function" then
        sync.MarkDirty(reason)
    end
end

local function buildSyncedAppearancePatch(actor, record)
    if type(actor) ~= "table" or type(actor.appearance) ~= "table"
        or type(actor.appearance.resolved) ~= "table"
    then
        return nil
    end
    local resolved = type(record.runtime) == "table"
        and type(record.runtime.appearanceCache) == "table"
        and record.runtime.appearanceCache or nil
    if not resolved and PNC.Identity
        and type(PNC.Identity.RollAppearance) == "function"
    then
        resolved = PNC.Identity.RollAppearance(record)
    end
    if not resolved and type(record.appearance) == "table" then
        resolved = type(record.appearance.resolved) == "table"
            and record.appearance.resolved or record.appearance
    end
    if type(resolved) ~= "table" then return nil end

    local current = actor.appearance.resolved
    local nextAppearance = cloneTable(actor.appearance)
    local target = nextAppearance.resolved
    local changed = false
    local function syncField(key, value)
        if value ~= nil and not tablesEqual(current[key], value) then
            target[key] = cloneTable(value)
            changed = true
        end
    end

    syncField("skinTexture", resolved.skinTexture)
    syncField("skinColor", resolved.skinColor)
    syncField("hairModel", resolved.hairModel)
    syncField("hairColor", resolved.hairColor)
    syncField("beardModel", resolved.beardModel)
    syncField("hairStubble", resolved.hairStubble)
    syncField("beardStubble", resolved.beardStubble)
    syncField("chestHair", resolved.chestHair)
    if record.isFemale ~= nil or (type(record.identity) == "table"
        and record.identity.isFemale ~= nil)
    then
        local female = record.isFemale == true
            or (type(record.identity) == "table"
                and record.identity.isFemale == true)
        syncField("gender", female and "female" or "male")
    end
    return changed and nextAppearance or nil
end

local function buildSyncedIdentityPatch(actor, record)
    if type(actor) ~= "table" or type(actor.identity) ~= "table"
        or type(actor.identity.survivor) ~= "table"
    then
        return nil
    end
    local nextIdentity = cloneTable(actor.identity)
    local targetSurvivor = nextIdentity.survivor
    local srcIdentity = type(record.identity) == "table"
        and record.identity or {}
    local srcSurvivor = type(srcIdentity.survivor) == "table"
        and srcIdentity.survivor or {}
    local changed = false

    local displayNameValue = record.displayName or record.name
        or srcIdentity.displayName
    if type(displayNameValue) == "string" and displayNameValue ~= ""
        and nextIdentity.displayName ~= displayNameValue
    then
        nextIdentity.displayName = displayNameValue
        changed = true
    end
    if record.isFemale ~= nil or srcIdentity.isFemale ~= nil then
        local gender = (record.isFemale == true
            or srcIdentity.isFemale == true) and "female" or "male"
        if nextIdentity.gender ~= gender then
            nextIdentity.gender = gender
            changed = true
        end
        if targetSurvivor.gender ~= gender then
            targetSurvivor.gender = gender
            changed = true
        end
    end
    for _, key in ipairs({
        "forename", "surname", "skinTexture", "skinColor", "hairModel",
        "hairColor", "beardModel", "hairStubble", "beardStubble", "chestHair",
    }) do
        local value = srcSurvivor[key]
        if value ~= nil and not tablesEqual(targetSurvivor[key], value) then
            targetSurvivor[key] = cloneTable(value)
            changed = true
        end
    end
    return changed and nextIdentity or nil
end

local function mirrorLeaseRuntime(record, actor)
    if type(record) ~= "table" or type(actor) ~= "table" then return end
    local lease = type(actor.providerLease) == "table"
        and actor.providerLease or {}
    record.runtime = type(record.runtime) == "table" and record.runtime or {}
    record.runtime.coreProvider = lease.provider
    record.runtime.coreProviderLease = lease.leaseID
    record.runtime.coreProviderState = lease.state
    record.runtime.coreProviderBodyID = lease.bodyID
    if tonumber(actor.revision) ~= nil then
        record.coreRevision = tonumber(actor.revision)
    end
end

local function buildSyncedWorldPositionPatch(actor, record)
    if type(actor) ~= "table" or type(record) ~= "table" then
        return nil
    end
    local rx = tonumber(record.x)
    local ry = tonumber(record.y)
    local rz = tonumber(record.z) or 0
    if rx == nil or ry == nil or rx ~= rx or ry ~= ry then
        return nil
    end
    local curPos = position(actor)
    if math.abs(rx - curPos.x) <= 0.001
        and math.abs(ry - curPos.y) <= 0.001
        and math.abs(rz - curPos.z) <= 0.001
    then
        return nil
    end
    local nextWorld = cloneTable(
        type(actor.world) == "table" and actor.world or {}
    )
    nextWorld.location = type(nextWorld.location) == "table"
        and nextWorld.location or {}
    nextWorld.location.position = { x = rx, y = ry, z = rz }
    return nextWorld
end

local function syncWorldPositionToCore(reg, actorID, actor, record, core)
    if not reg or type(reg.Commit) ~= "function" then
        return actor, false
    end
    local nextWorld = buildSyncedWorldPositionPatch(actor, record)
    if not nextWorld then
        return actor, false
    end
    local committed = reg:Commit(
        actorID,
        { world = nextWorld },
        actor.revision,
        { returnClone = false }
    )
    if not committed then
        return actor, false
    end
    if tonumber(committed.revision) ~= nil then
        record.coreRevision = tonumber(committed.revision)
    end
    if PNC.Registry then
        PNC.Registry.CoreStoreDirty = true
    end
    markProjectionDirty(core, "core_actor_position_sync")
    return committed, true
end

--- Synchronizes Project Hoomans' live/abstract presence state into
--- PsychopatzCore's canonical `actor.providerLease` so SurvivorWorld map
--- projections, hover cards, diagnostics, and startup restore stay in sync.
function Adapter.SyncPresenceLease(record, zombie, core, options)
    if not isServerAuthority() then
        return false, "server_authority_required"
    end
    core = core or PsychopatzCore
    options = type(options) == "table" and options or {}
    if type(record) ~= "table" or type(core) ~= "table" then
        return false, "record_and_core_required"
    end
    local reg = coreRegistry(core)
    if not reg then
        return false, "core_registry_unavailable"
    end
    local actorID = tostring(
        record.coreActorID
            or (type(record.runtime) == "table" and record.runtime.coreActorID)
            or record.id
            or ""
    )
    if actorID == "" then
        return false, "actor_id_required"
    end
    local actor = (type(reg.Peek) == "function" and reg:Peek(actorID))
        or (type(reg.Get) == "function" and reg:Get(actorID))
        or nil
    if not actor then
        return false, "core_actor_not_found"
    end

    local liveState = PNC.Const and PNC.Const.PRESENCE_LIVE or "live"
    local isLive = record.presenceState == liveState
    if isLive and zombie == nil and PNC.Registry
        and type(PNC.Registry.GetLiveZombie) == "function"
    then
        zombie = PNC.Registry.GetLiveZombie(record.id)
    end
    local lease = type(actor.providerLease) == "table"
        and actor.providerLease or {}
    local nowHours = tonumber(options.now) or worldAgeHours()

    if isLive then
        local idValue = resolveLiveBodyID(record, zombie)
        if not idValue then
            return false, "body_id_required"
        end
        if lease.state == "materialized" then
            if lease.provider == "ProjectHoomans" then
                if tostring(lease.bodyID or "") == tostring(idValue) then
                    mirrorLeaseRuntime(record, actor)
                    syncWorldPositionToCore(reg, actorID, actor, record, core)
                    return true, "already_materialized"
                end
                if type(reg.DematerializeProvider) == "function" then
                    local demat, dematErr = reg:DematerializeProvider(actorID, {
                        provider = "ProjectHoomans",
                        owner = lease.owner,
                        bodyID = lease.bodyID,
                        authority = "server",
                        now = nowHours,
                    })
                    if not demat then
                        return false, dematErr or "core_dematerialize_failed"
                    end
                    actor = demat
                    lease = type(actor.providerLease) == "table"
                        and actor.providerLease or {}
                end
            else
                return false, "body_lease_active"
            end
        end

        if lease.state == "released" or lease.state == nil then
            if type(reg.AcquireProvider) ~= "function" then
                return false, "core_acquire_unavailable"
            end
            local acquired, acqErr = reg:AcquireProvider(actorID, {
                provider = "ProjectHoomans",
                owner = "ProjectHoomans:live",
                authority = "server",
                now = nowHours,
            })
            if not acquired then
                return false, acqErr or "core_acquire_failed"
            end
            actor = acquired
            lease = type(actor.providerLease) == "table"
                and actor.providerLease or {}
        elseif lease.state == "abstract"
            and lease.provider ~= "ProjectHoomans"
        then
            if type(reg.SwitchProvider) ~= "function" then
                return false, "core_switch_unavailable"
            end
            local switched, switchErr = reg:SwitchProvider(actorID, {
                provider = "ProjectHoomans",
                owner = "ProjectHoomans:live",
                handoffFrom = lease.owner,
                authority = "server",
                now = nowHours,
            })
            if not switched then
                return false, switchErr or "core_switch_failed"
            end
            actor = switched
            lease = type(actor.providerLease) == "table"
                and actor.providerLease or {}
        end

        if type(reg.MaterializeProvider) ~= "function" then
            return false, "core_materialize_unavailable"
        end
        local committed, matErr = reg:MaterializeProvider(actorID, {
            provider = "ProjectHoomans",
            owner = lease.owner or "ProjectHoomans:live",
            bodyID = idValue,
            authority = "server",
            now = nowHours,
        })
        if not committed then
            return false, matErr or "core_materialize_failed"
        end
        mirrorLeaseRuntime(record, committed)
        syncWorldPositionToCore(reg, actorID, committed, record, core)
        markProjectionDirty(core, "presence_materialize")
        return true, "materialized"
    end

    if lease.state == "materialized"
        and lease.provider == "ProjectHoomans"
    then
        if type(reg.DematerializeProvider) ~= "function" then
            return false, "core_dematerialize_unavailable"
        end
        local committed, dematErr = reg:DematerializeProvider(actorID, {
            provider = "ProjectHoomans",
            owner = lease.owner,
            bodyID = lease.bodyID,
            authority = "server",
            now = nowHours,
        })
        if not committed then
            return false, dematErr or "core_dematerialize_failed"
        end
        mirrorLeaseRuntime(record, committed)
        syncWorldPositionToCore(reg, actorID, committed, record, core)
        markProjectionDirty(core, "presence_abstract")
        return true, "abstract"
    end

    mirrorLeaseRuntime(record, actor)
    syncWorldPositionToCore(reg, actorID, actor, record, core)
    return true, "already_abstract"
end

function Adapter.SyncPromotedCoreActorToCore(record, core, options)
    core = core or PsychopatzCore
    options = type(options) == "table" and options or {}
    if type(record) ~= "table" or type(core) ~= "table" then
        return false, "record_and_core_required", OUTCOME_TERMINAL
    end
    if record.coreBacked ~= true then
        return false, "not_core_backed", OUTCOME_TERMINAL
    end
    if record.runtime and record.runtime.pendingRecruitmentRollback then
        return false, "recruitment_rollback_pending", OUTCOME_RETRYABLE
    end
    local reg = coreRegistry(core)
    if not reg then
        return false, "core_registry_unavailable", OUTCOME_RETRYABLE
    end
    local actorID = tostring(
        record.coreActorID
            or (type(record.runtime) == "table" and record.runtime.coreActorID)
            or record.id
            or ""
    )
    if actorID == "" then
        return false, "actor_id_required", OUTCOME_TERMINAL
    end
    local actor = (type(reg.Peek) == "function" and reg:Peek(actorID))
        or reg:Get(actorID)
    if not actor then
        return false, "core_actor_not_found", OUTCOME_TERMINAL
    end

    local liveState = PNC.Const and PNC.Const.PRESENCE_LIVE or "live"
    local recordIsLive = record.presenceState == liveState
        or (PNC.Registry and type(PNC.Registry.GetLiveZombie) == "function"
            and PNC.Registry.GetLiveZombie(record.id) ~= nil)
    local lease = type(actor.providerLease) == "table"
        and actor.providerLease or nil
    local leaseState = lease and lease.state or nil
    if (recordIsLive and leaseState ~= "materialized")
        or (not recordIsLive and leaseState == "materialized"
            and lease.provider == "ProjectHoomans")
    then
        Adapter.SyncPresenceLease(record, nil, core)
        actor = (type(reg.Peek) == "function" and reg:Peek(actorID))
            or reg:Get(actorID)
        if not actor then
            return false, "core_actor_not_found", OUTCOME_TERMINAL
        end
    end

    local coreSocialAdapter = PNC.Persistence and PNC.Persistence.CoreSocial or nil
    if type(record.social) == "table"
        and coreSocialAdapter
        and type(coreSocialAdapter.SyncToCore) == "function"
    then
        local localRev = tonumber(record.social.revision) or 0
        local coreRev = tonumber(actor.social and actor.social.revision) or 0
        local runtime = type(record.runtime) == "table" and record.runtime or nil
        local syncedRev = runtime and tonumber(runtime._coreSyncedSocialRev) or nil
        local dirtyDomains = PNC.Registry and PNC.Registry.DirtyDomains
            and PNC.Registry.DirtyDomains[record.id] or nil
        local socialDomainDirty = type(dirtyDomains) == "table"
            and dirtyDomains.social == true or false
        local needsSocialSync = (
                (coreRev == 0 or syncedRev == nil)
                and record.social.authority ~= "core"
                and type(coreSocialAdapter.HasGenericSocialPayload) == "function"
                and coreSocialAdapter.HasGenericSocialPayload(record.social)
            )
            or localRev > coreRev
            or socialDomainDirty
            or (runtime and runtime.coreSocialDirty == true)
        if needsSocialSync then
            local ok, reason = coreSocialAdapter.SyncToCore(record, core)
            if not ok then
                return false,
                    reason or "core_social_sync_failed",
                    OUTCOME_RETRYABLE
            end
            if type(record.runtime) == "table" then
                record.runtime.coreSocialDirty = nil
            end
            actor = (type(reg.Peek) == "function" and reg:Peek(actorID))
                or reg:Get(actorID)
            if not actor then
                return false, "core_actor_not_found", OUTCOME_TERMINAL
            end
        elseif syncedRev == nil then
            record.runtime = type(record.runtime) == "table" and record.runtime or {}
            record.runtime._coreSyncedSocialRev = coreRev
        end
    end

    local patch = {}
    local hasPatch = false

    local nextWorld = buildSyncedWorldPositionPatch(actor, record)
    if nextWorld then
        patch.world = nextWorld
        hasPatch = true
    end

    local syncedInvRev = nil
    if type(record.inventory) == "table" and hasInventoryBridgeDeps() then
        local invRev = tonumber(record.inventory.revision) or 0
        local lastInvRev = type(record.runtime) == "table"
            and record.runtime._coreSyncedInventoryRev or nil
        if actor.personalInventory == nil
            or lastInvRev ~= invRev
            or options.forceInventory == true
        then
            local captured, _, captureErr = ActorInventoryBridge.CaptureRecord(
                record, actor
            )
            if not captured then
                return false,
                    captureErr or "core_inventory_capture_failed",
                    OUTCOME_RETRYABLE
            end
            if Json.Encode(captured) ~= Json.Encode(actor.personalInventory) then
                patch.personalInventory = captured
                hasPatch = true
            end
            syncedInvRev = invRev
        end
    end

    local extensionActorView = actor
    if patch.world then
        extensionActorView = { world = patch.world }
    end
    local nextExt = CoreActorExtension.Encode(record, extensionActorView)
    local oldExts = type(actor.extensions) == "table" and actor.extensions or {}
    local oldExt = oldExts[CoreActorExtension.EXTENSION_ID]
    local extChanged = not tablesEqual(oldExt, nextExt)

    local syncAffiliation = options.syncAffiliation == true
        or (record.runtime and record.runtime.coreAffiliationDirty == true)
    local affiliation = syncAffiliation and recordAffiliation(record) or nil
    local curAff = type(oldExts[AFFILIATION_EXTENSION]) == "table"
        and oldExts[AFFILIATION_EXTENSION] or {}
    local affChanged = affiliation ~= nil
        and (oldExts[AFFILIATION_EXTENSION] ~= nil or affiliation.factionID ~= nil
            or affiliation.communityID ~= nil or affiliation.groupID ~= nil)
        and not tablesEqual(curAff, affiliation)

    if extChanged or affChanged then
        local nextExts = cloneTable(oldExts)
        nextExts[CoreActorExtension.EXTENSION_ID] = nextExt
        if affChanged then
            nextExts[AFFILIATION_EXTENSION] = affiliation
        end
        patch.extensions = nextExts
        hasPatch = true
    end

    local nextAppearance = buildSyncedAppearancePatch(actor, record)
    if nextAppearance then
        patch.appearance = nextAppearance
        hasPatch = true
    end

    local nextIdentity = buildSyncedIdentityPatch(actor, record)
    if nextIdentity then
        patch.identity = nextIdentity
        hasPatch = true
    end

    if hasPatch then
        local committed, commitErr = reg:Commit(
            actorID, patch, actor.revision, { returnClone = false }
        )
        if not committed then
            return false,
                commitErr or "core_actor_commit_failed",
                OUTCOME_RETRYABLE
        end
        if syncedInvRev ~= nil then
            record.runtime = type(record.runtime) == "table" and record.runtime or {}
            record.runtime._coreSyncedInventoryRev = syncedInvRev
        end
        Adapter.Metrics.syncs = (tonumber(Adapter.Metrics.syncs) or 0) + 1
        record.coreRevision = committed.revision
        if record.runtime then record.runtime.coreAffiliationDirty = nil end
        if PNC.Registry then
            PNC.Registry.CoreStoreDirty = true
        end
        if patch.appearance ~= nil or patch.identity ~= nil
            or patch.personalInventory ~= nil or patch.world ~= nil
        then
            markProjectionDirty(core, "core_actor_presentation_sync")
        end
        return true, {
            committed = true,
            actor = committed,
            extensionPersisted = nextExt ~= nil,
        }, OUTCOME_WRITTEN
    end

    if syncedInvRev ~= nil then
        record.runtime = type(record.runtime) == "table" and record.runtime or {}
        record.runtime._coreSyncedInventoryRev = syncedInvRev
    end
    if record.runtime then record.runtime.coreAffiliationDirty = nil end
    return true, {
        committed = false,
        actor = actor,
        extensionPersisted = nextExt ~= nil,
    }, OUTCOME_WRITTEN
end

function Adapter.SyncAllPromotedCoreActors(core)
    core = core or PsychopatzCore
    if not PNC.Registry or type(PNC.Registry.Data) ~= "table" then
        return 0
    end
    local synced = 0
    for _, record in pairs(PNC.Registry.Data) do
        if type(record) == "table" and record.coreBacked == true then
            local ok, res = Adapter.SyncPromotedCoreActorToCore(record, core)
            if ok and type(res) == "table" and res.committed == true then
                synced = synced + 1
            end
        end
    end
    return synced
end

function Adapter.DemoteCoreActor(recordOrID, core, options)
    core = core or PsychopatzCore
    options = type(options) == "table" and options or {}
    if not PNC.Registry then
        return false, "pnc_registry_unavailable"
    end
    local id = type(recordOrID) == "table" and tostring(recordOrID.id or "")
        or tostring(recordOrID or "")
    local record = PNC.Registry.Data and PNC.Registry.Data[id] or nil
    if not record then
        return false, "promoted_record_not_found"
    end
    if record.coreBacked ~= true then
        return false, "not_core_backed"
    end
    local liveState = PNC.Const and PNC.Const.PRESENCE_LIVE or "live"
    if record.presenceState == liveState
        or (PNC.Registry.GetLiveZombie and PNC.Registry.GetLiveZombie(id) ~= nil)
    then
        return false, "live_body_active"
    end
    if options.force ~= true then
        local active, reason = Adapter.HasActiveHoomansResponsibility(
            record,
            options.now,
            options
        )
        if active then
            return false, reason
        end
    end

    local synced, syncResult = Adapter.SyncPromotedCoreActorToCore(
        record, core, options
    )
    if not synced then
        return false, syncResult
    end

    PNC.Registry.ReleasePromotedRecord(id)
    Adapter.Metrics.demotions = (tonumber(Adapter.Metrics.demotions) or 0) + 1
    return true, {
        actorId = id,
        committed = type(syncResult) == "table" and syncResult.committed == true,
        extensionPersisted = type(syncResult) == "table"
            and syncResult.extensionPersisted == true,
    }
end

function Adapter.RestoreActiveCoreActors(core)
    core = core or PsychopatzCore
    if type(core) ~= "table" then return 0, "core_required" end
    local reg = coreRegistry(core)
    if not reg then return 0, "core_actor_registry_unavailable" end

    local candidatesByID = {}
    local orderedIDs = {}
    local function addCandidate(actor)
        if type(actor) ~= "table" or not actor.actorId then return end
        local id = tostring(actor.actorId)
        if not candidatesByID[id] then
            candidatesByID[id] = actor
            orderedIDs[#orderedIDs + 1] = id
        end
    end

    if type(reg.ListWithExtension) == "function" then
        for _, actor in ipairs(reg:ListWithExtension(CoreActorExtension.EXTENSION_ID)) do
            addCandidate(actor)
        end
    end
    if type(reg.ListMaterialized) == "function" then
        for _, actor in ipairs(reg:ListMaterialized()) do
            addCandidate(actor)
        end
    end

    table.sort(orderedIDs)
    local restored = 0
    for _, id in ipairs(orderedIDs) do
        local actor = candidatesByID[id]
        local exts = type(actor.extensions) == "table" and actor.extensions or {}
        local ext = exts[CoreActorExtension.EXTENSION_ID]
        if CoreActorExtension.RequiresStartupPromotion(ext, actor) then
            local rec = Adapter.PromoteCoreActor(actor, core, {
                reason = "startup_restore",
            })
            if rec then
                restored = restored + 1
            end
        end
    end
    Adapter.Metrics.startupRestores =
        (tonumber(Adapter.Metrics.startupRestores) or 0) + restored
    return restored, "restored"
end

function Adapter.QueryPromotionCandidates(players, radius, now, core)
    core = core or PsychopatzCore
    local reg = coreRegistry(core)
    if not reg or type(players) ~= "table" or #players == 0 then
        return {}
    end
    radius = math.max(0, tonumber(radius) or 0)
    local radiusSq = radius * radius
    local promotedData = PNC.Registry and PNC.Registry.Data or {}
    local byID = {}

    local function considerActor(actor, distSq)
        if type(actor) ~= "table" or not actor.actorId then return end
        local id = tostring(actor.actorId)
        if promotedData[id] then return end
        if OptionalPolicy and not OptionalPolicy.ShouldProject(actor) then
            return
        end
        local exts = type(actor.extensions) == "table" and actor.extensions or {}
        local lease = type(actor.providerLease) == "table"
            and actor.providerLease or {}
        if not survivorWorldAffiliation(actor)
            and exts[CoreActorExtension.EXTENSION_ID] == nil
            and lease.state ~= "abstract"
            and lease.state ~= "materialized"
        then
            return
        end
        local existing = byID[id]
        if not existing or distSq < existing.distSq then
            byID[id] = { actorId = id, distSq = distSq }
        end
    end

    local auditDiag = PNC.PerformanceScalingDiagnostics
    local auditEnabled = auditDiag
        and type(auditDiag.IsPresenceTraversalAuditEnabled) == "function"
        and auditDiag.IsPresenceTraversalAuditEnabled() == true
        and type(auditDiag.LogPresenceTraversal) == "function"
    local spatialHitsCount = 0
    local worldGroupsCount = 0
    local journeyGroupsCount = 0
    local skippedDetails = nil
    if auditEnabled then skippedDetails = {} end

    if type(reg.QueryNearPosition) == "function" then
        for _, player in ipairs(players) do
            if player and type(player.getX) == "function" then
                local hits = reg:QueryNearPosition(
                    player:getX(), player:getY(), radius
                )
                spatialHitsCount = spatialHitsCount + #hits
                for i = 1, #hits do
                    local hit = hits[i]
                    if not promotedData[hit.actorId] then
                        local actor = reg.records and reg.records[hit.actorId]
                            or (type(reg.Get) == "function" and reg:Get(hit.actorId))
                        considerActor(actor, hit.distSq)
                    end
                end
            end
        end
    end

    local worldAuthority = PNC.CoreSurvivorWorldAuthority
    local worldRegistry = worldAuthority and worldAuthority.Registry or nil
    local auditWorldHour = nil
    if worldRegistry and type(worldRegistry.ListGroups) == "function"
        and type(worldRegistry.ProjectGroupMemberPosition) == "function"
    then
        -- ProjectGroupMemberPosition expects worldAgeHours, NOT real-time ms!
        local worldHour = nil
        if getGameTime and getGameTime() and getGameTime().getWorldAgeHours then
            worldHour = tonumber(getGameTime():getWorldAgeHours())
        end
        if worldHour == nil and PNC.Travel and PNC.Travel.Service
            and type(PNC.Travel.Service.WorldHour) == "function"
        then
            worldHour = tonumber(PNC.Travel.Service.WorldHour())
        end
        if worldHour == nil then
            local n = tonumber(now) or 0
            -- Guard against callers passing real-time milliseconds (> 1e9).
            worldHour = n < 100000000 and n or 0
        end
        auditWorldHour = worldHour
        local groupRadiusSq = (radius + 24) * (radius + 24)
        local listedGroups = worldRegistry:ListGroups()
        worldGroupsCount = #listedGroups
        for _, group in ipairs(listedGroups) do
            if type(group.journey) == "table" then
                journeyGroupsCount = journeyGroupsCount + 1
                local members = type(group.memberActorIDs) == "table" and group.memberActorIDs or {}
                if #members == 0 and skippedDetails and #skippedDetails < 6 then
                    skippedDetails[#skippedDetails + 1] = tostring(group.id) .. ":no_members"
                elseif #members > 0 then
                    local nearAnyPlayer = false
                    for _, memberID in ipairs(members) do
                        local id = tostring(memberID)
                        if not promotedData[id] then
                            local actor = reg.records and reg.records[id]
                                or (type(reg.Get) == "function" and reg:Get(id))
                            if actor then
                                local projectedPos = worldRegistry:ProjectGroupMemberPosition(
                                    group.id, id, actor.world, worldHour
                                )
                                if type(projectedPos) == "table"
                                    and tonumber(projectedPos.x)
                                    and tonumber(projectedPos.y)
                                then
                                    local minD2 = math.huge
                                    for _, player in ipairs(players) do
                                        local dx = tonumber(projectedPos.x) - player:getX()
                                        local dy = tonumber(projectedPos.y) - player:getY()
                                        local d2 = dx * dx + dy * dy
                                        if d2 < minD2 then minD2 = d2 end
                                        if d2 <= groupRadiusSq then
                                            nearAnyPlayer = true
                                        end
                                        if d2 <= radiusSq then
                                            considerActor(actor, d2)
                                            if byID[id] then
                                                byID[id].projectedX = tonumber(projectedPos.x)
                                                byID[id].projectedY = tonumber(projectedPos.y)
                                                byID[id].projectedZ = tonumber(projectedPos.z) or 0
                                            end
                                        end
                                    end
                                    if not nearAnyPlayer then
                                        if skippedDetails and #skippedDetails < 6 and minD2 <= (radius * 3) * (radius * 3) then
                                            skippedDetails[#skippedDetails + 1] = tostring(group.id)
                                                .. ":dist=" .. tostring(math.floor(math.sqrt(minD2)))
                                                .. "@(" .. tostring(math.floor(projectedPos.x)) .. "," .. tostring(math.floor(projectedPos.y)) .. ")"
                                        end
                                        break
                                    end
                                elseif skippedDetails and #skippedDetails < 6 then
                                    skippedDetails[#skippedDetails + 1] = tostring(group.id) .. ":no_proj"
                                end
                            elseif skippedDetails and #skippedDetails < 6 then
                                skippedDetails[#skippedDetails + 1] = tostring(group.id) .. ":actor_missing(" .. id .. ")"
                            end
                        end
                    end
                end
            end
        end
    end

    local ordered = {}
    for _, entry in pairs(byID) do
        ordered[#ordered + 1] = entry
    end
    table.sort(ordered, function(left, right)
        if left.distSq == right.distSq then
            return left.actorId < right.actorId
        end
        return left.distSq < right.distSq
    end)
    if auditEnabled then
        local nowMs = tonumber(now) or (PNC.Core and PNC.Core.Now and PNC.Core.Now()) or 0
        if (nowMs - (tonumber(Adapter._lastPromoAuditAt) or 0)) >= 2000 or #ordered > 0 then
            Adapter._lastPromoAuditAt = nowMs
            auditDiag.LogPresenceTraversal("core_promotion_scan", {
                "players=" .. tostring(#players),
                "radius=" .. tostring(radius),
                "worldHour=" .. tostring(auditWorldHour or "nil"),
                "spatialHits=" .. tostring(spatialHitsCount),
                "worldGroups=" .. tostring(worldGroupsCount),
                "journeyGroups=" .. tostring(journeyGroupsCount),
                "matched=" .. tostring(#ordered),
                "skipped=" .. (skippedDetails and #skippedDetails > 0 and table.concat(skippedDetails, ",") or "none"),
            })
        end
    end
    return ordered
end

function Adapter.PumpDemotions(now, core, options)
    options = type(options) == "table" and options or {}
    core = core or PsychopatzCore
    now = tonumber(now) or (PNC.Core and PNC.Core.Now and PNC.Core.Now()) or 0
    if not PNC.Registry or type(PNC.Registry.Data) ~= "table" then
        return 0
    end
    local intervalMs = tonumber(
        PNC.Const and PNC.Const.CORE_DEMOTE_PUMP_MS
    ) or 1000
    if options.force ~= true
        and now - (tonumber(Adapter.LastDemotePumpAt) or 0) < intervalMs
    then
        return 0
    end
    Adapter.LastDemotePumpAt = now
    Adapter.Metrics.demotePumps = (tonumber(Adapter.Metrics.demotePumps) or 0) + 1

    local maxPerPump = math.max(1, math.floor(tonumber(
        options.max or (PNC.Const and PNC.Const.CORE_DEMOTE_MAX_PER_PUMP) or 8
    )))
    local ids = {}
    for id, record in pairs(PNC.Registry.Data) do
        if type(record) == "table" and record.coreBacked == true then
            ids[#ids + 1] = tostring(id)
        end
    end
    if #ids == 0 then return 0 end
    table.sort(ids)

    local demoted = 0
    for i = 1, #ids do
        if demoted >= maxPerPump then break end
        local record = PNC.Registry.Data[ids[i]]
        if record and not Adapter.HasActiveHoomansResponsibility(record, now, options) then
            local ok = Adapter.DemoteCoreActor(record, core, {
                now = now,
                ignoreProximity = options.ignoreProximity,
                ignoreGrace = options.ignoreGrace,
            })
            if ok then
                demoted = demoted + 1
            end
        end
    end
    return demoted
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
    spec.provider = providerID(spec)
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
        provider = providerID(spec),
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
        provider = providerID(spec),
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
    record.runtime.coreProvider = providerID(spec)
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
    spec.provider = providerID(spec)
    spec.owner = owner(spec)
    return service.Release(actor, spec)
end

local function reconcileExistingWorld()
    if isServer and isServer() ~= true then return end
    if PsychopatzCore then
        local worldAdapter = PNC.CoreSurvivorWorldAdapter
        if worldAdapter
            and type(worldAdapter.ReconcileExistingWorld) == "function"
        then
            local report, reason = worldAdapter.ReconcileExistingWorld()
            if not report then
                if PNC.Core and PNC.Core.LogWarn then
                    PNC.Core.LogWarn(
                        "PNC Core SurvivorWorld reconciliation deferred"
                            .. " reason=" .. tostring(reason or "unknown")
                    )
                end
            elseif #report.failures > 0
                and PNC.Core and PNC.Core.LogWarn
            then
                PNC.Core.LogWarn(
                    "PNC Core SurvivorWorld reconciliation partial"
                        .. " failures=" .. tostring(#report.failures)
                )
            end
        end
    end
end

if Events and Events.OnInitGlobalModData
    and type(Events.OnInitGlobalModData.Add) == "function"
    and not Adapter.ReconcileInitHookRegistered
then
    Adapter.ReconcileInitHookRegistered = true
    Events.OnInitGlobalModData.Add(reconcileExistingWorld)
end

if Events and Events.OnServerStarted
    and type(Events.OnServerStarted.Add) == "function"
    and not Adapter.ReconcileServerHookRegistered
then
    Adapter.ReconcileServerHookRegistered = true
    Events.OnServerStarted.Add(reconcileExistingWorld)
end

return Adapter
