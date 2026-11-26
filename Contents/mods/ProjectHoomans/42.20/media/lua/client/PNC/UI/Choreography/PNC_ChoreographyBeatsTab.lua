-- Compatibility and load-order hub for the Puppet Opera beat editor tab.
--
-- Keep this public module path and class name stable. The implementation is
-- split into cohesive UI spokes so callers do not need to know how the tab is
-- assembled.

require "ISUI/ISPanel"
require "PsychopatzCore/UI/PsychopatzUI"

PNC = PNC or {}

local UI = PsychopatzCore.UI
local Internal = PNC.ChoreographyBeatsTabInternal
if not Internal then
    Internal = {}
    PNC.ChoreographyBeatsTabInternal = Internal
end
Internal.UI = UI
Internal.Layout = UI.Layout
Internal.addDetail = UI.AddKeyValue

ISPNCChoreographyBeatsTab = ISPanel:derive("ISPNCChoreographyBeatsTab")

require "PNC/UI/Choreography/PNC_ChoreographyBeatsTab_Presentation"
require "PNC/UI/Choreography/PNC_ChoreographyBeatsTab_Interaction"
require "PNC/UI/Choreography/PNC_ChoreographyBeatsTab_Lifecycle"
require "PNC/UI/Choreography/PNC_ChoreographyBeatsTab_Refresh"
require "PNC/UI/Choreography/PNC_ChoreographyBeatsTab_Actions"
require "PNC/UI/Choreography/PNC_ChoreographyBeatsTab_Responsive"

return ISPNCChoreographyBeatsTab
