local Network = PNC.Network
local Core = PNC.Core
local Equipment = PNC.Equipment
local Inventory = PNC.Inventory
local Skills = PNC.Skills
local Stamina = PNC.Stamina
local Profiles = PNC.VisualProfiles
local Wounds = PNC.NPCWounds
local Firearms = PNC.Firearms
local Settings = PNC.Sandbox
local Parts = Network.Internal.SnapshotParts
local buildTravelSummary = Parts.BuildTravelSummary
local buildMapPresentationSummary = Parts.BuildMapPresentationSummary
local resolveAIState = Parts.ResolveAIState
local buildIdentitySummary = Parts.BuildIdentitySummary
local buildOrganizationalFactionSummary =
    Parts.BuildOrganizationalFactionSummary
local buildCombatSummary = Parts.BuildCombatSummary
local buildCommandFeedback = Parts.BuildCommandFeedback
local buildCorpseHaulDiagnostic = Parts.BuildCorpseHaulDiagnostic
local buildBandageFeedback = Parts.BuildBandageFeedback
local buildActionInformation = Parts.BuildActionInformation
local buildStaminaRecoverySummary = Parts.BuildStaminaRecoverySummary
local buildVisualState = Parts.BuildVisualState
local buildPathDebugState = Parts.BuildPathDebugState
local buildCombatDebugState = Parts.BuildCombatDebugState
local buildDetailedDebugState = Parts.BuildDetailedDebugState
local buildSeatingDebugState = Parts.BuildSeatingDebugState
local buildIdentityOwnershipSummary =
    Parts.BuildIdentityOwnershipSummary

Network.Internal.DetailedPayload = {
    Core = Core,
    Equipment = Equipment,
    Inventory = Inventory,
    Skills = Skills,
    Stamina = Stamina,
    Profiles = Profiles,
    Wounds = Wounds,
    Firearms = Firearms,
    Settings = Settings,
    Parts = Parts,
    buildTravelSummary = buildTravelSummary,
    buildMapPresentationSummary = buildMapPresentationSummary,
    resolveAIState = resolveAIState,
    buildIdentitySummary = buildIdentitySummary,
    buildOrganizationalFactionSummary = buildOrganizationalFactionSummary,
    buildCombatSummary = buildCombatSummary,
    buildCommandFeedback = buildCommandFeedback,
    buildCorpseHaulDiagnostic = buildCorpseHaulDiagnostic,
    buildBandageFeedback = buildBandageFeedback,
    buildActionInformation = buildActionInformation,
    buildStaminaRecoverySummary = buildStaminaRecoverySummary,
    buildVisualState = buildVisualState,
    buildPathDebugState = buildPathDebugState,
    buildCombatDebugState = buildCombatDebugState,
    buildDetailedDebugState = buildDetailedDebugState,
    buildSeatingDebugState = buildSeatingDebugState,
    buildIdentityOwnershipSummary = buildIdentityOwnershipSummary,
}

require "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_DetailedPayloads_State"
require "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_DetailedPayloads_Identity"
require "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_DetailedPayloads_PresentationProjection"
require "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_DetailedPayloads_Build"

return Network
