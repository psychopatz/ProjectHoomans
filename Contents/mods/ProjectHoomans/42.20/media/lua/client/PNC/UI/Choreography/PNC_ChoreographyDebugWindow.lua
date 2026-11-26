-- Compatibility and load-order hub for the Puppet Opera scene builder.
--
-- Keep this public module path and WindowAPI namespace stable.  The window
-- implementation is split into cohesive UI spokes so callers do not need to
-- know the internal migration and Project Zomboid's load order stays explicit.

require "ISUI/ISTabPanel"
require "ISUI/ISComboBox"
require "PsychopatzCore/UI/PsychopatzUI"
require "PNC/Choreography/PNC_Choreography_Client"
require "PNC/UI/Choreography/PNC_ChoreographyDebugModel"
require "PNC/UI/Choreography/PNC_ChoreographyLayoutTab"
require "PNC/UI/Choreography/PNC_ChoreographyAnimationTab"
require "PNC/UI/Choreography/PNC_ChoreographyBeatsTab"
require "PNC/UI/Choreography/PNC_ChoreographyTriggersTab"
require "PNC/UI/Choreography/PNC_ChoreographyTraceTab"

PNC = PNC or {}
PNC.ChoreographyDebugWindow = PNC.ChoreographyDebugWindow or {}

local WindowAPI = PNC.ChoreographyDebugWindow
local Internal = WindowAPI.Internal or {}
WindowAPI.Internal = Internal
Internal.Model = PNC.ChoreographyDebugModel
Internal.Client = PNC.Choreography.Client
Internal.UI = PsychopatzCore.UI
Internal.Layout = Internal.UI.Layout

ISPNCChoreographyDebugWindow = PsychopatzWindow:derive(
    "ISPNCChoreographyDebugWindow")

require "PNC/UI/Choreography/PNC_ChoreographyDebugWindow_Presentation"
require "PNC/UI/Choreography/PNC_ChoreographyDebugWindow_Tabs"
require "PNC/UI/Choreography/PNC_ChoreographyDebugWindow_Refresh"
require "PNC/UI/Choreography/PNC_ChoreographyDebugWindow_Actions"
require "PNC/UI/Choreography/PNC_ChoreographyDebugWindow_Lifecycle"

return WindowAPI
