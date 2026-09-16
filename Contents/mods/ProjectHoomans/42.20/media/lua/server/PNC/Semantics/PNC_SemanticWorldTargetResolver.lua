-- Resolve semantic world targets into bounded primitive assignments.
--
-- This boundary is deliberately read-only.  It may inspect the loaded world
-- while resolving a step, but it never stores Java objects in an action plan
-- and never performs the resulting gameplay action.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.Semantics.WorldTargetResolver =
    PNC.Semantics.WorldTargetResolver or {}

require "PNC/Semantics/PNC_SemanticDiagnostics"

local Resolver = PNC.Semantics.WorldTargetResolver
local Locator = PNC.NearbyResourceLocator
local FacilityTargets = PNC.FacilityInteractionTargets
local Diagnostics = PNC.Semantics.SemanticDiagnostics

Resolver.Providers = Resolver.Providers or {}
Resolver.Aliases = Resolver.Aliases or {}
Resolver.MAX_RADIUS = Resolver.MAX_RADIUS or 32
Resolver.DEFAULT_STOP_DISTANCE = Resolver.DEFAULT_STOP_DISTANCE or 0.9
Resolver.OBJECT_CACHE_MS = Resolver.OBJECT_CACHE_MS or 1000

local function number(value)
    return tonumber(value)
end

local function text(value)
    local result = tostring(value or "")
    return result ~= "" and result or nil
end

local function lower(value)
    return string.lower(tostring(value or ""))
end

local function call(object, method, ...)
    local fn = object and object[method]
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, object, ...)
    return ok and value or nil
end

local function boundedRadius(value, fallback)
    return math.max(0, math.min(Resolver.MAX_RADIUS,
        math.floor(number(value) or fallback or 12)))
end

local function primitiveTarget(raw, fallbackKind)
    if type(raw) ~= "table" then return nil end
    local x = number(raw.x or raw.targetX)
    local y = number(raw.y or raw.targetY)
    local z = number(raw.z or raw.targetZ) or 0
    if x == nil or y == nil then return nil end
    return {
        kind = text(raw.kind) or fallbackKind or "world_point",
        targetID = text(raw.targetID or raw.id or raw.resourceKey
            or raw.key),
        x = x,
        y = y,
        z = z,
        mode = text(raw.mode) or "walk",
        stopDistance = math.max(0.25, number(raw.stopDistance)
            or Resolver.DEFAULT_STOP_DISTANCE),
        dynamic = raw.dynamic == true,
    }
end

local function abstractOrigin(record)
    if not record then return nil end
    if type(record.getX) == "function" then return record end
    local x = number(record.x)
    local y = number(record.y)
    local z = number(record.z) or 0
    if x == nil or y == nil then return nil end
    -- The locator only needs these read methods.  This adapter is created
    -- during a bounded resolve, never retained in the plan or cache.
    return {
        getX = function() return x end,
        getY = function() return y end,
        getZ = function() return z end,
    }
end

local function originFor(context)
    context = type(context) == "table" and context or {}
    return context.origin or context.body or abstractOrigin(context.record)
end

local function traceResolution(target, context, kind, result, reason)
    local trace = PsychopatzCore and PsychopatzCore.DebugTrace
    local semanticAudit = Diagnostics
        and type(Diagnostics.IsEnabled) == "function"
        and Diagnostics.IsEnabled() == true
    local legacyTrace = trace
        and type(trace.IsEnabled) == "function"
        and trace.IsEnabled() == true
        and type(trace.Record) == "function"
    if not semanticAudit and not legacyTrace
    then
        return result, reason
    end
    context = type(context) == "table" and context or {}
    local record = context.record
    local origin = originFor(context)
    local definition = {
        source = "ProjectHoomans.Semantics",
        event = "semantic.world_target.resolve",
        requestID = context.requestID or context.planID,
        data = {
        npcID = record and (record.id or record.npcID),
        planID = context.planID,
        targetText = text(target and (target.text or target.value
            or target.category or target.concept or target.id)),
        requestedKind = text(target and target.kind),
        resolvedKind = text(kind or result and result.kind),
        status = result and "resolved" or "failed",
        reason = reason,
        radius = number(target and target.radius),
        originX = origin and call(origin, "getX") or nil,
        originY = origin and call(origin, "getY") or nil,
        originZ = origin and call(origin, "getZ") or nil,
        targetID = result and result.targetID,
        targetX = result and result.x,
        targetY = result and result.y,
        targetZ = result and result.z,
        },
    }
    if semanticAudit then
        Diagnostics.Record(
            "semantic.world_target.resolve",
            definition.data,
            { requestID = definition.requestID }
        )
    else
        trace.Record(definition)
    end
    return result, reason
