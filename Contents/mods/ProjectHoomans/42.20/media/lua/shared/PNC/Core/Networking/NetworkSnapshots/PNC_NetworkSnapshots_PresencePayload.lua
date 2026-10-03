--[[
    PNC Network Snapshots - Presence Payload
    Builds throttled incremental presence snapshots.
]]

local Network = PNC.Network
local Core = PNC.Core
local Const = PNC.Const
local Diagnostics = PNC.PerformanceScalingDiagnostics
local Equipment = PNC.Equipment
local Stamina = PNC.Stamina
local Firearms = PNC.Firearms
local Settings = PNC.Sandbox
local Parts = Network.Internal.SnapshotParts
local buildTravelSummary = Parts.BuildTravelSummary
local resolveAIState = Parts.ResolveAIState
local buildCombatSummary = Parts.BuildCombatSummary
local buildCommandFeedback = Parts.BuildCommandFeedback
local buildCorpseHaulDiagnostic = Parts.BuildCorpseHaulDiagnostic
local buildBandageFeedback = Parts.BuildBandageFeedback
local buildActionInformation = Parts.BuildActionInformation
local buildStaminaRecoverySummary = Parts.BuildStaminaRecoverySummary
local buildVisualState = Parts.BuildVisualState
local buildPathDebugState = Parts.BuildPathDebugState
local buildCombatDebugState = Parts.BuildCombatDebugState
local buildCampResourceDebugState = Parts.BuildCampResourceDebugState
local buildSeatingDebugState = Parts.BuildSeatingDebugState
local buildIdentityOwnershipSummary =
    Parts.BuildIdentityOwnershipSummary

local PresencePayload = Network.Internal.PresencePayload or {}
Network.Internal.PresencePayload = PresencePayload
PresencePayload.Core = Core
PresencePayload.Const = Const
PresencePayload.Diagnostics = Diagnostics
PresencePayload.Equipment = Equipment
PresencePayload.Stamina = Stamina
PresencePayload.Firearms = Firearms
PresencePayload.Settings = Settings
PresencePayload.BuildTravelSummary = buildTravelSummary
PresencePayload.ResolveAIState = resolveAIState
PresencePayload.BuildCombatSummary = buildCombatSummary
PresencePayload.BuildCommandFeedback = buildCommandFeedback
PresencePayload.BuildCorpseHaulDiagnostic = buildCorpseHaulDiagnostic
PresencePayload.BuildBandageFeedback = buildBandageFeedback
PresencePayload.BuildActionInformation = buildActionInformation
PresencePayload.BuildStaminaRecoverySummary = buildStaminaRecoverySummary
PresencePayload.BuildVisualState = buildVisualState
PresencePayload.BuildPathDebugState = buildPathDebugState
PresencePayload.BuildCombatDebugState = buildCombatDebugState
PresencePayload.BuildCampResourceDebugState = buildCampResourceDebugState
PresencePayload.BuildSeatingDebugState = buildSeatingDebugState
PresencePayload.BuildIdentityOwnershipSummary = buildIdentityOwnershipSummary

require "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_PresencePayload_CombatDebug"
require "PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_PresencePayload_Build"

return Network
