-- Bounded Hoomans adapter for authoritative world-state transitions.
--
-- The exact Build 42.20 Lua binding for each global utility is not frozen in
-- this repository. Readers are therefore injected by the verified authority
-- owner. An absent or failing reader is explicitly unknown; this module never
-- turns a guessed default into a world fact.

PNC = PNC or {}
local Adapter = PNC.WorldKnowledge
if not Adapter then return nil end

Adapter.WorldState = Adapter.WorldState or { last = nil, sequence = {} }
Adapter.PropagationTrace = Adapter.PropagationTrace or {}

local DOMAINS = { "helicopter", "power", "water", "season" }

local function now()
    local gameTime = getGameTime and getGameTime() or nil
    if gameTime and type(gameTime.getWorldAgeHours) == "function" then
        return tonumber(gameTime:getWorldAgeHours()) or 0
    end
    return 0
end

local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, item in pairs(value) do result[key] = copy(item) end
    return result
end

local function normalize(domain, value, source)
    if type(value) == "table" then
        source = value.source or source
        if value.known == false or value.status == "unknown" then
            return { known = false, status = "unknown",
                reason = tostring(value.reason or "authority_unknown"),
                source = source }
        end
        value = value.value ~= nil and value.value or value.status
    end
    if value == nil then
        return { known = false, status = "unknown",
            reason = "authority_unknown", source = source }
    end
    if domain == "season" then
        local text = tostring(value)
        if text == "" or text == "unknown" then
            return { known = false, status = "unknown",
                reason = "season_authority_unknown", source = source }
        end
        return { known = true, value = text, status = text, source = source }
    end
    if type(value) ~= "boolean" then
        return { known = false, status = "unknown",
            reason = "boolean_authority_invalid", source = source }
    end
    return { known = true, value = value,
        status = value and "on" or "off", source = source }
end

local function read(reader, domain)
    if type(reader) ~= "function" then
        return normalize(domain, nil, "reader_unavailable")
    end
    local ok, value, source = pcall(reader)
    if not ok then
        return { known = false, status = "unknown",
            reason = "authority_reader_error", source = domain }
    end
    return normalize(domain, value, source or domain)
end

function Adapter.ResetWorldStateRuntime()
    Adapter.WorldState = { last = nil, sequence = {} }
    Adapter.PropagationTrace = {}
end

function Adapter.ReadAuthoritativeWorldState(readers)
    readers = type(readers) == "table" and readers or {}
    local result = {}
    for index = 1, #DOMAINS do
        local domain = DOMAINS[index]
        result[domain] = read(readers[domain], domain)
    end
    return result
end

local function defaultWorld()
    if type(getWorld) ~= "function" then return nil end
    local ok, world = pcall(getWorld)
    return ok and world or nil
end

function Adapter.DefaultAuthorityReaders()
    return {
        helicopter = function()
            local world = defaultWorld()
            local helicopter = world and world.helicopter or nil
            if helicopter and type(helicopter.isActive) == "function" then
                return helicopter:isActive(), "IsoWorld.helicopter:isActive"
            end
            if world and type(world.getHelicopter) == "function" then
                local ok, value = pcall(world.getHelicopter, world)
                helicopter = ok and value or nil
                if helicopter and type(helicopter.isActive) == "function" then
                    return helicopter:isActive(), "IsoWorld:getHelicopter:isActive"
                end
            end
            return nil, "helicopter_api_unavailable"
        end,
        power = function()
            local world = defaultWorld()
            if world and type(world.isHydroPowerOn) == "function" then
                return world:isHydroPowerOn(), "IsoWorld:isHydroPowerOn"
            end
            return nil, "power_api_unavailable"
        end,
        water = function()
            return nil, "water_global_authority_unverified"
        end,
        season = function()
            if type(getClimateManager) == "function" then
                local ok, climate = pcall(getClimateManager)
                if ok and climate and type(climate.getSeasonName) == "function" then
                    return climate:getSeasonName(), "ClimateManager:getSeasonName"
                end
            end
            return nil, "season_api_unavailable"
        end,
    }
end

function Adapter.ObserveDefaultAuthority(options)
    return Adapter.ObserveAuthoritativeWorldState(
        Adapter.DefaultAuthorityReaders(), options)
end

