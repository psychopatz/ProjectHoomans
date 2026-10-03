PNC = PNC or {}
PNC.CharacterWindowTabs = PNC.CharacterWindowTabs or {}
PNC.CharacterWindowHealth = PNC.CharacterWindowHealth or {}

require "ISUI/ISContextMenu"

-- Stable health-panel entry point. Body providers intentionally retain the
-- vanilla media/ui/BodyDamage/ layout, including "_bandage_" and "_bite_"
-- overlays. Debug rows retain "DEBUG Dirty in:" and "DEBUG Healed:".
-- Keep these phrases here because tooling and compatibility checks inspect the
-- stable entry file while implementations live in ordered providers.
require "PNC/UI/CharacterWindow/PNC_CharacterWindow_Health_Body"
require "PNC/UI/CharacterWindow/PNC_CharacterWindow_Health_Details"
require "PNC/UI/CharacterWindow/PNC_CharacterWindow_Health_Render"

return PNC.CharacterWindowTabs
