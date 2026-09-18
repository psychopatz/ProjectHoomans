-- Compatibility and load-order hub for the Puppet Opera layout editor.
--
-- Keep this public module path and class name stable.  The implementation is
-- split into cohesive UI spokes so callers do not need to know the internal
-- migration and Project Zomboid's Lua load order remains explicit.

require "ISUI/ISPanel"
require "PsychopatzCore/UI/PsychopatzUI"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaAnchorGrid"

PNC = PNC or {}

local UI = PsychopatzCore.UI
local Internal = PNC.PuppetOperaLayoutTabInternal
if not Internal then
    Internal = {}
    PNC.PuppetOperaLayoutTabInternal = Internal
end
Internal.UI = UI
Internal.Layout = UI.Layout
Internal.addDetail = UI.AddKeyValue

ISPNCPuppetOperaLayoutTab = ISPanel:derive("ISPNCPuppetOperaLayoutTab")

require "PNC/UI/PuppetOpera/PNC_PuppetOperaLayoutTab_Presentation"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaLayoutTab_LiveDrag"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaLayoutTab_Lifecycle"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaLayoutTab_Refresh"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaLayoutTab_Responsive"

return ISPNCPuppetOperaLayoutTab
