require "PsychopatzCore/UI/PsychopatzUI"
require "ISUI/ISComboBox"
require "PNC/Debug/PNC_AnimationSceneDebugModel"

PNC = PNC or {}
PNC.AnimationSceneDebugWindow =
    PNC.AnimationSceneDebugWindow or {}

local WindowAPI = PNC.AnimationSceneDebugWindow
local Model = PNC.AnimationSceneDebugModel
local UI = PsychopatzCore.UI
local Layout = UI.Layout
local addDetail = UI.AddKeyValue

ISPNCAnimationSceneDebugWindow =
    PsychopatzWindow:derive(
        "ISPNCAnimationSceneDebugWindow"
    )

local function drawSceneItem(list, y, row, alternate)
    local scene = row.item
    local selected = list.selected == row.index
    if selected then
        list:drawRect(
            0, y, list:getWidth(), list.itemheight,
            0.35, 0.20, 0.52, 0.78
        )
    elseif alternate then
        list:drawRect(
            0, y, list:getWidth(), list.itemheight,
            0.12, 0.16, 0.18, 0.20
        )
    end
    list:drawText(
        tostring(scene.label or scene.id),
        8, y + 5,
        0.92, 0.94, 1.00, 1,
        UIFont.Small
    )
    list:drawText(
        tostring(scene.id)
            .. "  →  PNC_" .. tostring(scene.bump),
        8, y + 23,
        0.58, 0.82, 0.95, 1,
        UIFont.Small
    )
    list:drawText(
        "category=" .. tostring(scene.category)
            .. "  pool=" .. tostring(scene.pool or "-")
            .. "  weight=" .. tostring(scene.weight),
        8, y + 41,
        0.70, 0.72, 0.74, 1,
        UIFont.Small
    )
    return y + list.itemheight
end

function ISPNCAnimationSceneDebugWindow:initialise()
    PsychopatzWindow.initialise(self)
end

function ISPNCAnimationSceneDebugWindow:createChildren()
    PsychopatzWindow.createChildren(self)

    self.search = UI.CreateTextEntry(self, {
        clearButton = true,
        width = 100,
        height = 26,
        onTextChange = function()
            self:refreshCatalog()
        end,
    })

    self.groupFilter = ISComboBox:new(
        0, 0, 180, 26, self,
        ISPNCAnimationSceneDebugWindow.onGroupChanged
    )
    self.groupFilter:initialise()
    self.groupFilter:instantiate()
    self:addChild(self.groupFilter)

    self.gapEntry = UI.CreateTextEntry(self, {
        text = "750",
        width = 90,
        height = 26,
        onlyNumbers = true,
    })

    self.list = UI.CreateList(self, {
        itemHeight = 59,
        doDrawItem = drawSceneItem,
    })
    self.details = UI.CreateKeyValueList(self, {
        itemHeight = 26,
        valueXMax = 152,
        valueXRatio = 0.35,
        ellipsize = false,
        labelX = 8,
        labelY = 6,
        valueY = 6,
        labelColor = { r = 0.62, g = 0.72, b = 0.80, a = 1 },
        valueColor = { r = 0.92, g = 0.92, b = 0.92, a = 1 },
        warningColor = { r = 1.0, g = 0.52, b = 0.28, a = 1 },
        alternateColor = { r = 0.16, g = 0.18, b = 0.20, a = 1 },
        alternateAlpha = 0.12,
        drawSelection = false,
    })

    self.buttons = {}
    local definitions = {
        { "play", "Play Scene", "onPlay", "selected" },
        { "step", "Roll Pool Once", "onStep", "warning" },
        { "cycle", "Auto Cycle Pool", "onCycle", "warning" },
        { "stop", "Stop Scene / Cycle", "onStop", "danger" },
        { "overlay", "Scene Overlay", "onOverlay", "quiet" },
        { "refresh", "Refresh Registry", "onRefresh", "quiet" },
        { "xml", "Open XML Player", "onOpenXML", "quiet" },
    }
    for _, definition in ipairs(definitions) do
        local button = UI.CreateButton(self, {
            id = definition[1],
            title = definition[2],
            target = self,
            onclick =
                ISPNCAnimationSceneDebugWindow[
                    definition[3]
                ],
            variant = definition[4],
        })
        self.buttons[#self.buttons + 1] = button
        self[definition[1] .. "Button"] = button
    end
    self:refreshGroups()
    self:refreshCatalog()
    self:requestResponsiveLayout(true)
end

function ISPNCAnimationSceneDebugWindow:onResponsiveLayout()
    local width = self:getWidth()
    local height = self:getHeight()
    local margin = 12
    local top = 58
    local gapWidth = 92
    local groupWidth = math.max(
        170,
        math.floor(width * 0.26)
    )
    local searchWidth = math.max(
        190,
        width - margin * 2 - groupWidth
            - gapWidth - 16
    )
    local groupX = margin + searchWidth + 8
    Layout.SetBounds(self.search, margin, top, searchWidth, 26)
    Layout.SetBounds(self.groupFilter, groupX, top, groupWidth, 26)
    Layout.SetBounds(self.gapEntry, groupX + groupWidth + 8, top,
        gapWidth, 26)

    local buttonsTop = height - 43
    local mainTop = top + 36
    local mainHeight = math.max(
        130,
        buttonsTop - mainTop - 10
    )
    local leftWidth = math.max(
        280,
        math.floor((width - margin * 3) * 0.53)
    )
    Layout.SetBounds(self.list, margin, mainTop, leftWidth, mainHeight)
    Layout.SetBounds(self.details, margin * 2 + leftWidth, mainTop,
        math.max(220, width - leftWidth - margin * 3), mainHeight)

    local buttonWidth = math.max(
        112,
        math.floor(
            (width - margin * 2 - 40)
                / #self.buttons
        )
    )
    local x = margin
    for _, button in ipairs(self.buttons) do
        Layout.SetBounds(button, x, buttonsTop, buttonWidth, 28)
        x = x + buttonWidth + 8
    end
end

return WindowAPI
