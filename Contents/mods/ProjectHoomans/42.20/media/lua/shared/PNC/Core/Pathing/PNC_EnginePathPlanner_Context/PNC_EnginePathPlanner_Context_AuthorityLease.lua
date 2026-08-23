PNC = PNC or {}
PNC.EnginePathPlanner = PNC.EnginePathPlanner or {}
PNC.EnginePathPlanner.Internal = PNC.EnginePathPlanner.Internal or {}

local Planner = PNC.EnginePathPlanner
local Internal = Planner.Internal
local Core = PNC.Core
local LiveBodyControl = PNC.LiveBodyControl

function Internal.IsMultiplayerAuthority()
    return Core
        and Core.IsAuthority
        and Core.IsAuthority()
        and isServer
        and isServer() == true
end

function Internal.SetServerMovementLease(body, navigation, active)
    if not navigation then return false end
    local movementActive = active == true
    local serverLease = movementActive
        and Internal.IsMultiplayerAuthority()
    -- In single-player the action advances Behavior2 while the body stays
    -- useless. Dedicated MP instead needs a useful client-controlled body.
    local keepEngineMovementActive = serverLease == true
    navigation.serverMovementLease = serverLease
    local record = navigation.record
    if record then
        Planner.ActiveServerRoutes[record] =
            serverLease and navigation or nil
    end
    if LiveBodyControl and LiveBodyControl.SetManagedBodyUseless then
        LiveBodyControl.SetManagedBodyUseless(
            body,
            not keepEngineMovementActive,
            keepEngineMovementActive
        )
    elseif body and body.setUseless then
        body:setUseless(not keepEngineMovementActive)
    end
    return serverLease
end

return Internal
