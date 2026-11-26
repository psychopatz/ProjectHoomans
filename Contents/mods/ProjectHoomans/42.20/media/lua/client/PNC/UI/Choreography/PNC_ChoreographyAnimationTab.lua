-- Compatibility and load-order hub for the Puppet Opera animation catalog tab.
--
-- Keep this public module path and class name stable.  The implementation is
-- split into cohesive UI spokes so the debug window can continue constructing
-- both catalog variants through the existing global class contract.

require "ISUI/ISPanel"
require "ISUI/ISComboBox"
require "PsychopatzCore/UI/PsychopatzUI"

PNC = PNC or {}

local UI = PsychopatzCore.UI
local Internal = PNC.ChoreographyAnimationTabInternal
if not Internal then
    Internal = {}
    PNC.ChoreographyAnimationTabInternal = Internal
end
Internal.UI = UI
Internal.Layout = UI.Layout
Internal.addDetail = UI.AddKeyValue

ISPNCChoreographyAnimationTab = ISPanel:derive(
    "ISPNCChoreographyAnimationTab")

require "PNC/UI/Choreography/PNC_ChoreographyAnimationTab_Presentation"
require "PNC/UI/Choreography/PNC_ChoreographyAnimationTab_Lifecycle"
require "PNC/UI/Choreography/PNC_ChoreographyAnimationTab_Catalog"
require "PNC/UI/Choreography/PNC_ChoreographyAnimationTab_Details"
require "PNC/UI/Choreography/PNC_ChoreographyAnimationTab_Actions"
require "PNC/UI/Choreography/PNC_ChoreographyAnimationTab_Responsive"

return ISPNCChoreographyAnimationTab
