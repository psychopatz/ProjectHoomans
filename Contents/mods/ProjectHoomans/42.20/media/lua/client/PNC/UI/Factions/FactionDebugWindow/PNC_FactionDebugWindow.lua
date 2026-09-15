-- Ordered entry point for the faction debug window.

require "PsychopatzCore/UI/PsychopatzUI"
require "PNC/UI/Factions/FactionDebugModel/PNC_FactionDebugModel"
require "PNC/UI/Factions/FactionDebugOverlay/PNC_FactionDebugOverlay"
require "PNC/UI/Factions/PNC_FactionEmblemEditor"
require "PNC/UI/Factions/PNC_FactionMemberWindow"

PNC = PNC or {}
PNC.FactionDebugUI = PNC.FactionDebugUI or {}

local FactionUI = PNC.FactionDebugUI
local Internal = FactionUI.Internal or {}
FactionUI.Internal = Internal

Internal.Model = PNC.FactionDebugModel
Internal.ClientState = PNC.Network.ClientState
Internal.UI = PsychopatzCore.UI
Internal.Theme = Internal.UI.Theme
Internal.Layout = Internal.UI.Layout

require "PNC/UI/Factions/FactionDebugWindow/PNC_FactionDebugWindow_Config"
require "PNC/UI/Factions/FactionDebugWindow/PNC_FactionDebugWindow_Controls"

ISPNCFactionDebugWindow =
    PsychopatzWindow:derive("ISPNCFactionDebugWindow")

require "PNC/UI/Factions/FactionDebugWindow/PNC_FactionDebugWindow_Lists"
require "PNC/UI/Factions/FactionDebugWindow/PNC_FactionDebugWindow_Setup"
require "PNC/UI/Factions/FactionDebugWindow/PNC_FactionDebugWindow_Layout"
require "PNC/UI/Factions/FactionDebugWindow/PNC_FactionDebugWindow_Snapshot"
require "PNC/UI/Factions/FactionDebugWindow/PNC_FactionDebugWindow_ActionsNavigation"
require "PNC/UI/Factions/FactionDebugWindow/PNC_FactionDebugWindow_ActionsModes"
require "PNC/UI/Factions/FactionDebugWindow/PNC_FactionDebugWindow_ActionPayload"
require "PNC/UI/Factions/FactionDebugWindow/PNC_FactionDebugWindow_Actions"
require "PNC/UI/Factions/FactionDebugWindow/PNC_FactionDebugWindow_ControlState"
require "PNC/UI/Factions/FactionDebugWindow/PNC_FactionDebugWindow_Rendering"
require "PNC/UI/Factions/FactionDebugWindow/PNC_FactionDebugWindow_Lifecycle"

return FactionUI
