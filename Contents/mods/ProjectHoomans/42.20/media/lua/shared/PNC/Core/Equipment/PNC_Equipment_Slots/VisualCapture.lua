PNC = PNC or {}
PNC.Equipment = PNC.Equipment or {}
PNC.Equipment.Internal = PNC.Equipment.Internal or {}

local Equipment = PNC.Equipment
local Internal = Equipment.Internal

function Internal.VisualStateSignature(state)
    local tint = state and state.tint or {}
    local color = state and state.color or {}
    return table.concat({
        tostring(state and state.fullType or ""),
        tostring(state and state.baseTexture or ""),
        tostring(state and state.hue or ""),
        tostring(state and state.textureChoice or ""),
        tostring(state and state.decal or ""),
        tostring(tint.r or ""),
        tostring(tint.g or ""),
        tostring(tint.b or ""),
        tostring(state and state.modelIndex or ""),
        tostring(state and state.customColor == true),
        tostring(color.r or ""),
        tostring(color.g or ""),
        tostring(color.b or ""),
    }, ":")
end

local VisualState = require "PsychopatzCore/Inventory/PsychopatzItemVisualState"
Equipment.CaptureItemVisualState = VisualState.Capture
