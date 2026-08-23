--[[
    PNC Engine Path Planner
    Stable entry point for native path request and pump ownership.
]]

PNC = PNC or {}
PNC.EnginePathPlanner = PNC.EnginePathPlanner or {}
PNC.EnginePathPlanner.Internal = PNC.EnginePathPlanner.Internal or {}

require "PNC/Core/Pathing/PNC_EnginePathPlanner/PNC_EnginePathPlanner_Passage"
require "PNC/Core/Pathing/PNC_EnginePathPlanner/PNC_EnginePathPlanner_Request"
require "PNC/Core/Pathing/PNC_EnginePathPlanner/PNC_EnginePathPlanner_Steering"
require "PNC/Core/Pathing/PNC_EnginePathPlanner/PNC_EnginePathPlanner_PumpTraversal"
require "PNC/Core/Pathing/PNC_EnginePathPlanner/PNC_EnginePathPlanner_PumpProgress"
require "PNC/Core/Pathing/PNC_EnginePathPlanner/PNC_EnginePathPlanner_Pump"
require "PNC/Core/Pathing/PNC_EnginePathPlanner/PNC_EnginePathPlanner_Frames"
require "PNC/Core/Pathing/PNC_EnginePathPlanner/PNC_EnginePathPlanner_Lifecycle"

return PNC.EnginePathPlanner
