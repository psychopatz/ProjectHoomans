-- Compatibility and load-order hub for Puppet Opera window presentation.

PNC = PNC or {}

local Internal = PNC.ChoreographyDebugWindow.Internal
local Class = ISPNCChoreographyDebugWindow

-- Contracts load first because Tabs, Refresh, Actions, and Lifecycle consume
-- the translated labels during their own module initialization.
require "PNC/UI/Choreography/PNC_ChoreographyDebugWindow_Presentation_Contracts"
require "PNC/UI/Choreography/PNC_ChoreographyDebugWindow_Presentation_Responsive"
require "PNC/UI/Choreography/PNC_ChoreographyDebugWindow_Presentation_Render"

return Class
