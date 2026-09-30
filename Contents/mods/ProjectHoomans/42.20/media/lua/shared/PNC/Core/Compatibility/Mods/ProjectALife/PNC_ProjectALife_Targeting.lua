-- A-Life actor translation and target discovery for the Project A-Life adapter.
--
-- Turns Project A-Life actor records into the stable foreign-actor references
-- Hoomans targeting understands, and enumerates live actors near a source.
-- This module owns no stance or damage decision.

PNC = PNC or {}
PNC.Compatibility = PNC.Compatibility or {}
PNC.Compatibility.ProjectALifeAdapter =
    PNC.Compatibility.ProjectALifeAdapter or {}

local Adapter = PNC.Compatibility.ProjectALifeAdapter
local Internal = Adapter.Internal

function Adapter.enumerateTargets(context)
    local output = {}
    local source = context and context.source
    local radius = tonumber(context and context.radius) or 12
    local sx = source and tonumber(source.x)
    local sy = source and tonumber(source.y)
    local sz = source and tonumber(source.z)
    local alife = ProjectALife
    local watchdog = alife and alife.Watchdog
    local bindings = watchdog and watchdog.bindings
    if type(bindings) ~= "table" then return output end

    for uid, binding in pairs(bindings) do
        local record = Internal.RegistryRecord(tostring(uid))
        local body = binding and binding.shell
        if record and record.lifecycle == "active"
            and body and Internal.IsAlive(body)
            and tonumber(binding.generation) == tonumber(record.generation)
        then
            local x, y, z = Internal.GetPosition(body)
            local dx = sx and x and x - sx or nil
            local dy = sy and y and y - sy or nil
            if x and y and (sx == nil or dx * dx + dy * dy <= radius * radius)
                and (sz == nil or z == nil or math.abs(z - sz) < 1)
            then
                local candidate = Internal.ActorReference(
                    tostring(uid), record.generation)
                if candidate ~= nil then
                    candidate.immediateSelfDefense = Internal.RecentThreat(
                        source, candidate.actorId)
                    output[#output + 1] = candidate
                end
            end
        end
    end
    return output
end

function Adapter.getActorRef(context)
    context = type(context) == "table" and context or {}
    local actor = context.actor
    if type(actor) == "table" then
        local uid = actor.uid or actor.ProjectALifeUID
        if uid ~= nil then
            return Internal.ActorReference(tostring(uid), actor.generation)
        end
    end
    if actor and actor.getModData then
        local ok, data = pcall(actor.getModData, actor)
        if ok and type(data) == "table" and data.ProjectALifeUID then
            return Internal.ActorReference(tostring(data.ProjectALifeUID),
                data.ProjectALifeGeneration)
        end
    end
    return nil
end

function Adapter.resolveTarget(context)
    context = type(context) == "table" and context or {}
    local ref = context.ref or {}
    return Internal.ActorReference(
        tostring(ref.actorId or ref.id or ""), ref.generation)
end

return Adapter
