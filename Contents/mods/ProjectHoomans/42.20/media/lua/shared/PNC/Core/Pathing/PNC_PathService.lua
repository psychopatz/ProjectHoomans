--[[
    PNC Path Service
    Entry point for the split pathing subsystem. The public `PNC.PathService`
    table remains stable while focused implementation files live under the
    dedicated `PNC_PathService/` folder.
]]

PNC = PNC or {}
PNC.PathService = PNC.PathService or {}

local PathService = PNC.PathService
PathService.Internal = PathService.Internal or {}

require "PNC/Core/Pathing/PNC_TraversalAction"
require "PNC/Core/Pathing/PNC_PathService/PNC_PathService_Context"
require "PNC/Core/Pathing/PNC_PathService/PNC_PathService_Facing"
require "PNC/Core/Pathing/PNC_PathService/PNC_PathService_AmbientFacing"
require "PNC/Core/Pathing/PNC_PathService/PNC_PathService_Logging"
require "PNC/Core/Pathing/PNC_PathService/PNC_PathService_Interactions"
require "PNC/Core/Pathing/PNC_PathService/PNC_PathService_TraversalRuntime"
require "PNC/Core/Pathing/PNC_PathService/PNC_PathService_Lane"
require "PNC/Core/Pathing/PNC_PathService/PNC_PathService_Motion"

-- Canonical movement-lane boundary. Direct methods remain available for
-- existing integrations; Commands.Reset uses record-first argument order so
-- callers cannot accidentally pass the body as movement state.
PathService.Commands = PathService.Commands or {}
PathService.Queries = PathService.Queries or {}

local Commands = PathService.Commands
Commands.MoveToward = PathService.MoveToward
Commands.Pump = PathService.Pump
Commands.AdvanceAbstract = PathService.AdvanceAbstract
Commands.RequestCombatFacing = PathService.RequestCombatFacing
Commands.RequestIdleFacing = PathService.RequestIdleFacing
Commands.RequestAmbientFacing = PathService.RequestAmbientFacing
Commands.ApplyTravelFacing = PathService.ApplyTravelFacing
Commands.Reset = function(record, zombie, reason)
    return PathService.Reset(zombie, record, reason)
end

local Queries = PathService.Queries
Queries.IsTraversalActive = PathService.IsTraversalActive
Queries.GetMovementRecoveryState = PathService.GetMovementRecoveryState

return PathService
