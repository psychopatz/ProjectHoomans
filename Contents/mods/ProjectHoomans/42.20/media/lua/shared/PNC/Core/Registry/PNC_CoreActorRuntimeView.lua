-- Transient ProjectHoomans runtime view of a canonical PsychopatzCore actor.
--
-- This adapter exists so Hoomans-owned gameplay/presentation systems can use
-- their normal record contracts for an actor that deliberately has no Hoomans
-- body or persistence record. Core remains authoritative for identity, social,
-- knowledge, appearance and world state.

PNC = PNC or {}
PNC.CoreActorRuntimeView = PNC.CoreActorRuntimeView or {}

local View = PNC.CoreActorRuntimeView
local Registry = PNC.Registry
local Const = PNC.Const or {}

local AFFILIATION_EXTENSION = "PsychopatzCore.SurvivorWorld"
local DEFAULT_CONVERSATION_ACCESS_MS = 15000
local MAX_CONVERSATION_ACCESS_MS = 30000

local function now()
    return PNC.Core and type(PNC.Core.Now) == "function"
        and PNC.Core.Now()
        or getTimeInMillis and getTimeInMillis()
        or 0
end

local function playerKey(player)
    if not player then return nil end
    local characters = PNC.PlayerCharacters
    if characters and type(characters.GetEntityKey) == "function" then
        local key = characters.GetEntityKey(player, {
            callback = "core_actor_runtime_view",
        })
        if key then return tostring(key) end
    end
    if player.getUsername then
        local username = tostring(player:getUsername() or "")
        if username ~= "" then return "username:" .. username end
    end
    if player.getOnlineID then
        local id = tostring(player:getOnlineID() or "")
        if id ~= "" then return "online:" .. id end
    end
    return nil
end

