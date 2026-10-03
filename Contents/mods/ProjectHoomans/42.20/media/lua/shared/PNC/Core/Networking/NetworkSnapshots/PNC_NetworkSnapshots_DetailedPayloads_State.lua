-- Gathers the derived state used by the detailed network snapshot serializer.
-- This provider does not define or mutate the serialized payload contract.

if not PNC or not PNC.Network
    or not PNC.Network.Internal
    or not PNC.Network.Internal.DetailedPayload
then return end

local Network = PNC.Network
local H = Network.Internal.DetailedPayload
if not H then return Network end

local Core = H.Core
local Equipment = H.Equipment
local Inventory = H.Inventory
local Stamina = H.Stamina
local Profiles = H.Profiles
local Wounds = H.Wounds
local Firearms = H.Firearms
local Settings = H.Settings
local resolveAIState = H.resolveAIState

local function buildNeedsSummary(record)
    local repository = PNC.NeedsRepository
    local state = repository and repository.Get
        and repository.Get(record, false) or nil
    local needs = state and state.needs or record.needs
    if type(needs) ~= "table" then return nil end
    local evaluatedAt = repository and repository.GetEvaluatedAt
        and repository.GetEvaluatedAt(record) or nil
    return {
        hunger = tonumber(needs.hunger) or 0,
        thirst = tonumber(needs.thirst) or 0,
        fatigue = tonumber(needs.fatigue) or 0,
        sampledAt = evaluatedAt,
    }
end

function H.BuildSnapshotState(record, inventorySummaryOverride)
    local state = {}
    state.aiState, state.inCombat = resolveAIState(record)
    state.canRevive = PNC.Health and PNC.Health.CanRevive
        and PNC.Health.CanRevive(record) or false
    state.staminaInfo = Stamina and Stamina.BuildSnapshot
        and Stamina.BuildSnapshot(record) or {}
    state.equipmentInfo = Equipment and Equipment.Describe
        and Equipment.Describe(record) or {}
    state.identity = H.buildIdentitySummary(record)
    state.ownership = H.buildIdentityOwnershipSummary(record)
    if inventorySummaryOverride ~= nil then
        -- Keep the snapshot copy independent from the full inventory payload.
        state.inventorySummary = Core.DeepCopy(inventorySummaryOverride)
    else
        state.inventorySummary = Inventory and Inventory.BuildSummaryPayload
            and Inventory.BuildSummaryPayload(record) or nil
    end
    state.combat = H.buildCombatSummary(record, state.equipmentInfo)
    state.visualState = H.buildVisualState(record)
    state.appearance = Profiles and Profiles.RollAppearance
        and Profiles.RollAppearance(record) or nil
    state.bodyHealth = Wounds and Wounds.BuildSnapshot
        and Wounds.BuildSnapshot(record) or nil
    state.needsSummary = buildNeedsSummary(record)
    state.firearmState = Firearms and Firearms.BuildDebugState
        and Firearms.BuildDebugState(record)
        or nil
    state.vehiclePassenger = record.runtime
        and record.runtime.vehiclePassenger or nil
    state.treatmentState = PNC.BehaviorTreatment
        and PNC.BehaviorTreatment.BuildSnapshot
        and PNC.BehaviorTreatment.BuildSnapshot(record) or nil
    state.medicalCareState = PNC.Treatment
        and PNC.Treatment.BuildMedicalCareSnapshot
        and PNC.Treatment.BuildMedicalCareSnapshot(record) or nil
    state.attackMode = record.runtime and (
        record.runtime.target ~= nil
        or (
            record.runtime.attackAction ~= nil
            and Core.Now() < (
                tonumber(record.runtime.attackAction.finishAt) or 0
            )
        )
    ) or false
    return state
end

return Network
