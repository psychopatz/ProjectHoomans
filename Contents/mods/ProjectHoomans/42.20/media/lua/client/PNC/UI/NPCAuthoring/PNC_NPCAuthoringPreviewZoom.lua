local UI = PsychopatzCore.UI
local Zoom = {}

function Zoom.Build(parent, portrait)
    local buttons = {}
    for index, delta in ipairs({ -1, 1 }) do
        local out = delta < 0
        local button = UI.CreateButton(parent, {
            title = out and "-" or "+", target = portrait, variant = "quiet",
            onclick = function(target) target:zoomBy(delta, true) end,
        })
        button.tooltip = PNC.Translation.GetKey(
            out and "UI_PNC_Authoring_ZoomOut" or "UI_PNC_Authoring_ZoomIn",
            out and "Zoom out" or "Zoom in")
        buttons[index] = button
    end
    return buttons
end

function Zoom.Layout(buttons, x, y, width, height, gap, visible)
    local buttonWidth = math.max(1, (width - gap) / 2)
    for index, button in ipairs(buttons) do
        button:setVisible(visible)
        if visible then UI.Layout.SetBounds(button, x + (index - 1) * (buttonWidth + gap), y, buttonWidth, height) end
    end
end

return Zoom
