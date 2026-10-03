-- Client prompt shown when semantic policy asks the player to clarify.
require "PsychopatzCore/UI/PsychopatzUI"
require "ISUI/ISComboBox"
require "ISUI/ISLabel"
require "PNC/Semantics/PNC_SemanticDialoguePolicy"
require "PNC/Semantics/PNC_SemanticTelemetryStorage"

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local TelemetryPrompt = PNC.Semantics.SemanticTelemetryPrompt or {}
PNC.Semantics.SemanticTelemetryPrompt = TelemetryPrompt
TelemetryPrompt.Queue = TelemetryPrompt.Queue or {}
TelemetryPrompt.Seen = TelemetryPrompt.Seen or {}
TelemetryPrompt.SeenOrder = TelemetryPrompt.SeenOrder or {}
TelemetryPrompt.Internal = TelemetryPrompt.Internal or {}

require "PNC/Semantics/PNC_SemanticTelemetryPrompt_Window"
require "PNC/Semantics/PNC_SemanticTelemetryPrompt_Queue"

return TelemetryPrompt