end

local function objectName(object)
    return lower(call(object, "getObjectName")
        or call(object, "getName"))
end

local function globalCampfireForSquare(square)
    local campfire = call(square, "getCampfire")
    local x
    local y
    local z
    if not campfire then return nil end
    x = call(campfire, "getX") or call(square, "getX")
    y = call(campfire, "getY") or call(square, "getY")
    z = call(campfire, "getZ") or call(square, "getZ")
    if x == nil or y == nil then return nil end
    return {
        object = campfire,
        source = "global_campfire",
        key = "campfire@" .. tostring(x) .. ":" .. tostring(y)
            .. ":" .. tostring(z or 0),
    }
end

local function isCampfire(entry, requestedID)
    local object = entry and entry.object
    local key = text(entry and entry.key)
    local objectID = call(object, "getID")
    local wanted = text(requestedID)
    if wanted and wanted ~= key and wanted ~= tostring(objectID or "") then
        return false
    end
    if entry and entry.source == "global_campfire" then return true end
    local campfire = call(object, "isCampfire")
    if campfire == true then return true end
    local container = call(object, "getContainer")
    if lower(call(container, "getType")) == "campfire" then return true end
    local name = objectName(object)
    return string.find(name, "campfire", 1, true) ~= nil
end

local function resolvePlayer(target, context)
    context = type(context) == "table" and context or {}
    local runtime = type(context.runtime) == "table"
        and context.runtime or {}
    local player = runtime.player
    local x = call(player, "getX")
    local y = call(player, "getY")
    local z = call(player, "getZ") or 0
    if x == nil or y == nil then return nil, "player_target_unavailable" end

    local resolved = primitiveTarget({
        kind = "player",
        targetID = target and target.targetID or "player",
        x = x,
        y = y,
        z = z,
        mode = target and target.mode,
        stopDistance = target and target.stopDistance or 1.25,
        dynamic = true,
    }, "player")
    if not resolved then return nil, "player_position_unavailable" end
    resolved.dynamic = true
    return resolved
end

local function resolveCampfire(target, context)
    local origin = originFor(context)
    local radius = boundedRadius(target and target.radius, 16)
    local wantedID = target and (target.targetID or target.id
        or target.objectID)
    if not origin then return nil, "world_origin_unavailable" end
    if not Locator or type(Locator.FindObject) ~= "function" then
        return nil, "world_locator_unavailable"
    end
    local entry = Locator.FindObject(origin, {
        radius = radius,
        cacheMs = tonumber(target and target.cacheMs)
            or Resolver.OBJECT_CACHE_MS,
        cacheKey = "semantic_campfire:" .. tostring(wantedID or "nearest"),
        accept = function(candidate)
            return isCampfire(candidate, wantedID)
        end,
        specialObject = globalCampfireForSquare,
    })
    if not entry then return nil, "campfire_not_found" end
    local result = primitiveTarget({
        kind = "campfire",
        targetID = entry.key,
        x = entry.x,
        y = entry.y,
        z = entry.z,
        mode = target and target.mode,
        -- Stop outside the object tile.  A later interaction provider can
        -- add a more precise approach spot without changing this contract.
        stopDistance = target and target.stopDistance or 1.25,
    }, "campfire")
    if not result then return nil, "campfire_position_unavailable" end
    result.objectKind = "campfire"
    result.resourceKey = entry.key
    return result
