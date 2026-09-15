-- Faction debug window translation helpers.


PNC = PNC or {}
PNC.FactionDebugUI = PNC.FactionDebugUI or {}

local FactionUI = PNC.FactionDebugUI
local Internal = FactionUI.Internal or {}
FactionUI.Internal = Internal
local function text(key)
    return getText and PNC.Translation.GetKey(key) or key
end

Internal.Text = text
