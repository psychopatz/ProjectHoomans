-- World-target adapter for refill plans.
--
-- NearbyWater may return live Java objects while it is discovering a source.
-- This adapter converts that read-only discovery into the primitive target
-- assignment required by MOVE_TO. The refill provider resolves the source
-- again at commit time; no Java object is retained in the action plan.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Resolver = PNC.Semantics.WorldTargetResolver
local Water = PNC.NearbyWaterService

local function text(value)
    value = tostring(value or "")
    return value ~= "" and value or nil
end

local function resolveFillSource(target, context)
    context = type(context) == "table" and context or {}
    local record = context.record
    local wantedKey = target and (target.sourceKey
        or target.resourceKey or target.targetID or target.id)
    local source
    local reason
    local approach

    if not record then return nil, "npc_required" end
    if not Water or type(Water.ResolveFillSource) ~= "function" then
        return nil, "water_service_unavailable"
    end

    source, reason = Water.ResolveFillSource(record, wantedKey)
    if not source then
        return nil, reason or "WATER_FILL_SOURCE_UNAVAILABLE"
    end
    if not source.object then
        return nil, "WATER_FILL_SOURCE_OBJECT_UNAVAILABLE"
    end
    if type(Water.BuildApproach) ~= "function" then
        return nil, "WATER_APPROACH_UNAVAILABLE"
    end

    approach, reason = Water.BuildApproach(record, source)
    if not approach then
        return nil, reason or "WATER_APPROACH_UNAVAILABLE"
    end
    if tonumber(approach.x) == nil or tonumber(approach.y) == nil then
        return nil, "WATER_APPROACH_POSITION_MISSING"
    end

    return {
        kind = "water_fill_source",
        targetID = text(source.key),
        resourceKey = text(source.key),
        x = tonumber(approach.x),
        y = tonumber(approach.y),
        z = tonumber(approach.z) or 0,
        mode = text(target and target.mode) or "walk",
        stopDistance = math.max(0.25,
            tonumber(target and target.stopDistance) or 1.25),
        -- A faucet is stationary. Keep the assignment stable while the NPC
        -- walks; the commit provider still re-resolves the source by key.
        dynamic = false,
        interactionFacing = text(approach.interactionFacing),
        approachKey = text(approach.approachKey),
    }
end

if Resolver and type(Resolver.Register) == "function" then
    Resolver.Register("water_fill_source", resolveFillSource)
    Resolver.Register("water_refill_source", resolveFillSource)
end
if Resolver and type(Resolver.RegisterAlias) == "function" then
    Resolver.RegisterAlias("water fill source", "water_fill_source")
    Resolver.RegisterAlias("water refill source", "water_refill_source")
end

return Resolver
