-- Optional bridge from the server action-plan lease to shared behavior.
-- The shared behavior system remains usable when the server service is absent.

PNC = PNC or {}
PNC.BehaviorActionPlanOwnership = PNC.BehaviorActionPlanOwnership or {}

local Ownership = PNC.BehaviorActionPlanOwnership

function Ownership.Get(record)
    local service = PNC.Semantics
        and PNC.Semantics.ActionPlanService or nil
    if not service or type(service.GetExecutionOwner) ~= "function" then
        return nil
    end
    return service.GetExecutionOwner(record)
end

return Ownership
