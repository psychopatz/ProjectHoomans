-- Unified Props & Anchors tab for Animation Studio.
-- Combines standalone Hold Item attachment testing (e.g. cigarettes, food,
-- weapons) and Firearm Anchor muzzle/hand tuning behind a clean toggle.

require "ISUI/ISPanel"
require "PsychopatzCore/UI/PsychopatzUI"
require "PNC/UI/AnimationStudio/PNC_AnimationStudio_HoldItemPanel"
require "PNC/UI/AnimationStudio/PNC_AnimationStudio_FirearmAnchorPanel"

PNC = PNC or {}
PNC.AnimationStudioTabs = PNC.AnimationStudioTabs or {}

local UI = PsychopatzCore.UI
local Layout = UI.Layout

local function tr(key, fallback)
    local translation = PNC.Translation
    local value = translation and translation.GetKey
        and translation.GetKey(key, fallback) or fallback
    if not value or value == "" or value == key then return fallback end
    return value
end

local function setButtonState(button, title, variant)
    if not button then return end
    if button.setTitle then button:setTitle(title) else button.title = title end
    if UI.SetButtonVariant then UI.SetButtonVariant(button, variant) end
end

ISPNCAnimationStudioPropsTab = ISPanel:derive("ISPNCAnimationStudioPropsTab")

function ISPNCAnimationStudioPropsTab:initialise()
    ISPanel.initialise(self)
    self:noBackground()
end

function ISPNCAnimationStudioPropsTab:createChildren()
    ISPanel.createChildren(self)
    self.tool = "hold_item"

    self.holdItemBtn = UI.CreateButton(self, {
        title = tr("UI_PNC_AnimationStudio_HoldItem", "Hold Item"),
        target = self,
        onclick = UI.ButtonCallback(function() self:setTool("hold_item") end),
        variant = "selected",
    })
    self.anchorBtn = UI.CreateButton(self, {
        title = tr("UI_PNC_AnimationStudio_FirearmAnchor", "Firearm Anchor"),
        target = self,
        onclick = UI.ButtonCallback(function() self:setTool("anchor") end),
        variant = "quiet",
    })

    self.holdItemPanel = ISPNCNPCPresentationDebugHoldItemTab:new(0, 0, 1, 1)
    self.holdItemPanel:initialise()
    self.holdItemPanel:instantiate()
    self:addChild(self.holdItemPanel)

    self.anchorPanel = ISPNCNPCPresentationDebugAnchorTab:new(0, 0, 1, 1)
    self.anchorPanel:initialise()
    self.anchorPanel:instantiate()
    self.anchorPanel:setVisible(false)
    self:addChild(self.anchorPanel)

    self:onResponsiveLayout()
end

function ISPNCAnimationStudioPropsTab:setTool(tool)
    self.tool = tool == "anchor" and "anchor" or "hold_item"
    setButtonState(self.holdItemBtn, tr("UI_PNC_AnimationStudio_HoldItem", "Hold Item"),
        self.tool == "hold_item" and "selected" or "quiet")
    setButtonState(self.anchorBtn, tr("UI_PNC_AnimationStudio_FirearmAnchor", "Firearm Anchor"),
        self.tool == "anchor" and "selected" or "quiet")
    if self.holdItemPanel then self.holdItemPanel:setVisible(self.tool == "hold_item") end
    if self.anchorPanel then self.anchorPanel:setVisible(self.tool == "anchor") end
    self:onResponsiveLayout()
end

function ISPNCAnimationStudioPropsTab:setContext(host)
    self.host = host
    if self.holdItemPanel and self.holdItemPanel.setContext then
        self.holdItemPanel:setContext(host)
    end
    if self.anchorPanel and self.anchorPanel.setContext then
        self.anchorPanel:setContext(host)
    end
end

function ISPNCAnimationStudioPropsTab:onResponsiveLayout()
    local w = math.max(1, self.width)
    local h = math.max(1, self.height)
    local pad = 8
    local btnH = 26
    local btnW = 136
    Layout.SetBounds(self.holdItemBtn, pad, pad, btnW, btnH)
    Layout.SetBounds(self.anchorBtn, pad + btnW + 6, pad, btnW, btnH)

    local bodyY = pad + btnH + 8
    local bodyH = math.max(1, h - bodyY - pad)
    local bodyW = math.max(1, w - pad * 2)
    for _, panel in ipairs({ self.holdItemPanel, self.anchorPanel }) do
        if panel then
            Layout.SetBounds(panel, pad, bodyY, bodyW, bodyH)
            if panel.onResponsiveLayout then panel:onResponsiveLayout() end
        end
    end
end

function ISPNCAnimationStudioPropsTab:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    return o
end

return ISPNCAnimationStudioPropsTab
