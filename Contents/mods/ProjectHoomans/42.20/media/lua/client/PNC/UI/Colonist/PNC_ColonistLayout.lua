require "PsychopatzCore/UI/PsychopatzUI"

local LayoutModel = {}
local Layout = PsychopatzCore.UI.Layout

local function setPane(window, pane, rect)
    if not pane or not rect then return end
    Layout.SetBounds(pane, rect.x, rect.y, rect.width, rect.height)
    pane.uiScale = window.uiScale
    pane:layoutContent()
end

function LayoutModel.Calculate(window, tabButtons, tabDefinition)
    -- Keep the two-pane relationship even at the smallest supported size:
    -- the colonist roster is permanent and tab content never replaces it.
    local rect = window:getContentRect({ top = 30, bottom = 12 })
    local scale = window.uiScale or Layout.Scale()
    local px = function(value) return Layout.Pixels(value, scale) end
    local gap = px(12)
    local rosterWidth = math.min(px(300), math.max(px(240),
        math.floor(rect.width * 0.36)))
    local detailsX = rect.x + rosterWidth + gap
    local detailsWidth = math.max(px(240), rect.width - rosterWidth - gap)
    local tabs = Layout.Flow(tabButtons, {
        x = detailsX,
        y = rect.y,
        width = detailsWidth,
    }, {
        scale = scale,
        minWidth = 96,
        gap = 6,
    })
    local bodyY = tabs.bottom + px(10)
    local controlsHeight = 0
    if tabDefinition and tabDefinition.getControlsHeight then
        controlsHeight = math.max(0, tonumber(tabDefinition.getControlsHeight(
            window, detailsWidth, Layout)) or 0)
    end
    local controlsGap = controlsHeight > 0 and px(8) or 0
    local detailsY = bodyY + controlsHeight + controlsGap
    local bodyHeight = math.max(px(120), rect.y + rect.height - detailsY)

    return {
        rect = rect,
        tabs = {
            x = detailsX,
            y = rect.y,
            width = detailsWidth,
            height = tabs.height,
        },
        controls = controlsHeight > 0 and {
            x = detailsX,
            y = bodyY,
            width = detailsWidth,
            height = controlsHeight,
        } or nil,
        people = {
            x = rect.x,
            y = rect.y,
            width = rosterWidth,
            height = rect.height,
        },
        details = {
            x = detailsX,
            y = detailsY,
            width = detailsWidth,
            height = bodyHeight,
        },
    }
end

function LayoutModel.Apply(window)
    setPane(window, window.peoplePane, window.layout.people)
    setPane(window, window.detailsPane, window.layout.details)
    if window.tabControlsPane then
        if window.layout.controls then
            Layout.SetBounds(window.tabControlsPane,
                window.layout.controls.x, window.layout.controls.y,
                window.layout.controls.width, window.layout.controls.height)
            window.tabControlsPane.uiScale = window.uiScale
        else
            Layout.SetBounds(window.tabControlsPane, 0, 0, 1, 1)
        end
    end
end

return LayoutModel
