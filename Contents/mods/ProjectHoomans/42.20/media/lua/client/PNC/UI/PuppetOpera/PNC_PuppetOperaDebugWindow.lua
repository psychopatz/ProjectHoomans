-- Compatibility and load-order hub for the Puppet Opera scene builder.
--
-- Keep this public module path and WindowAPI namespace stable.  The window
-- implementation is split into cohesive UI spokes so callers do not need to
-- know the internal migration and Project Zomboid's load order stays explicit.

require "ISUI/ISTabPanel"
require "ISUI/ISComboBox"
require "PsychopatzCore/UI/PsychopatzUI"
require "PNC/PuppetOpera/PNC_PuppetOpera_Client"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaDebugModel"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaLayoutTab"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaAnimationTab"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaBeatsTab"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaTraceTab"

PNC = PNC or {}
PNC.PuppetOperaDebugWindow = PNC.PuppetOperaDebugWindow or {}

local WindowAPI = PNC.PuppetOperaDebugWindow
local Internal = WindowAPI.Internal or {}
WindowAPI.Internal = Internal
Internal.Model = PNC.PuppetOperaDebugModel
Internal.Client = PNC.PuppetOpera.Client
Internal.UI = PsychopatzCore.UI
Internal.Layout = Internal.UI.Layout

ISPNCPuppetOperaDebugWindow = PsychopatzWindow:derive(
    "ISPNCPuppetOperaDebugWindow")

require "PNC/UI/PuppetOpera/PNC_PuppetOperaDebugWindow_Presentation"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaDebugWindow_Tabs"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaDebugWindow_Refresh"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaDebugWindow_Actions"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaDebugWindow_Lifecycle"

return WindowAPI
