require "PsychopatzCore/UI/PsychopatzUI"

local LayoutModel = {}
local Layout = PsychopatzCore.UI.Layout

function LayoutModel.SetPane(window, pane, rect)
    Layout.SetBounds(pane, rect.x, rect.y, rect.width, rect.height)
    pane.uiScale = window.uiScale
    pane:layoutContent()
end

function LayoutModel.Calculate(window, navigation)
    local rect = window:getContentRect({ top = 34, bottom = 12 })
    local flow = Layout.Flow(
        navigation,
        { x = rect.x, y = rect.y, width = rect.width },
        { scale = window.uiScale, minWidth = 92, gap = 6 }
    )
    local summaryHeight = Layout.Pixels(64, window.uiScale)
    local summaryY = flow.bottom + Layout.Pixels(10, window.uiScale)
    local sectionY = summaryY + summaryHeight
        + Layout.Pixels(10, window.uiScale)
    local content = {
        x = rect.x,
        y = sectionY,
        width = rect.width,
        height = math.max(80, rect.y + rect.height - sectionY),
    }
    local split = Layout.Split(content, {
        scale = window.uiScale,
        firstRatio = 0.36,
        topRatio = 0.42,
        breakpoint = 780,
        gap = 12,
    })
    return {
        summary = {
            x = rect.x,
            y = summaryY,
            width = rect.width,
            height = summaryHeight,
        },
        people = split.first,
        details = split.second,
        compact = split.compact,
        content = content,
    }
end

function LayoutModel.ApplyBase(window)
    LayoutModel.SetPane(window, window.peoplePane, window.layout.people)
    LayoutModel.SetPane(window, window.detailsPane, window.layout.details)
end

return LayoutModel
