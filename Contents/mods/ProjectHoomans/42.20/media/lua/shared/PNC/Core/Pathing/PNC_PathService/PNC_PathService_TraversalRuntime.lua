--[[
    PNC Traversal Runtime
    Stable entry point for scripted traversal lifecycle and progression.
]]

PNC = PNC or {}
PNC.PathService = PNC.PathService or {}
PNC.PathService.Internal = PNC.PathService.Internal or {}

local Internal = PNC.PathService.Internal
Internal.TraversalRuntime = Internal.TraversalRuntime or {}

require "PNC/Core/Pathing/PNC_PathService/TraversalRuntime/PNC_PathService_TraversalRuntime_Signals"
require "PNC/Core/Pathing/PNC_PathService/TraversalRuntime/PNC_PathService_TraversalRuntime_Lifecycle"
require "PNC/Core/Pathing/PNC_PathService/TraversalRuntime/PNC_PathService_TraversalRuntime_Progress"
