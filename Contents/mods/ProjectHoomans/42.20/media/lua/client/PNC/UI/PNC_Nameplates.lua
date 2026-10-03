require "ISUI/ISUIElement"
require "PsychopatzCore/Settings/PsychopatzSettings"

PNC = PNC or {}
PNC.Nameplates = PNC.Nameplates or {}

require "PNC/UI/PNC_Nameplates_Settings"

require "PNC/UI/Nameplates/PNC_NameplatePresentation"
require "PNC/UI/Nameplates/PNC_NameplateFirearmAnchor"
require "PNC/UI/Nameplates/PNC_NameplateDebug"
require "PNC/UI/Nameplates/PNC_NameplateBodies"
require "PNC/UI/Nameplates/PNC_NameplateDisplaySettings"
require "PNC/UI/Nameplates/PNC_NameplateRelationshipFeedback"
require "PNC/UI/Nameplates/PNC_NameplateRelationshipFeedbackRenderer"
require "PNC/UI/Nameplates/PNC_NameplateToolFeedback"
require "PNC/UI/Nameplates/PNC_NameplateToolFeedbackRenderer"
require "PNC/UI/Nameplates/PNC_NameplateScopes"
require "PNC/UI/Nameplates/PNC_NameplateStealthIndicator"
require "PNC/UI/Nameplates/PNC_NameplateEntries"
require "PNC/UI/Nameplates/NameplateRenderer/PNC_NameplateRenderer"

local Nameplates = PNC.Nameplates
Nameplates.RelationshipFeedback = PNC.NameplateRelationshipFeedback
Nameplates.RelationshipFeedbackRenderer =
    PNC.NameplateRelationshipFeedbackRenderer
Nameplates.ToolFeedback = PNC.NameplateToolFeedback
Nameplates.ToolFeedbackRenderer = PNC.NameplateToolFeedbackRenderer
Nameplates.DisplaySettings = PNC.NameplateDisplaySettings

require "PNC/UI/PNC_Nameplates_OverlayCatalog"
require "PNC/UI/PNC_Nameplates_OverlayToggles"
require "PNC/UI/PNC_Nameplates_Manager"
require "PNC/UI/PNC_Nameplates_Lifecycle"
