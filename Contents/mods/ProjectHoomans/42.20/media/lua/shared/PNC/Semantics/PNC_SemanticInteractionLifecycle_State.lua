-- Ordered state lifecycle entry point. Mutable storage providers load before
-- transitions, projections and persistence consumers.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Lifecycle = PNC.Semantics.InteractionLifecycle or {}
PNC.Semantics.InteractionLifecycle = Lifecycle
Lifecycle.Internal = Lifecycle.Internal or {}

require "PNC/Semantics/PNC_SemanticInteractionLifecycle_State_Storage"
require "PNC/Semantics/PNC_SemanticInteractionLifecycle_State_Transitions"
require "PNC/Semantics/PNC_SemanticInteractionLifecycle_State_Projections"
require "PNC/Semantics/PNC_SemanticInteractionLifecycle_State_Persistence"

return Lifecycle
