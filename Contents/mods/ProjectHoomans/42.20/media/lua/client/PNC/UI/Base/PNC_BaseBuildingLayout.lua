require "PsychopatzCore/UI/PsychopatzUI"

local LayoutModel = {}
local UI = PsychopatzCore.UI
local Layout = UI.Layout
local Controls = require
    "PNC/UI/Base/PNC_BaseBuildingLayout_Controls"
local Panes = require
    "PNC/UI/Base/PNC_BaseBuildingLayout_Panes"

function LayoutModel.Apply(window, content)
    local gap = Layout.Pixels(8, window.uiScale)
    local buttonHeight = Layout.Pixels(28, window.uiScale)
    local width, height = content.width, content.height
    local toolbarY = Controls.ApplyCategories(window, content, Layout,
        gap, buttonHeight, width)
    local metrics = Controls.BuildFooter(window, content, Layout, width,
        height, gap, buttonHeight, toolbarY)
    Panes.Apply(window, content, Layout, metrics)
    Controls.ApplyFooter(window, content, Layout, metrics)

end

return LayoutModel
