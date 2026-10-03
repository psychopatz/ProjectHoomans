-- Catch-up movement, bounded convergence, and diagnostics for abstract
-- follow-owner ticks.

PNC = PNC or {}
PNC.BehaviorCompanion = PNC.BehaviorCompanion or {}
PNC.BehaviorCompanion.Internal = PNC.BehaviorCompanion.Internal or {}

local Companion = PNC.BehaviorCompanion
local Internal = Companion.Internal
local H = Internal.AbstractFollowOwnerMovementHandoff
if type(H) ~= "table" then return Companion end

return Companion
