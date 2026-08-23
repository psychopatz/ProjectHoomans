--[[
    PNC Path Service Context
    Stable entry point for shared PathService state and movement policy.
]]

PNC = PNC or {}
PNC.PathService = PNC.PathService or {}
PNC.PathService.Internal = PNC.PathService.Internal or {}

require "PNC/Core/Pathing/PNC_PathService/Context/PNC_PathService_Context_Config"
require "PNC/Core/Pathing/PNC_PathService/Context/PNC_PathService_Context_WorldState"
require "PNC/Core/Pathing/PNC_PathService/Context/PNC_PathService_Context_PositionRecovery"
require "PNC/Core/Pathing/PNC_PathService/Context/PNC_PathService_Context_TraversalMemory"
require "PNC/Core/Pathing/PNC_PathService/Context/PNC_PathService_Context_BodyOwnership"
require "PNC/Core/Pathing/PNC_PathService/Context/PNC_PathService_Context_Goals"
require "PNC/Core/Pathing/PNC_PathService/Context/PNC_PathService_Context_Animation"
