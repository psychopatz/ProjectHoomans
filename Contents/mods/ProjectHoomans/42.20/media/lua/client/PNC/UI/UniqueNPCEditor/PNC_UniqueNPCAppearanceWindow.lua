require "ISUI/ISPanel"
require "ISUI/ISLabel"
require "ISUI/ISComboBox"
require "RadioCom/ISUIRadio/ISSliderPanel"
require "PsychopatzCore/UI/PsychopatzUI"
require "PNC/UI/PNC_AudioDebugModel"
require "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorModel"
pcall(require, "PNC/Core/Identity/PNC_Identity_Appearance")

PNC = PNC or {}
PNC.UniqueNPCAppearanceUI = PNC.UniqueNPCAppearanceUI or {}

local AppearanceUI = PNC.UniqueNPCAppearanceUI
local Model = PNC.UniqueNPCEditorModel
local Appearance = PNC.Identity and PNC.Identity.Appearance
local UI = PsychopatzCore.UI
local Layout = UI.Layout
local AudioDebug = PNC.AudioDebug

local function clamp(value, minimum, maximum)
    value = tonumber(value) or minimum
    return math.max(minimum, math.min(maximum, value))
end

local function setLabelText(label, value)
    value = tostring(value or "")
    if UI.SetLabelText then
        UI.SetLabelText(label, value)
    elseif label and label.setName then
        label:setName(value)
    end
end

local function setControlEnabled(control, enabled)
    if not control then return end
    if control.setEnabled then
        control:setEnabled(enabled == true)
    elseif control.setEnable then
        control:setEnable(enabled == true)
    end
end


local Internal = AppearanceUI.Internal or {}
Internal.Appearance = Appearance
Internal.Model = Model
Internal.UI = UI
Internal.Layout = Layout
Internal.AudioDebug = AudioDebug
Internal.clamp = clamp
Internal.setLabelText = setLabelText
Internal.setControlEnabled = setControlEnabled
AppearanceUI.Internal = Internal
require "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCAppearanceWindow_Options_Core"
require "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCAppearanceWindow_Options_Catalog"

ISPNCUniqueNPCAppearanceScrollPanel = ISPanel:derive(
    "ISPNCUniqueNPCAppearanceScrollPanel")

function ISPNCUniqueNPCAppearanceScrollPanel:initialise()
    ISPanel.initialise(self)
    self:noBackground()
end

function ISPNCUniqueNPCAppearanceScrollPanel:createChildren()
    ISPanel.createChildren(self)
    self:setScrollChildren(true)
    self:addScrollBars()
end

function ISPNCUniqueNPCAppearanceScrollPanel:onResize()
    if self.vscroll then
        local scrollWidth = self.vscroll.getWidth
            and self.vscroll:getWidth() or self.vscroll.width or 13
        self.vscroll:setX(math.max(0, self.width - scrollWidth))
        self.vscroll:setHeight(self.height)
    end
end

function ISPNCUniqueNPCAppearanceScrollPanel:onMouseWheel(delta)
    local current = self.getYScroll and tonumber(self:getYScroll()) or 0
    local maximum = math.max(0,
        (tonumber(self.contentHeight) or 0) - (tonumber(self.height) or 0))
    if self.setYScroll then
        self:setYScroll(math.max(-maximum, math.min(0,
            current + (tonumber(delta) or 0) * 32)))
    end
    return true
end

function ISPNCUniqueNPCAppearanceScrollPanel:prerender()
    ISPanel.prerender(self)
    self:setStencilRect(0, 0, self.width, self.height)
end

function ISPNCUniqueNPCAppearanceScrollPanel:render()
    ISPanel.render(self)
    self:clearStencilRect()
end


ISPNCUniqueNPCAppearanceWindow = ISPanel:derive(
    "ISPNCUniqueNPCAppearanceWindow")

function ISPNCUniqueNPCAppearanceWindow:initialise()
    ISPanel.initialise(self)
    self:noBackground()
end

function ISPNCUniqueNPCAppearanceWindow:render()
    ISPanel.render(self)
    if self.content then
        self.content:setScrollHeight(self.content.contentHeight or 0)
        self.content.maxScroll = math.max(0,
            (self.content.contentHeight or 0) - (self.content.height or 0))
        if self.content.getYScroll and self.content.setYScroll then
            self.content:setYScroll(math.max(-self.content.maxScroll,
                math.min(0, self.content:getYScroll())))
        end
    end
end

function ISPNCUniqueNPCAppearanceWindow:new(x, y, width, height, options)
    local object = ISPanel:new(x, y, width, height)
    setmetatable(object, self)
    self.__index = self
    return object
end

function AppearanceUI.Open(editor)
    if editor and editor.showTab then
        return editor:showTab("Appearance")
    end
    return nil
end


ISPNCUniqueNPCAppearanceWindow.Internal = Internal
require "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCAppearanceWindow_Controls_Build"
require "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCAppearanceWindow_Controls_Options"
require "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCAppearanceWindow_Editing"
require "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCAppearanceWindow_Voice"
require "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCAppearanceWindow_Layout"
require "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCAppearanceWindow_DraftSync"

return AppearanceUI
