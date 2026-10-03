if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.Semantics.WorldTargetResolver = PNC.Semantics.WorldTargetResolver or {}

local Resolver = PNC.Semantics.WorldTargetResolver
local Locator = PNC.NearbyResourceLocator
local FacilityTargets = PNC.FacilityInteractionTargets
local Catalog = PNC.Semantics.WorldTargetCatalog
    or require "PNC/Semantics/PNC_SemanticWorldTargetCatalog"
local CampSite = PNC.Semantics.CampSite
    or require "PNC/Semantics/PNC_SemanticCampSite"
local Deps = Resolver._Deps or {}
local number = Deps.number
local text = Deps.text
local lower = Deps.lower
local call = Deps.call
local boundedRadius = Deps.boundedRadius
local validClientHint = Deps.validClientHint
local nearClientHint = Deps.nearClientHint
local hintKey = Deps.hintKey
local primitiveTarget = Deps.primitiveTarget
local originFor = Deps.originFor
local traceResolution = Deps.traceResolution
local globalCampfireForSquare = Deps.globalCampfireForSquare
local listSize = Deps.listSize
local listItem = Deps.listItem
local campfireIDMatches = Deps.campfireIDMatches
local isCampfire = Deps.isCampfire
local cellFor = Deps.cellFor
local campfireEntryOnSquare = Deps.campfireEntryOnSquare

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
    square = cell:getGridSquare(
        math.floor(hint.x), math.floor(hint.y), math.floor(hint.z))
    if not square then return nil, "campfire_hint_not_loaded" end
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