local function clone(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local output = {}
    seen[value] = output
    for key, child in pairs(value) do
        output[clone(key, seen)] = clone(child, seen)
    end
    return output
end

local function actors()
    local value = PsychopatzCore and PsychopatzCore.Actors or nil
    if value then return value end
    local ok, loaded = pcall(
        require,
        "PsychopatzCore/Actors/PsychopatzActors"
    )
    return ok and loaded or nil
end

local function coreSocial(actor, fallback)
    local adapter = PNC.Persistence
        and PNC.Persistence.CoreSocial or nil
    if actor and type(actor.social) == "table"
        and adapter
        and type(adapter.FromCoreSocial) == "function"
    then
        local projected = adapter.FromCoreSocial(
            actor.social,
            fallback
        )
        if type(projected) == "table" then return projected end
    end
    return clone(fallback or {})
end

local function portraitFor(actor)
    local api = actors()
    local presentation = api and api.Presentation or nil
    if presentation and type(presentation.BuildPortrait) == "function" then
        local portrait = presentation.BuildPortrait(actor)
        if type(portrait) == "table" then return portrait end
    end
    return nil
end

local function affiliationFor(actor)
    local extensions = actor
        and type(actor.extensions) == "table"
        and actor.extensions or {}
    local affiliation = extensions[AFFILIATION_EXTENSION]
    return type(affiliation) == "table"
        and clone(affiliation) or {}
end

local function identityFields(record, actor)
    local identity = type(actor.identity) == "table"
        and actor.identity or {}
    local survivor = type(identity.survivor) == "table"
        and identity.survivor or {}
    record.identity = clone(identity)
    record.identitySeed = identity.identitySeed or actor.actorId
    record.archetypeID = identity.archetypeID
    record.name = identity.displayName or actor.actorId
    record.displayName = record.name
    record.forename = survivor.forename
    record.surname = survivor.surname
    record.isFemale = tostring(identity.gender or survivor.gender or "")
        :lower() == "female"
    record.gender = identity.gender or survivor.gender
    record.voiceProfile = clone(survivor.voiceProfile or {})
end

local function presentationFields(record, actor)
    local portrait = portraitFor(actor)
    local resolved = type(actor.appearance) == "table"
        and type(actor.appearance.resolved) == "table"
        and actor.appearance.resolved or {}
    record.appearance = portrait
        and clone(portrait.appearance)
        or clone(resolved)
    record.equipment = portrait
        and clone(portrait.equipment)
        or { worn = {} }
    record.equipmentSummary = clone(record.equipment)
    record.portrait = portrait and clone(portrait) or nil
end

local function affiliationFields(record, actor)
    local affiliation = affiliationFor(actor)
    record.affiliation = affiliation
    record.factionID = affiliation.factionID
    record.factionId = affiliation.factionID
    record.communityID = affiliation.communityID
    record.communityId = affiliation.communityID
    record.groupID = affiliation.groupID
    record.groupId = affiliation.groupID
    record.role = affiliation.role
end

function View.Ensure(actorID, options)
    options = type(options) == "table" and options or {}
    actorID = tostring(actorID or "")
    if actorID == "" then return nil, "actor_id_required" end
    if not Registry or type(Registry.SetRuntimeView) ~= "function" then
        return nil, "runtime_view_registry_unavailable"
    end

    local api = actors()
    local actor = api and type(api.Get) == "function"
        and api.Get(actorID) or nil
    if type(actor) ~= "table" then return nil, "core_actor_not_found" end

    local persistent = Registry.Data
        and Registry.Data[actorID] or nil
    if persistent then return persistent, "persistent_record_exists" end

    local record = Registry.GetRuntimeView
        and Registry.GetRuntimeView(actorID) or nil
    local runtime = record and record.runtime or {}
    local priorSocial = record and record.social or nil
    record = record or {}

    record.id = actorID
    record.coreActorID = actorID
    record.ownerMod = actor.ownerMod
    record.persist = false
    record.runtimeView = true
    record.abstractOnly = options.abstractOnly ~= false
    record.presenceMode = "abstract"
    record.presenceState = Const.PRESENCE_ABSTRACT or "abstract"
    record.provider = options.provider
        or actor.providerLease and actor.providerLease.provider
        or actor.ownerMod
    record.providerState = options.providerState
        or actor.providerLease and actor.providerLease.state
        or "abstract"
    record.alive = true
    record.available = true
    record.runtime = runtime
    record.runtime.coreActorID = actorID
    record.runtime.abstractCoreActorView = true
    record.runtime.providerState = record.providerState
    record.recordRevision = tonumber(actor.revision) or 0
    record.coreRevision = tonumber(actor.revision) or 0

    identityFields(record, actor)
    presentationFields(record, actor)
    affiliationFields(record, actor)

    record.persona = clone(actor.persona or {})
    record.knowledge = clone(actor.knowledge or {})
    record.social = coreSocial(actor, priorSocial)
    record.personality = record.social
        and clone(record.social.personality) or {}
    record.socialProfile = clone(record.personality)

    local world = type(actor.world) == "table" and actor.world or {}
    local position = world.location and world.location.position
        or world.position
    if type(position) == "table" then
        record.x = tonumber(position.x) or record.x or 0
        record.y = tonumber(position.y) or record.y or 0
        record.z = tonumber(position.z) or record.z or 0
    end

    if options.tacticalClass ~= nil then
        record.tacticalClass = tostring(options.tacticalClass)
    elseif record.tacticalClass == nil then
        record.tacticalClass = "neutral"
    end

    if options.trader == true then
        record.worldRole = "trader"
        record.roles = record.roles or {}
        record.roles.trader = true
    end

    return Registry.SetRuntimeView(record)
end

function View.GrantConversationAccess(
    actorOrRecord,
    player,
    source,
    ttlMs
)
    local record = type(actorOrRecord) == "table"
        and actorOrRecord
        or View.Get(actorOrRecord)
    if type(record) ~= "table"
        or record.runtimeView ~= true
        or record.abstractOnly ~= true
    then
        return false, "abstract_runtime_view_required"
    end
    local key = playerKey(player)
    if not key then return false, "player_identity_unavailable" end

    ttlMs = math.max(
        1000,
        math.min(
            MAX_CONVERSATION_ACCESS_MS,
            math.floor(
                tonumber(ttlMs)
                    or DEFAULT_CONVERSATION_ACCESS_MS
            )
        )
    )
    record.runtime = record.runtime or {}
    record.runtime.abstractConversationAccess =
        record.runtime.abstractConversationAccess or {}
    record.runtime.abstractConversationAccess[key] = {
        expiresAt = now() + ttlMs,
        source = tostring(source or "remote"),
    }
    return true, key
end

function View.ConsumeConversationAccess(
    actorOrRecord,
    player,
    currentTime
)
    local record = type(actorOrRecord) == "table"
        and actorOrRecord
        or View.Get(actorOrRecord)
    if type(record) ~= "table" then
        return false, "runtime_view_unavailable"
    end
    local key = playerKey(player)
    if not key then return false, "player_identity_unavailable" end
    local access = record.runtime
        and record.runtime.abstractConversationAccess or nil
    local grant = access and access[key] or nil
    if type(grant) ~= "table" then
        return false, "abstract_access_denied"
    end
    currentTime = tonumber(currentTime) or now()
    if currentTime > (tonumber(grant.expiresAt) or 0) then
        access[key] = nil
        return false, "abstract_access_expired"
    end
    access[key] = nil
    return true, grant.source
end

function View.Remove(actorID)
    if not Registry or type(Registry.RemoveRuntimeView) ~= "function" then
        return false
    end
    return Registry.RemoveRuntimeView(actorID)
end

function View.Get(actorID)
    return Registry and Registry.GetRuntimeView
        and Registry.GetRuntimeView(actorID) or nil
end

return View
