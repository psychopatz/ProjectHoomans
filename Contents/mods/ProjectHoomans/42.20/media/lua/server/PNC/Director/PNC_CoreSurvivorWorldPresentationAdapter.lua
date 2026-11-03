if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then
    return
end

PNC = PNC or {}
PNC.CoreSurvivorWorldPresentationAdapter =
    PNC.CoreSurvivorWorldPresentationAdapter or {}

local Adapter = PNC.CoreSurvivorWorldPresentationAdapter
local World = require
    "PsychopatzCore/SurvivorWorld/PsychopatzSurvivorWorld"

Adapter.PROVIDER_ID = "ProjectHoomans.LiveBody"
Adapter.PRIORITY = 500

local function liveBody(actorID)
    if not PNC.Registry
        or type(PNC.Registry.GetLiveZombie) ~= "function"
    then
        return nil
    end
    return PNC.Registry.GetLiveZombie(actorID)
end

local function bodyPosition(body)
    if not body then return nil end
    local x = body.getX and tonumber(body:getX()) or nil
    local y = body.getY and tonumber(body:getY()) or nil
    if x == nil or y == nil then return nil end
    local z = body.getZ and tonumber(body:getZ()) or 0
    return { x = x, y = y, z = z or 0 }
end

function Adapter.ResolvePosition(actor)
    local actorID = actor and (actor.actorId or actor.actorID)
    if not actorID then return nil end
    return bodyPosition(liveBody(actorID))
end

local ok, reason = World.Presentation.RegisterPositionProvider(
    Adapter.PROVIDER_ID,
    {
        priority = Adapter.PRIORITY,
        resolve = Adapter.ResolvePosition,
    }
)

Adapter.Registered = ok == true
Adapter.LastRegistrationReason = reason

return Adapter
