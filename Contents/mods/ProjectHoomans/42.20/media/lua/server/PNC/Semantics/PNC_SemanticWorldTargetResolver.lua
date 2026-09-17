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
local Catalog = PNC.Semantics.WorldTargetCatalog
    or require "PNC/Semantics/PNC_SemanticWorldTargetCatalog"

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

local function validClientHint(target, kind, origin, radius)
    local raw = target and target.clientHint
    local hintKind
    local x
    local y
    local z
    local originX
    local originY
    local originZ
    local maximum
    local dx
    local dy
    if type(raw) ~= "table" then return nil end
    hintKind = lower(raw.kind)
    hintKind = string.gsub(hintKind, "[%s%-]+", "_")
    if hintKind ~= "" and hintKind ~= lower(kind) then
        return nil, "client_hint_kind_mismatch"
    end
    if hintKind ~= ""
        and Catalog and type(Catalog.Get) == "function"
        and not Catalog.Get(hintKind)
    then
        return nil, "client_hint_kind_unknown"
    end
    if Catalog and type(Catalog.Normalize) == "function"
        and raw.query ~= nil
    then
        local requested = target and (target.text or target.value
            or target.category or target.concept or target.id) or ""
        local requestedKey = Catalog.Normalize(requested)
        local queryKey = Catalog.Normalize(raw.query)
        if requestedKey ~= "" and queryKey ~= ""
            and requestedKey ~= queryKey
        then
            return nil, "client_hint_query_mismatch"
        end
    end
    x = number(raw.x)
    y = number(raw.y)
    z = number(raw.z) or 0
    if x == nil or y == nil
        or math.abs(x) > 1000000 or math.abs(y) > 1000000
    then
        return nil, "client_hint_coordinates_invalid"
    end
    originX = number(call(origin, "getX"))
    originY = number(call(origin, "getY"))
    originZ = number(call(origin, "getZ")) or 0
    if originX == nil or originY == nil then
        return nil, "world_origin_unavailable"
    end
    maximum = math.max(4, math.min(Resolver.MAX_RADIUS,
        (number(radius) or 12) + 4))
    dx = x - number(originX)
    dy = y - number(originY)
    if dx * dx + dy * dy > maximum * maximum
        or math.abs(z - number(originZ)) > 1
    then
        return nil, "client_hint_out_of_range"
    end
    return {
        kind = hintKind,
        x = x,
        y = y,
        z = z,
        score = number(raw.score),
    }
end

local function nearClientHint(entry, hint, maximum)
    if not entry or not hint then return false end
    local x = number(entry.x)
    local y = number(entry.y)
    local z = number(entry.z) or 0
    if x == nil or y == nil then return false end
    local dx = x - hint.x
    local dy = y - hint.y
    maximum = number(maximum) or 2.5
    return dx * dx + dy * dy <= maximum * maximum
        and math.abs(z - hint.z) <= 1
end

local function hintKey(hint)
    if not hint then return "" end
    return tostring(math.floor(hint.x * 10)) .. ":"
        .. tostring(math.floor(hint.y * 10)) .. ":"
        .. tostring(math.floor(hint.z * 10))
end

Resolver.ValidateClientHint = validClientHint
Resolver.NearClientHint = nearClientHint
Resolver.ClientHintKey = hintKey

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

local function listSize(list)
    local size = call(list, "size")
    if size ~= nil then return math.max(0, math.floor(number(size) or 0)) end
    if type(list) == "table" then return #list end
    return 0
end

local function listItem(list, index)
    local item = call(list, "get", index)
    if item ~= nil then return item end
    if type(list) == "table" then return list[index + 1] end
    return nil
end

local function campfireIDMatches(wanted, key, objectID)
    local wantedText = text(wanted)
    local keyText = text(key)
    local objectText = tostring(objectID or "")
    local coordinateKey = wantedText
        and string.match(wantedText, "^([^#]+)#") or nil
    if not wantedText then return true end
    return wantedText == keyText
        or wantedText == objectText
        or coordinateKey ~= nil and coordinateKey == keyText
end

local function isCampfire(entry, requestedID)
    local object = entry and entry.object
    local key = text(entry and entry.key)
    local objectID = call(object, "getID")
    if not campfireIDMatches(requestedID, key, objectID) then
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

local function cellFor(context)
    if type(context) == "table" and context.cell then
        return context.cell
    end
    if type(getCell) == "function" then
        local ok, cell = pcall(getCell)
        if ok then return cell end
    end
    return nil
end

