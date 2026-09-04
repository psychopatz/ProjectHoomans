--[[
    PNC Traversal Query
    Stable entry point for read-only world, passage, and route queries.
]]

PNC = PNC or {}
PNC.TraversalQuery = PNC.TraversalQuery or {}
PNC.TraversalQuery.Internal = PNC.TraversalQuery.Internal or {}

require "PNC/Core/Pathing/TraversalQuery/PNC_TraversalQuery_Internal"
require "PNC/Core/Pathing/TraversalQuery/PNC_TraversalQuery_Squares"
require "PNC/Core/Pathing/TraversalQuery/PNC_TraversalQuery_Interior"
require "PNC/Core/Pathing/TraversalQuery/PNC_TraversalQuery_Objects"
require "PNC/Core/Pathing/TraversalQuery/PNC_TraversalQuery_Fences"
require "PNC/Core/Pathing/TraversalQuery/PNC_TraversalQuery_Passages"
require "PNC/Core/Pathing/TraversalQuery/PNC_TraversalQuery_Planning"
require "PNC/Core/Pathing/TraversalQuery/PNC_TraversalQuery_FenceSearch"
