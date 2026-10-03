-- Built-in NPC traits. These deliberately separate player traits;
-- same display concept may have different simulation effects for an NPC.
PNC = PNC or {}
local Traits = PNC.NPCTraits

-- Temporary shared icon until dedicated NPC combat trait art is authored.
local PLACEHOLDER_ICON = "media/ui/Traits/trait_pnc_friendly.png"
Traits.Internal = Traits.Internal or {}
local Internal = Traits.Internal

local function register(definition)
    local ok, reason = Traits.Register(definition)
    if not ok and PNC.Core and PNC.Core.LogWarn then
        PNC.Core.LogWarn("NPC trait registration failed id="
            .. tostring(definition and definition.id or "")
            .. " reason=" .. tostring(reason))
    end
end

Internal.Register = register
Internal.PlaceholderIcon = PLACEHOLDER_ICON

require "PNC/Core/Traits/PNC_NPCTraitDefinitions_Core"
require "PNC/Core/Traits/PNC_NPCTraitDefinitions_Additional"
