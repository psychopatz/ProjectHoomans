-- Compatibility and load-order hub for Puppet Opera window presentation.

PNC = PNC or {}

local Internal = PNC.PuppetOperaDebugWindow.Internal
local Class = ISPNCPuppetOperaDebugWindow

-- Contracts load first because Tabs, Refresh, Actions, and Lifecycle consume
-- the translated labels during their own module initialization.
require "PNC/UI/PuppetOpera/PNC_PuppetOperaDebugWindow_Presentation_Contracts"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaDebugWindow_Presentation_Responsive"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaDebugWindow_Presentation_Render"

return Class