local function changed(previous, current)
    if not previous or previous.known ~= true then return true end
    return previous.status ~= current.status
end

function Adapter.PublishWorldStateTransition(previous, current, options)
    options = type(options) == "table" and options or {}
    current = type(current) == "table" and current or {}
    local facts = {}
    local at = tonumber(options.at) or now()
    for index = 1, #DOMAINS do
        local domain = DOMAINS[index]
        local state = current[domain]
        if state and state.known == true
            and changed(previous and previous[domain], state)
            and Adapter.Core
        then
            local sequence = (Adapter.WorldState.sequence[domain] or 0) + 1
            Adapter.WorldState.sequence[domain] = sequence
            local prior = previous and previous[domain] or nil
            local fact = Adapter.Publish({
                producer = "hoomans:pz_world",
                kind = "world.state",
                subject = { id = "world:" .. domain, kind = "world_state" },
                eventID = "world:" .. domain .. ":" .. tostring(sequence),
                occurredAt = at, observedAt = at,
                severity = domain == "helicopter" and 0.7 or 0.4,
                retention = prior and "historical" or "derived_current",
                payload = {
                    domain = domain, status = state.status, value = state.value,
                    previousStatus = prior and prior.status or nil,
                    source = tostring(state.source or options.source or "authority"),
                    transition = prior and "changed" or "initial",
                },
            })
            if fact then facts[#facts + 1] = fact end
        end
    end
    return facts
end

function Adapter.ObserveAuthoritativeWorldState(readers, options)
    options = type(options) == "table" and options or {}
    local current = Adapter.ReadAuthoritativeWorldState(readers)
    local previous = Adapter.WorldState.last
    local facts = Adapter.PublishWorldStateTransition(previous, current, options)
    Adapter.WorldState.last = copy(current)
    return current, facts
end

function Adapter.AcquirePublicFact(record, factID, options)
    options = type(options) == "table" and options or {}
    if options.authorized ~= true then return nil, "public_authorization_required" end
    local core = Adapter.Core
    local id = Adapter.ActorID(record)
    if not core or not id then return nil, "actor_invalid" end
    return core.Acquire(id, factID, {
        authorized = true,
        provenance = options.provenance or "public",
        confidence = options.confidence or 0.8,
        source = options.source or "public_authority",
        acquisitionPath = options.acquisitionPath or "public",
        learnedAt = options.learnedAt or now(),
    })
end

local function addTrace(entry)
    Adapter.PropagationTrace[#Adapter.PropagationTrace + 1] = entry
    while #Adapter.PropagationTrace > 64 do
        table.remove(Adapter.PropagationTrace, 1)
    end
end

function Adapter.PropagateConversation(fromRecord, toRecord, options)
    options = type(options) == "table" and options or {}
    local channel = tostring(options.channel or "conversation")
    if options.authorized ~= true then
        addTrace({ fromActorID = Adapter.ActorID(fromRecord),
            toActorID = Adapter.ActorID(toRecord), channel = channel,
            accepted = false, reason = "propagation_authorization_required" })
        return nil, "propagation_authorization_required"
    end
    if channel ~= "conversation" and channel ~= "radio"
        and channel ~= "faction"
    then
        addTrace({ fromActorID = Adapter.ActorID(fromRecord),
            toActorID = Adapter.ActorID(toRecord), channel = channel,
            accepted = false, reason = "propagation_channel_invalid" })
        return nil, "propagation_channel_invalid"
    end
    if not Adapter.Core then return nil, "core_world_knowledge_unavailable" end
    local transferred, reason = Adapter.Core.Share(
        Adapter.ActorID(fromRecord), Adapter.ActorID(toRecord), {
            authorized = true,
            max = options.max or 3,
            now = options.now or now(),
            cooldown = options.cooldown or 24,
            provenance = channel == "radio" and "radio" or "told",
            source = options.source or channel,
            acquisitionPath = options.acquisitionPath or channel,
            confidence = options.confidence or 0.85,
        })
    addTrace({ fromActorID = Adapter.ActorID(fromRecord),
        toActorID = Adapter.ActorID(toRecord), channel = channel,
        accepted = transferred ~= nil, reason = reason,
        transferred = transferred and copy(transferred) or {} })
    return transferred, reason
end

return Adapter
