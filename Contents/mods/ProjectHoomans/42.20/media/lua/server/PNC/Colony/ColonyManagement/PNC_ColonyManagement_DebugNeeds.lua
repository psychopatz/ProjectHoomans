if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ColonyManagement = PNC.ColonyManagement or {}
PNC.ColonyManagement.Internal = PNC.ColonyManagement.Internal or {}

local Management = PNC.ColonyManagement
local Internal = Management.Internal
local Definitions = PNC.NeedsDefinitions
local canUseDebug = Internal.canUseDebug
local owned = Internal.owned
local debugNearbyWaterAction = Internal.debugNearbyWaterAction

local function debugNeedAction(player, args)
    if not canUseDebug(player) then return false, "not_authorized" end
    local record = PNC.Registry and PNC.Registry.Get(args.npcID) or nil
    if not record or record.alive == false or not owned(record, player) then
        return false, "npc_not_owned"
    end
    if PNC.Recruitment and PNC.Recruitment.ReconcileOwned then
        local reconciled, reconcileReason =
            PNC.Recruitment.ReconcileOwned(player, record)
        if not reconciled and reconcileReason ~= "unchanged" then
            return false, reconcileReason or "membership_repair_failed"
        end
    end
    local operation = tostring(args.operation or "")
    if operation == "modify" then
        local needType = tostring(args.needType or "")
        if not Definitions.Get(needType) then return false, "unknown_need" end
        local amount = math.max(-1, math.min(1, tonumber(args.amount) or 0))
        local value = PNC.IndividualNeeds.Modify(
            record, needType, amount, "colony_debug"
        )
        return value ~= nil, value ~= nil and "updated" or "update_failed", {
            npcID = record.id, needType = needType, value = value,
        }
    end
    if operation == "reset" then
        return PNC.IndividualNeeds.Reset(record) == true, "reset"
    end
    if operation == "force_provision" then
        local ok, reason, results = PNC.ProvisionScheduler.RequestManual(record)
        local diagnostics = PNC.ProvisionEvaluator.Inspect(record) or {
            npcID = record.id,
        }
        diagnostics.forceResults = results
        return ok, reason, diagnostics
    end
    if operation == "inspect_provision" then
        local diagnostics, reason = PNC.ProvisionEvaluator.Inspect(record)
        return diagnostics ~= nil, reason or "provision_inspected", diagnostics
    end
    if operation == "force_nearby_water" then
        return debugNearbyWaterAction(player, args)
    end
    return false, "unknown_debug_operation"
end

Internal.debugNeedAction = debugNeedAction

return Management
