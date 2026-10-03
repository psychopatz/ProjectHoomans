require "PsychopatzCore/UI/PsychopatzUI"
require "ISUI/ISComboBox"
require "PNC/UI/Relationships/PNC_RelationshipDebugModel"
require "PNC/UI/Relationships/PNC_RelationshipGraphPanel"
local Controls = require
    "PNC/UI/Relationships/PNC_RelationshipDebugWindow_Controls"

PNC.RelationshipDebugUI = PNC.RelationshipDebugUI or {}

local RelationshipUI = PNC.RelationshipDebugUI
local Model = PNC.RelationshipDebugModel
local ClientState = PNC.Network.ClientState
local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout

local function drawEntity(list, y, entry, alternate)
    local item = entry.item
    local height = list.itemheight
    UI.DrawListSelection(
        list,
        y,
        height,
        list.selected == entry.index,
        alternate
    )
    local color = Theme.colors.text
    local muted = Theme.colors.textMuted
    list:drawText(
        Layout.Ellipsize(
            item.label or item.name or item.id,
            UIFont.Small,
            list:getWidth() - 20
        ),
        10, y + 5,
        color.r, color.g, color.b, color.a,
        UIFont.Small
    )
    list:drawText(
        Layout.Ellipsize(
            item.key or item.id or item.kind,
            UIFont.Small,
            list:getWidth() - 20
        ),
        10, y + 24,
        muted.r, muted.g, muted.b, muted.a,
        UIFont.Small
    )
    return y + height
end

ISPNCRelationshipDebugWindow =
    PsychopatzWindow:derive("ISPNCRelationshipDebugWindow")

function ISPNCRelationshipDebugWindow:initialise()
    PsychopatzWindow.initialise(self)
end

function ISPNCRelationshipDebugWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.observers = UI.CreateList(self, {
        itemHeight = Layout.Pixels(44, self.uiScale),
        doDrawItem = drawEntity,
    })
    self.targets = UI.CreateList(self, {
        itemHeight = Layout.Pixels(44, self.uiScale),
        doDrawItem = drawEntity,
    })
    self.details = UI.CreateKeyValueList(self, {
        itemHeight = Layout.Pixels(27, self.uiScale),
        labelX = 10,
        labelY = 6,
        valueY = 6,
        labelWidth = 150,
        labelWidthRatio = 0.34,
        valueXOffset = 2,
        valueRightPadding = 12,
        valueMinimumWidth = 40,
    })
    self.actionCombo = ISComboBox:new(
        0,
        0,
        240,
        Layout.Pixels(26, self.uiScale),
        self,
        ISPNCRelationshipDebugWindow.onActionChanged
    )
    self.actionCombo:initialise()
    self.actionCombo:instantiate()
    self:addChild(self.actionCombo)
    for _, requirement in ipairs(
        PNC.RelationshipGraph.ListRequirements()
    ) do
        self.actionCombo:addOptionWithData(
            requirement.label,
            requirement.id
        )
    end
    if self.actionCombo.selectData then
        self.actionCombo:selectData("inspect")
    end
    self.graph = ISPNCRelationshipGraphPanel:new(
        0,
        0,
        320,
        420
    )
    self.graph:initialise()
    self.graph:instantiate()
    self:addChild(self.graph)
    Controls.Create(self, ISPNCRelationshipDebugWindow, UI, Layout)
    self:requestResponsiveLayout(true)
    self:refreshRoster()
    self:requestRoster()
end

function ISPNCRelationshipDebugWindow:onResponsiveLayout()
    local rect = self:getContentRect({ top = 28, bottom = 12 })
    local controls = Layout.Flow(
        self.controls,
        { x = rect.x, y = rect.y, width = rect.width },
        { scale = self.uiScale, minWidth = 72 }
    )
    local customY = controls.bottom + Layout.Pixels(5, self.uiScale)
    local entryWidth = Layout.Pixels(86, self.uiScale)
    Layout.SetBounds(
        self.customApproval,
        rect.x,
        customY,
        entryWidth,
        Layout.Pixels(26, self.uiScale)
    )
    Layout.SetBounds(
        self.customRespect,
        rect.x + entryWidth + Layout.Pixels(5, self.uiScale),
        customY,
        entryWidth,
        Layout.Pixels(26, self.uiScale)
    )
    Layout.SetBounds(
        self.applyCustomButton,
        rect.x + entryWidth * 2 + Layout.Pixels(10, self.uiScale),
        customY,
        Layout.Pixels(180, self.uiScale),
        Layout.Pixels(26, self.uiScale)
    )
    local tabs = Layout.Flow(
        self.sectionControls,
        {
            x = rect.x,
            y = customY + Layout.Pixels(31, self.uiScale),
            width = rect.width,
        },
        { scale = self.uiScale, minWidth = 82 }
    )
    local top = tabs.bottom + Layout.Pixels(25, self.uiScale)
    local height = math.max(
        100,
        rect.y + rect.height - top
    )
    local gap = Layout.Pixels(8, self.uiScale)
    local leftWidth = math.max(
        145,
        math.floor(rect.width * 0.15)
    )
    local graphWidth = math.max(
        300,
        math.min(410, math.floor(rect.width * 0.31))
    )
    local detailWidth = math.max(
        240,
        rect.width - leftWidth * 2 - graphWidth - gap * 3
    )
    self.layout = {
        custom = {
            x = rect.x,
            y = customY,
            width = rect.width,
        },
        observer = {
            x = rect.x, y = top,
            width = leftWidth, height = height,
        },
        target = {
            x = rect.x + leftWidth + gap, y = top,
            width = leftWidth, height = height,
        },
        graph = {
            x = rect.x + leftWidth * 2 + gap * 2, y = top,
            width = graphWidth, height = height,
        },
        detail = {
            x = rect.x + leftWidth * 2
                + graphWidth + gap * 3,
            y = top,
            width = detailWidth, height = height,
        },
    }
    Layout.SetBounds(
        self.observers,
        self.layout.observer.x,
        self.layout.observer.y,
        self.layout.observer.width,
        self.layout.observer.height
    )
    Layout.SetBounds(
        self.targets,
        self.layout.target.x,
        self.layout.target.y,
        self.layout.target.width,
        self.layout.target.height
    )
    Layout.SetBounds(
        self.actionCombo,
        self.layout.graph.x,
        self.layout.graph.y,
        self.layout.graph.width,
        Layout.Pixels(26, self.uiScale)
    )
    Layout.SetBounds(
        self.graph,
        self.layout.graph.x,
        self.layout.graph.y + Layout.Pixels(32, self.uiScale),
        self.layout.graph.width,
        self.layout.graph.height - Layout.Pixels(32, self.uiScale)
    )
    Layout.SetBounds(
        self.details,
        self.layout.detail.x,
        self.layout.detail.y,
        self.layout.detail.width,
        self.layout.detail.height
    )
end



return PNC.RelationshipDebugUI
