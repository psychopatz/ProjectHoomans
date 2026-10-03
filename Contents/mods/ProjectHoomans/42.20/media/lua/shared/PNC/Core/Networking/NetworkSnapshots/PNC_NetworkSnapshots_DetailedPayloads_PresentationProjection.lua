-- Builds the visual, diagnostic, and equipment projections of a detailed
-- snapshot. The final serializer retains ownership of the payload contract.

if not PNC or not PNC.Network
    or not PNC.Network.Internal
    or not PNC.Network.Internal.DetailedPayload
then return end

local Network = PNC.Network
local H = Network.Internal.DetailedPayload
if not H then return Network end

local Core = H.Core
local Equipment = H.Equipment
local buildPathDebugState = H.buildPathDebugState
local buildCombatDebugState = H.buildCombatDebugState
local buildSeatingDebugState = H.buildSeatingDebugState
local buildTravelSummary = H.buildTravelSummary
local buildMapPresentationSummary = H.buildMapPresentationSummary
local buildDetailedDebugState = H.buildDetailedDebugState

function H.BuildPresentationProjection(record, state)
    local combat = state.combat
    local firearmState = state.firearmState
    local staminaInfo = state.staminaInfo
    local canRevive = state.canRevive
    local aiState = state.aiState
    local vehiclePassenger = state.vehiclePassenger
    local ownership = state.ownership
    local appearance = state.appearance
    local equipmentInfo = state.equipmentInfo
    return {
        pathDebugState = buildPathDebugState(record),
        combatDebugState = buildCombatDebugState(
            record,
            combat,
            firearmState
        ),
        seatingDebug = buildSeatingDebugState(record),
        appearance = appearance and Core.DeepCopy(appearance) or nil,
        travel = buildTravelSummary(record, true),
        mapPresentation = buildMapPresentationSummary(record),
        equipmentSummary = {
            primaryFullType = record.equipment
                and record.equipment.primaryFullType or nil,
            primaryVisual = Equipment
                and Equipment.BuildPrimaryVisualSummary
                and Equipment.BuildPrimaryVisualSummary(record)
                or nil,
            secondaryFullType = record.equipment
                and record.equipment.secondaryFullType or nil,
            worn = Core.DeepCopy(record.equipment and record.equipment.worn or {}),
            wornVisuals = Equipment
                and Equipment.BuildWornVisualSummary
                and Equipment.BuildWornVisualSummary(record)
                or {},
            attached = Core.DeepCopy(record.equipment
                and record.equipment.attached or {}),
        },
        inventorySummary = state.inventorySummary,
        characterWindow = {
            ownerUsername = ownership.ownerUsername,
            ownerOnlineID = ownership.ownerOnlineID,
        },
        debugState = buildDetailedDebugState(
            record,
            combat,
            firearmState,
            staminaInfo,
            canRevive,
            aiState,
            vehiclePassenger
        ),
    }
end

return Network