end

function Resolver.Register(kind, provider)
    kind = lower(kind)
    if kind == "" or type(provider) ~= "function" then
        return false, "invalid_world_target_provider"
    end
    Resolver.Providers[kind] = provider
    return true, provider
end

local function aliasKey(value)
    value = lower(value)
    value = string.gsub(value, "[%s%-_]+", " ")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    -- Articles belong to the surface phrase, not to the world-target key.
    -- This keeps resolver behavior stable if a grammar chooses to retain
    -- "the"/"a" in a captured object phrase.
    value = string.gsub(value, "^(the|a|an|nearest)%s+", "")
    return value
end

function Resolver.RegisterAlias(alias, kind)
    local key = aliasKey(alias)
    kind = lower(kind)
    if key == "" or kind == "" then
        return false, "invalid_world_target_alias"
    end
    Resolver.Aliases[key] = kind
    return true, kind
end

function Resolver.ResolveKind(target)
    if type(target) ~= "table" then return nil end
    local explicit = lower(target.kind)
    if explicit ~= "" and explicit ~= "phrase"
        and explicit ~= "concept" and explicit ~= "literal"
    then
        return explicit
    end
    local values = {
        target.category,
        target.concept,
        target.id,
        target.value,
        target.text,
    }
    for index = 1, #values do
        local key = aliasKey(values[index])
        local mapped = Resolver.Aliases[key]
        if mapped then return mapped end
    end
    return nil
end

local function resolveFacilityResource(target, context)
    if not FacilityTargets or type(FacilityTargets.ResolveResource)
        ~= "function"
    then
        return nil, "facility_target_resolver_unavailable"
    end
    local resource = target.resource or target
    local ok, targets = pcall(FacilityTargets.ResolveResource, resource,
        context or {})
    if not ok or type(targets) ~= "table" then
        return nil, "facility_target_resolution_failed"
    end
    for index = 1, #targets do
        local resolved = primitiveTarget(targets[index],
            targets[index].kind or resource.resourceKind or "resource")
        if resolved and targets[index].validSpot ~= false then
            return resolved
        end
    end
    return nil, "facility_target_unavailable"
end

function Resolver.Resolve(target, context)
    if type(target) ~= "table" then
        return traceResolution(target, context, nil, nil,
            "world_target_required")
    end
    local direct = primitiveTarget(target)
    if direct then
        return traceResolution(target, context, direct.kind, direct, nil)
    end

    local kind = Resolver.ResolveKind(target)
        or lower(target.type or target.resourceKind or target.kind)
    if kind == "resource" or kind == "facility_resource"
        or kind == "interaction_resource"
    then
        local result, reason = resolveFacilityResource(target, context)
        return traceResolution(target, context, kind, result, reason)
    end

    local provider = Resolver.Providers[kind]
    if not provider then
        return traceResolution(target, context, kind, nil,
            "world_target_kind_unsupported")
    end
    local ok, result, reason = pcall(provider, target, context or {})
    if not ok then
        return traceResolution(target, context, kind, nil,
            "world_target_provider_failed")
    end
    if not result then
        return traceResolution(target, context, kind, nil,
            reason or "world_target_unresolved")
    end
    local bounded = primitiveTarget(result, kind)
    if not bounded then
        return traceResolution(target, context, kind, nil,
            "world_target_assignment_invalid")
    end
    bounded.objectKind = text(result.objectKind)
    bounded.resourceKey = text(result.resourceKey)
    return traceResolution(target, context, kind, bounded, nil)
end

Resolver.Register("campfire", resolveCampfire)
Resolver.Register("fire", resolveCampfire)
Resolver.Register("player", resolvePlayer)

-- Object providers live in their own spoke so the resolver remains a small
-- registry/contract boundary as Project Hoomans adds more world vocabulary.
require "PNC/Semantics/PNC_SemanticWorldTargetResolver_Objects"

return Resolver