local function campfireEntryOnSquare(square, requestedID)
    local x = number(call(square, "getX"))
    local y = number(call(square, "getY"))
    local z = number(call(square, "getZ")) or 0
    local global = globalCampfireForSquare(square)
    local objects
    local index
    if x == nil or y == nil then return nil end
    if global and isCampfire(global, requestedID) then
        global.x = x + 0.5
        global.y = y + 0.5
        global.z = z
        return global
    end
    objects = call(square, "getObjects")
    for index = 0, listSize(objects) - 1 do
        local object = listItem(objects, index)
        local objectID = call(object, "getID")
        local key = objectID and "campfire@" .. tostring(x) .. ":"
            .. tostring(y) .. ":" .. tostring(z) .. "#"
            .. tostring(objectID)
            or "campfire@" .. tostring(x) .. ":" .. tostring(y) .. ":"
                .. tostring(z)
        local entry = {
            object = object,
            source = "square_object",
            key = key,
            x = x + 0.5,
            y = y + 0.5,
            z = z,
        }
        if isCampfire(entry, requestedID) then return entry end
    end
    return nil
end

-- Validate one client-observed campfire square without falling back to the
-- broad server locator. Direct player commands must remain cheap even when a
-- multiplayer server has many simultaneous command requests.
function Resolver.ValidateCampfireHint(target, context)
    local raw = target and target.clientHint
    local origin = originFor(context)
    local radius = boundedRadius(target and target.radius, 16)
    local hint
    local reason
    local cell
    local square
    local requestedID
    local entry
    local result
    if type(raw) ~= "table" then return nil, "campfire_hint_required" end
    hint, reason = validClientHint(target, "campfire", origin, radius)
    if not hint then return nil, reason or "campfire_hint_invalid" end
    cell = cellFor(context)
    if not cell or type(cell.getGridSquare) ~= "function" then
        return nil, "campfire_validation_unavailable"
    end
    local ok
    ok, square = pcall(cell.getGridSquare, cell,
        math.floor(hint.x), math.floor(hint.y), math.floor(hint.z))
    if not ok or not square then return nil, "campfire_hint_not_loaded" end
    requestedID = raw.campfireID or target.campfireID or target.fireID
    entry = campfireEntryOnSquare(square, requestedID)
    if not entry then return nil, "campfire_hint_stale" end
    result = primitiveTarget({
        kind = "campfire",
        targetID = entry.key,
        x = entry.x,
        y = entry.y,
        z = entry.z,
        mode = target.mode,
        stopDistance = target.stopDistance or 1.25,
    }, "campfire")
    if not result then return nil, "campfire_position_unavailable" end
    result.objectKind = "campfire"
    result.resourceKey = entry.key
    result.clientHintAccepted = true
    return result
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
    local hint, hintReason = validClientHint(target, "campfire", origin, radius)
    local hintPresent = target and type(target.clientHint) == "table"
    local function find(useHint)
        local key = "semantic_campfire:" .. tostring(wantedID or "nearest")
        if useHint then key = key .. ":hint:" .. hintKey(hint) end
        return Locator.FindObject(origin, {
            radius = radius,
            cacheMs = tonumber(target and target.cacheMs)
                or Resolver.OBJECT_CACHE_MS,
            cacheKey = key,
            accept = function(candidate)
                if not isCampfire(candidate, wantedID) then return false end
                return not useHint or nearClientHint(candidate, hint, 2.5)
            end,
            specialObject = globalCampfireForSquare,
        })
    end
    local entry
    local hintAccepted = false
    if not origin then return nil, "world_origin_unavailable" end
    if not Locator or type(Locator.FindObject) ~= "function" then
        return nil, "world_locator_unavailable"
    end
    if hint then
        entry = find(true)
        hintAccepted = entry ~= nil
    end
    if not entry then entry = find(false) end
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
    result.clientHintAccepted = hintAccepted
    result.clientHintRejected = hintPresent and not hintAccepted
    result.clientHintReason = hintReason
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
    if Catalog and type(Catalog.ResolveKind) == "function" then
        local mapped = Catalog.ResolveKind(target)
        if mapped then return mapped end
    end
    -- A client may correct a misspelled surface phrase, but the hinted kind is
    -- usable only if this server already has a registered provider for it.
    local hint = target.clientHint
    local hintedKind = hint and lower(hint.kind) or ""
    hintedKind = string.gsub(hintedKind, "[%s%-]+", "_")
    if hintedKind ~= "" and Resolver.Providers[hintedKind]
        and (not Catalog or type(Catalog.Get) ~= "function"
            or Catalog.Get(hintedKind) ~= nil)
    then
        return hintedKind
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
    bounded.clientHintAccepted = result.clientHintAccepted == true
    bounded.clientHintRejected = result.clientHintRejected == true
    bounded.clientHintReason = text(result.clientHintReason)
    return traceResolution(target, context, kind, bounded, nil)
end

Resolver.Register("campfire", resolveCampfire)
Resolver.Register("fire", resolveCampfire)
Resolver.Register("player", resolvePlayer)

-- Object providers live in their own spoke so the resolver remains a small
-- registry/contract boundary as Project Hoomans adds more world vocabulary.
require "PNC/Semantics/PNC_SemanticWorldTargetResolver_Objects"

return Resolver
