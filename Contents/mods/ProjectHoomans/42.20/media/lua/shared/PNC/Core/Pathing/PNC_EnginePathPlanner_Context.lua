-- Shared engine-path query and request helpers.

PNC = PNC or {}
PNC.EnginePathPlanner = PNC.EnginePathPlanner or {}
PNC.EnginePathPlanner.Internal = PNC.EnginePathPlanner.Internal or {}

require "PNC/Core/Pathing/PNC_EnginePathPlanner_Context/PNC_EnginePathPlanner_Context_State"
require "PNC/Core/Pathing/PNC_EnginePathPlanner_Context/PNC_EnginePathPlanner_Context_Passage"
require "PNC/Core/Pathing/PNC_EnginePathPlanner_Context/PNC_EnginePathPlanner_Context_NativeState"
require "PNC/Core/Pathing/PNC_EnginePathPlanner_Context/PNC_EnginePathPlanner_Context_AuthorityLease"
require "PNC/Core/Pathing/PNC_EnginePathPlanner_Context/PNC_EnginePathPlanner_Context_RequestCleanup"
require "PNC/Core/Pathing/PNC_EnginePathPlanner_Context/PNC_EnginePathPlanner_Context_RoutePolicy"

return PNC.EnginePathPlanner.Internal
