if isClient and isClient() and (not isServer or not isServer()) then return end

PNC = PNC or {}
PNC.FacilityInteractionTargets = PNC.FacilityInteractionTargets or {}

local Targets = PNC.FacilityInteractionTargets
Targets.Resolvers = Targets.Resolvers or {}
Targets.Cache = Targets.Cache or {}

function Targets.Register(id, resolver)
    if type(id) ~= "string" or id == "" or type(resolver) ~= "function" then
        return false, "INVALID_RESOLVER"
    end
    Targets.Resolvers[id] = resolver
    return true
end

function Targets.Invalidate(componentId)
    Targets.Cache[tostring(componentId or "")] = nil
end

function Targets.Resolve(component, context)
    if type(component) ~= "table" or component.kind ~= "anchor" then return {} end
    local cached = Targets.Cache[component.id]
    if cached and cached.revision == component.revision then return cached.targets end
    local resolver = Targets.Resolvers[component.targetResolver]
    local targets = resolver and resolver(component, context) or nil
    if type(targets) ~= "table" or #targets == 0 then
        targets = { { x = component.x, y = component.y, z = component.z } }
    end
    Targets.Cache[component.id] = { revision = component.revision, targets = targets }
    return targets
end

function Targets.ReportPathFailure(componentId)
    Targets.Invalidate(componentId)
end

Targets.Register("worldObject", function(component)
    if PNC.WorldObjectTargetResolvers
        and type(PNC.WorldObjectTargetResolvers[component.objectTag]) == "function"
    then
        return PNC.WorldObjectTargetResolvers[component.objectTag](component)
    end
    return { { x = component.x, y = component.y, z = component.z } }
end)

return Targets
