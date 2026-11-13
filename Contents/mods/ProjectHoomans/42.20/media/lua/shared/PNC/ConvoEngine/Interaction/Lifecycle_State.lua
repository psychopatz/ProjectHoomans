-- Ordered state lifecycle entry point. Mutable storage providers load before
-- transitions, projections and persistence consumers.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Lifecycle = PNC.ConvoEngine.InteractionLifecycle or {}
PNC.ConvoEngine.InteractionLifecycle = Lifecycle
Lifecycle.Internal = Lifecycle.Internal or {}

require "PNC/ConvoEngine/Interaction/Lifecycle_State_Storage"
require "PNC/ConvoEngine/Interaction/Lifecycle_State_Transitions"
require "PNC/ConvoEngine/Interaction/Lifecycle_State_Projections"
require "PNC/ConvoEngine/Interaction/Lifecycle_State_Persistence"

return Lifecycle
