require "PsychopatzCore/UI/PsychopatzUI"

local LayoutModel = {}

function LayoutModel.SetPane(window, pane, rect)
    if not pane or not rect then return end
    local Layout = PsychopatzCore.UI.Layout
    Layout.SetBounds(pane, rect.x, rect.y, rect.width, rect.height)
    pane.uiScale = window.uiScale
    if pane.layoutContent then pane:layoutContent() end
end

function LayoutModel.ApplyResponsiveLayout(window)
    local Layout = PsychopatzCore.UI.Layout
    local rect = window:getContentRect({ top = 28, bottom = 12 })
    local scale = window.uiScale or Layout.Scale()
    local px = function(value) return Layout.Pixels(value, scale) end
    local gap = px(8)
    local summaryHeight = px(62)
    local toolbarY = rect.y + summaryHeight + gap
    local filterFlow = Layout.Flow(window.filterButtons, {
        x = rect.x, y = toolbarY, width = rect.width,
    }, { scale = scale, minWidth = 96, gap = 5 })
    local actionFlow = Layout.Flow({ window.pauseButton, window.cancelButton,
        window.debugToggle }, {
        x = rect.x, y = filterFlow.bottom + gap, width = rect.width,
    }, { scale = scale, minWidth = 118, gap = 5 })
    local debugFlow
    local debugAuthorized = window.snapshot and window.snapshot.storage
        and window.snapshot.storage.debugAuthorized == true or false
    if debugAuthorized and window.debugExpanded then
        debugFlow = Layout.Flow({ window.debugBlueprint, window.debugSpearKit }, {
            x = rect.x, y = actionFlow.bottom + gap, width = rect.width,
        }, { scale = scale, minWidth = 210, gap = 5 })
    end
    local controlsBottom = debugFlow and debugFlow.bottom or actionFlow.bottom
    local bodyY = controlsBottom + gap
    local bodyBottom = rect.y + rect.height
    local bodyHeight = math.max(px(150), bodyBottom - bodyY)
    local leftWidth = math.min(px(380), math.max(px(250),
        math.floor((rect.width - gap) * 0.34)))
    local rightWidth = math.max(px(260), rect.width - leftWidth - gap)
    local rightX = rect.x + leftWidth + gap
    local queueHeight = #(window.researchView
        and window.researchView.activeQueue or {}) > 0
        and math.min(px(108), math.max(px(74), math.floor(bodyHeight * 0.24)))
        or 0
    window.layout = {
        rect = rect,
        summary = { x = rect.x, y = rect.y, width = rect.width,
            height = summaryHeight },
        catalog = { x = rect.x, y = bodyY, width = leftWidth,
            height = bodyHeight },
        queue = { x = rightX, y = bodyY, width = rightWidth,
            height = queueHeight },
        details = { x = rightX, y = bodyY + queueHeight
                + (queueHeight > 0 and gap or 0), width = rightWidth,
            height = bodyHeight - queueHeight
                - (queueHeight > 0 and gap or 0) },
    }
    LayoutModel.SetPane(window, window.catalogPane, window.layout.catalog)
    if queueHeight > 0 then
        window.queuePane:setVisible(true)
        LayoutModel.SetPane(window, window.queuePane, window.layout.queue)
    else
        window.queuePane:setVisible(false)
    end
    LayoutModel.SetPane(window, window.detailsPane, window.layout.details)
    window.detailsPane.uiScale = scale
    window.detailsPane:layoutContent()
    window.debugBlueprint:setVisible(debugAuthorized and window.debugExpanded)
    window.debugSpearKit:setVisible(debugAuthorized and window.debugExpanded)
    window.debugToggle:setVisible(debugAuthorized)
end

return LayoutModel
