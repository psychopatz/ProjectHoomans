-- Compatibility and load-order hub for the Puppet Opera beat editor tab.
--
-- Keep this public module path and class name stable. The implementation is
-- split into cohesive UI spokes so callers do not need to know how the tab is
-- assembled.

require "ISUI/ISPanel"
require "PsychopatzCore/UI/PsychopatzUI"

PNC = PNC or {}

local UI = PsychopatzCore.UI
local Internal = PNC.PuppetOperaBeatsTabInternal
if not Internal then
    Internal = {}
    PNC.PuppetOperaBeatsTabInternal = Internal
end
Internal.UI = UI
Internal.Layout = UI.Layout
Internal.addDetail = UI.AddKeyValue

ISPNCPuppetOperaBeatsTab = ISPanel:derive("ISPNCPuppetOperaBeatsTab")

require "PNC/UI/PuppetOpera/PNC_PuppetOperaBeatsTab_Presentation"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaBeatsTab_Interaction"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaBeatsTab_Lifecycle"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaBeatsTab_Refresh"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaBeatsTab_Actions"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaBeatsTab_Responsive"

return ISPNCPuppetOperaBeatsTab
