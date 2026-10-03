-- World-target refresh provider.

PNC = PNC or {}
PNC.BehaviorTargeting = PNC.BehaviorTargeting or {}

local Targeting = PNC.BehaviorTargeting
local H = Targeting.Internal and Targeting.Internal.UpdateTargetFromWorld
if type(H) ~= "table" then
    return Targeting
end

local Core = H.Core
local Const = H.Const
local Resolver = H.Resolver

function Targeting.UpdateTargetFromWorld(record, target)
    if not target then
        return nil
    end
    local now = Core.Now()
    local memoryUntil = (tonumber(target.lastSeenAt) or 0)
        + (tonumber(Const.TARGET_VISUAL_MEMORY_MS) or 2200)
    if type(Resolver) == "function" then
        return Resolver(record, target, now, memoryUntil)
    end
    return nil
end



return Targeting
