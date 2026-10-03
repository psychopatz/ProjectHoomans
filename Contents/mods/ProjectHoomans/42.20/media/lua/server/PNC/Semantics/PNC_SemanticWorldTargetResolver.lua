if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

-- Stable semantic target boundary. Primitive validation and world-object
-- helpers load before provider registration and final target resolution.
require "PNC/Semantics/PNC_SemanticWorldTargetResolver_Core"
require "PNC/Semantics/PNC_SemanticWorldTargetResolver_Providers"

return PNC.Semantics.WorldTargetResolver
