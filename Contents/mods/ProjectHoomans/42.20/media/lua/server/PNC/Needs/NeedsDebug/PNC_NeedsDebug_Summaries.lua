if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Debug = PNC.NeedsDebug
local H = Debug.Internal
local Definitions = PNC.NeedsDefinitions
local Utils = PNC.NeedsUtils

function H.Copy(value)
    return PNC.Core and PNC.Core.DeepCopy and PNC.Core.DeepCopy(value) or value
end

function H.GroupSummary(faction)
    local state = PNC.GroupNeeds.Ensure(faction)
    local mobile = faction.mobile or {}
    local site = mobile.site or {}
    local home = site.home or {}
    local members = 0
    for _, value in pairs(faction.memberIDs or {}) do if value == true then members = members + 1 end end
    local rates = PNC.GroupNeeds.GetRates(faction) or {}
    return {
        id = faction.id, name = faction.name, type = faction.archetypeID,
        faction = faction.name, members = members, activity = PNC.GroupNeeds.GetActivity(faction),
        location = { x = home.x, y = home.y, z = home.z },
        destination = mobile.nextMoveAt, needs = state, rates = rates,
        history = H.Copy(Debug.groupHistory[faction.id] or {}),
        elapsed = math.max(0, Utils.WorldAgeHours() - (tonumber(state and state.lastUpdateWorldAge) or 0)),
    }
end

function H.IndividualSummary(record)
    local state = PNC.IndividualNeeds.Ensure(record)
    local repositoryState = PNC.IndividualNeeds.GetState(record)
    local rates = PNC.IndividualNeeds.GetRates(record)
    local evaluatedAt = PNC.NeedsRepository.GetEvaluatedAt(record)
    local persistence = PNC.Inventory and PNC.Inventory.Serialize
        and PNC.Inventory.Serialize(record) or nil
    local mode = PNC.Inventory and PNC.Inventory.GetPersistenceMode
        and PNC.Inventory.GetPersistenceMode(record) or "UNKNOWN"
    local delta = mode == "BASELINE_DELTA" and persistence and persistence[5] or nil
    return state and {
        id = record.id, name = tostring(record.name or record.id), owner = record.ownerUsername or "Player",
        activity = record.activeBehavior or record.activeJob or record.orderSpec and record.orderSpec.kind or "idle",
        needs = state,
        nutrition = H.Copy(repositoryState and repositoryState.nutrition or {}),
        severities = {
            hunger = Definitions.GetLevel("hunger", state.hunger),
            thirst = Definitions.GetLevel("thirst", state.thirst),
            fatigue = Definitions.GetLevel("fatigue", state.fatigue),
        },
        rates = H.Copy(rates), modifiers = H.Copy(rates and rates.modifiers or {}),
        mortalityEnabled = PNC.Sandbox.PlayerOwnedNPCNeedMortalityEnabled(),
        consequences = H.Copy(record.runtime and record.runtime.needs or {}),
        evaluatedAt = evaluatedAt,
        dirty = PNC.NeedsRepository.Dirty == true,
        history = H.Copy(Debug.individualHistory[record.id] or {}),
        conditionStats = PNC.ConditionStats
            and PNC.ConditionStats.Ensure(record, Utils.WorldAgeHours()) or {},
        conditionRates = PNC.ConditionStats
            and PNC.ConditionStats.GetRates(record,
                PNC.IndividualNeeds.GetActivity(record)) or {},
        dynamicTraits = H.Copy(record.dynamicTraits or {}),
        elapsed = math.max(0, Utils.WorldAgeHours() - evaluatedAt),
        supply = PNC.NPCSupplyService and PNC.NPCSupplyService.GetDebugState
            and PNC.NPCSupplyService.GetDebugState(record) or { byKind = {} },
        provision = PNC.ProvisionEvaluator
            and PNC.ProvisionEvaluator.GetDebugState
            and PNC.ProvisionEvaluator.GetDebugState(record)
            or { evaluations = {}, dirtyRules = {} },
        inventoryMode = mode,
        deltaRecordCount = delta and (#(delta[2] or {}) + #(delta[3] or {})) or 0,
        fullPromotionReason = record.inventoryPromotionReason,
    } or nil
end
