-- Stable public dispatch surface for companion behavior.

local Companion = PNC.BehaviorCompanion
local Internal = Companion.Internal

function Companion.Tick(record, zombie, job)
    if job == "FollowOwner" then
        return Internal.TickFollowOwner(record, zombie)
    end
    if job == "GuardAnchor" then
        return Internal.TickGuardAnchor(record, zombie)
    end
    if job == "PatrolRoute" then
        return Internal.TickPatrolRoute(record, zombie)
    end
    return false
end
