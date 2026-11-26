-- Compatibility and load-order hub for the Puppet Opera layout editor.
--
-- Keep this public module path and class name stable.  The implementation is
-- split into cohesive UI spokes so callers do not need to know the internal
-- migration and Project Zomboid's Lua load order remains explicit.

require "ISUI/ISPanel"
require "PsychopatzCore/UI/PsychopatzUI"
require "PNC/UI/Choreography/PNC_ChoreographyAnchorGrid"
require "PNC/UI/Choreography/PNC_ChoreographyTimelinePanel"

PNC = PNC or {}

local UI = PsychopatzCore.UI
local Internal = PNC.ChoreographyLayoutTabInternal
if not Internal then
    Internal = {}
    PNC.ChoreographyLayoutTabInternal = Internal
end
Internal.UI = UI
Internal.Layout = UI.Layout
Internal.addDetail = UI.AddKeyValue

ISPNCChoreographyLayoutTab = ISPanel:derive("ISPNCChoreographyLayoutTab")

require "PNC/UI/Choreography/PNC_ChoreographyLayoutTab_Presentation"
require "PNC/UI/Choreography/PNC_ChoreographyLayoutTab_LiveDrag"
require "PNC/UI/Choreography/PNC_ChoreographyLayoutTab_Lifecycle"
require "PNC/UI/Choreography/PNC_ChoreographyLayoutTab_Refresh"
require "PNC/UI/Choreography/PNC_ChoreographyLayoutTab_Responsive"

return ISPNCChoreographyLayoutTab
