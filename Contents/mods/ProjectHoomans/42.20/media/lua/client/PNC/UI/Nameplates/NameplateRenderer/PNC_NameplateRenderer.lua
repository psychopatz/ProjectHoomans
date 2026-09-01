require "PNC/UI/Nameplates/PNC_NameplateSpeech"
require "PNC/UI/Nameplates/PNC_NameplateRelationshipFeedbackRenderer"
require "PNC/UI/Nameplates/PNC_NameplateScopes"

PNC = PNC or {}
PNC.NameplateRenderer = PNC.NameplateRenderer or {}

local Renderer = PNC.NameplateRenderer

Renderer.Internal = Renderer.Internal or {}

require "PNC/UI/Nameplates/NameplateRenderer/PNC_NameplateRenderer_Shared"
require "PNC/UI/Nameplates/NameplateRenderer/PNC_NameplateRenderer_Core"
require "PNC/UI/Nameplates/NameplateRenderer/PNC_NameplateRenderer_DebugText"
require "PNC/UI/Nameplates/NameplateRenderer/PNC_NameplateRenderer_WorldPrimitives"
require "PNC/UI/Nameplates/NameplateRenderer/PNC_NameplateRenderer_PathDebug"
require "PNC/UI/Nameplates/NameplateRenderer/PNC_NameplateRenderer_CombatDebug"
require "PNC/UI/Nameplates/NameplateRenderer/PNC_NameplateRenderer_CampDebug"
require "PNC/UI/Nameplates/NameplateRenderer/PNC_NameplateRenderer_Api"

return Renderer
