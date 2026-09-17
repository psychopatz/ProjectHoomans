-- Compatibility name for the shared PsychopatzCore preview primitives.
-- Hoomans owns semantic data; Core owns world projection and drawing.
PNC = PNC or {}
PNC.PerceptionDebug = PNC.PerceptionDebug or {}

local Primitives = require "PsychopatzCore/Preview/PC_PreviewPrimitives"
PNC.PerceptionDebug.OverlayPrimitives = Primitives

return Primitives
