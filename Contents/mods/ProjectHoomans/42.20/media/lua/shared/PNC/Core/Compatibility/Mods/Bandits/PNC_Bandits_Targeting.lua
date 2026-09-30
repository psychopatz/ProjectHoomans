-- Bandits actor translation and target discovery.
--
-- Turns Bandits bodies and its light cache into stable foreign-actor references
-- Hoomans targeting understands. Owns no relationship or damage decision.
-- Depends only on the Bandits shared Internal table.

PNC = PNC or {}
PNC.Compatibility = PNC.Compatibility or {}
local Bridge = PNC.Compatibility.Bandits or {}
local Internal = Bridge.Internal or {}
Bridge.Internal = Internal
Bridge.Targeting = Bridge.Targeting or {}
PNC.Compatibility.Bandits = Bridge

local Targeting = Bridge.Targeting

function Targeting.GetActorRef(context)
    return Internal.MakeRef(
        context and context.actor, context and context.light)
end

function Targeting.ResolveTarget(context)
    local ref = context and context.ref
    local body = ref and ref.worldObject
        or ref and Internal.GetBody(ref.actorId)
    if not body or not Internal.IsBanditBody(body)
        or not body.isAlive or not body:isAlive()
    then
        return nil
    end
    return Internal.MakeRef(body)
end

function Targeting.EnumerateTargets(context)
    local output = {}
    local cache = Internal.LightCache()
    local source = context and context.source
    local radius = tonumber(context and context.radius) or math.huge
    local radiusSq = radius * radius
    local id
    local light
    local body
    local ref
    local dx
    local dy
    if type(cache) == "table" then
        for id, light in pairs(cache) do
            body = Internal.CachedBody(id)
                or Internal.GetBody(light and (light.id or id))
            if body and body.isAlive and body:isAlive() then
                ref = Internal.MakeRef(body, light)
                if ref and source and source.x ~= nil and source.y ~= nil then
                    dx = (tonumber(ref.x) or 0)
                        - (tonumber(source.x) or 0)
                    dy = (tonumber(ref.y) or 0)
                        - (tonumber(source.y) or 0)
                    if (dx * dx) + (dy * dy) <= radiusSq then
                        output[#output + 1] = ref
                        output[ref.actorId] = true
                    end
                elseif ref then
                    output[#output + 1] = ref
                    output[ref.actorId] = true
                end
            end
        end
    end
    if isServer and isServer() and getCell then
        local cell = getCell()
        local zombieList = cell and cell.getZombieList
            and cell:getZombieList() or nil
        local index
        if zombieList then
            for index = 0, zombieList:size() - 1 do
                body = zombieList:get(index)
                if body and Internal.IsBanditBody(body)
                    and body.isAlive and body:isAlive()
                then
                    ref = Internal.MakeRef(body)
                    if ref and not output[ref.actorId]
                        and source and source.x ~= nil
                        and source.y ~= nil
                    then
                        dx = (tonumber(ref.x) or 0)
                            - (tonumber(source.x) or 0)
                        dy = (tonumber(ref.y) or 0)
                            - (tonumber(source.y) or 0)
                        if (dx * dx) + (dy * dy) <= radiusSq then
                            output[#output + 1] = ref
                            output[ref.actorId] = true
                        end
                    elseif ref and not output[ref.actorId] then
                        output[#output + 1] = ref
                        output[ref.actorId] = true
                    end
                end
            end
        end
    end
    return output
end

return Bridge
