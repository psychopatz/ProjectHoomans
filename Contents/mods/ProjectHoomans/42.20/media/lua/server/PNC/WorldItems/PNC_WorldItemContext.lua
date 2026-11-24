-- Composition root for server-authoritative world-item discovery and context.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.WorldItemContext = PNC.WorldItemContext or {}

require "PNC/WorldItems/PNC_WorldItemContext_Zones"
require "PNC/WorldItems/PNC_WorldItemContext_RipRules"
require "PNC/WorldItems/PNC_WorldItemContext_Classifier"
require "PNC/WorldItems/PNC_WorldItemContext_Claims"
require "PNC/WorldItems/PNC_WorldItemContext_Cache"
require "PNC/WorldItems/PNC_WorldItemContext_Scanner"
require "PNC/WorldItems/PNC_WorldItemContext_Approach"
require "PNC/WorldItems/PNC_WorldItemContext_Objects"

local Context = PNC.WorldItemContext

Context.FindBestCandidate = Context.Scanner.FindBestCandidate
Context.ResetMetrics = Context.Scanner.ResetMetrics
Context.GetMetrics = Context.Scanner.GetMetrics
Context.InvalidateCache = Context.Scanner.InvalidateCache
Context.FindBestObject = Context.Objects.FindBestObject
Context.BuildApproachTiles = Context.Approach.BuildApproachTiles
Context.FacingToward = Context.Approach.FacingToward
Context.ForEachSquareInRadius = Context.Objects.ForEachSquareInRadius
Context.GetSquareSnapshot = Context.Cache.GetSquareSnapshot
Context.ClearSquare = Context.Cache.ClearSquare

return Context
