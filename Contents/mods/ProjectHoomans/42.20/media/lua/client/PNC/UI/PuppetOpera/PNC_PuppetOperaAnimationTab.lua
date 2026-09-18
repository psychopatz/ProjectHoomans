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
local Internal = PNC.PuppetOperaAnimationTabInternal
if not Internal then
    Internal = {}
    PNC.PuppetOperaAnimationTabInternal = Internal
end
Internal.UI = UI
Internal.Layout = UI.Layout
Internal.addDetail = UI.AddKeyValue

ISPNCPuppetOperaAnimationTab = ISPanel:derive(
    "ISPNCPuppetOperaAnimationTab")

require "PNC/UI/PuppetOpera/PNC_PuppetOperaAnimationTab_Presentation"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaAnimationTab_Lifecycle"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaAnimationTab_Catalog"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaAnimationTab_Details"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaAnimationTab_Actions"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaAnimationTab_Responsive"

return ISPNCPuppetOperaAnimationTab
