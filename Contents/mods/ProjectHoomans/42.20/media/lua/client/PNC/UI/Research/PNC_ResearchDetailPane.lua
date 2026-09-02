require "ISUI/ISPanel"
require "PsychopatzCore/UI/PsychopatzUI"

local DetailPane = ISPanel:derive("ISPNCResearchDetailPane")
local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout

local function tr(key, fallback)
    local value = getText and getText(key) or nil
    return value and value ~= "" and value ~= key and value or fallback
end

local function color(name)
    return Theme.colors[name] or Theme.colors.text
end

local function sourceLabel(source)
    if source == "blueprint" then
        return tr("UI_PNC_Research_Source_Blueprint", "BLUEPRINT")
    end
    if source == "book" then
        return tr("UI_PNC_Research_Source_Book", "BOOK")
    end
    return tr("UI_PNC_Research_Source_Technology", "TECHNOLOGY")
end

local function status(item)
    if item.status == "known" then
        return tr("UI_PNC_Research_Status_Learned", "LEARNED"), "success"
    end
    if item.status == "active" then
        return tr("UI_PNC_Research_Status_Active", "ACTIVE"), "accent"
    end
    if item.status == "locked" then
        return tr("UI_PNC_Research_Status_Locked", "LOCKED"), "warning"
    end
    if item.status == "available" then
        return tr("UI_PNC_Research_Status_Available", "AVAILABLE"), "accent"
    end
    return tr("UI_PNC_Research_Status_Unavailable", "UNAVAILABLE"), "warning"
end

function DetailPane:initialise()
    ISPanel.initialise(self)
    self.backgroundColor = Theme.Color("surface")
    self.borderColor = Theme.Color("border")
    self.psychopatzThemeBackgroundName = "surface"
    self.psychopatzThemeBorderName = "border"
end

function DetailPane:createChildren()
    self.actionButton = UI.CreateButton(self, {
        id = "research_item_action",
        title = tr("UI_PNC_Research_Action_Research", "BEGIN RESEARCH"),
        target = self,
        onclick = function(target, button)
            if target.owner and target.owner.onResearchControl then
                return target.owner:onResearchControl(button)
            end
            return false
        end,
        variant = "primary",
    })
end

function DetailPane:setOwner(owner)
    self.owner = owner
end

function DetailPane:setItem(item)
    self.item = item
    local button = self.actionButton
    if not button then return end
    local title = tr("UI_PNC_Research_Action_Research", "BEGIN RESEARCH")
    local variant = "primary"
    local enabled = false
    if item then
        if item.status == "known" then
            title = tr("UI_PNC_Research_Action_Learned", "LEARNED")
            variant = "success"
        elseif item.status == "active" then
            title = tr("UI_PNC_Research_Action_Queued", "ALREADY QUEUED")
            variant = "quiet"
        elseif item.status == "locked" then
            title = tr("UI_PNC_Research_Action_Locked", "PREREQUISITE REQUIRED")
            variant = "warning"
        elseif item.status == "unavailable" then
            title = tr("UI_PNC_Research_Action_Unavailable", "RESEARCH TABLE REQUIRED")
            variant = "warning"
        else
            enabled = item.researchable == true
        end
    else
        title = tr("UI_PNC_Research_Action_Select", "SELECT RESEARCH")
        variant = "quiet"
    end
    button:setTitle(title)
    button:setEnable(enabled)
    UI.SetButtonVariant(button, variant)
end

function DetailPane:layoutContent()
    if not self.actionButton then return end
    local scale = self.uiScale or Layout.Scale()
    local padding = Layout.Pixels(12, scale)
    local height = Layout.Pixels(28, scale)
    Layout.SetBounds(self.actionButton, padding,
        math.max(padding, self:getHeight() - height - padding),
        math.max(1, self:getWidth() - padding * 2), height)
end

function DetailPane:render()
    ISPanel.render(self)
    local item = self.item
    local scale = self.uiScale or Layout.Scale()
    local font = Theme.Font(scale)
    local padding = Layout.Pixels(12, scale)
    local width = self:getWidth() - padding * 2
    if not item then
        UI.DrawSectionTitle(self,
            tr("UI_PNC_Research_DetailTitle", "RESEARCH DETAILS"),
            padding, padding, width)
        self:drawText(Layout.Ellipsize(
            tr("UI_PNC_Research_SelectHint", "Select a research item to inspect its requirements."),
            font, width), padding, padding + 30,
            Theme.colors.textMuted.r, Theme.colors.textMuted.g,
            Theme.colors.textMuted.b, Theme.colors.textMuted.a, font)
        return
    end
    local statusText, statusColor = status(item)
    UI.DrawSectionTitle(self, item.name, padding, padding, width, statusText)
    local accent = color(statusColor)
    self:drawText(Layout.Ellipsize(item.description, font, width),
        padding, padding + 30, Theme.colors.textMuted.r,
        Theme.colors.textMuted.g, Theme.colors.textMuted.b,
        Theme.colors.textMuted.a, font)
    local source = sourceLabel(item.source)
    if item.quantity and item.source ~= "technology" then
        source = source .. "  |  x" .. tostring(item.quantity)
    end
    self:drawText(source, padding, padding + 56, accent.r, accent.g,
        accent.b, accent.a, font)
    local line = padding + 82
    if item.progress ~= nil then
        self:drawText(tr("UI_PNC_Research_Progress", "PROGRESS") .. ": "
            .. tostring(item.progress) .. "%", padding, line,
            Theme.colors.text.r, Theme.colors.text.g,
            Theme.colors.text.b, Theme.colors.text.a, font)
        line = line + 25
    elseif item.requiredWork and item.requiredWork > 0 then
        self:drawText(tr("UI_PNC_Research_Work", "WORK REQUIRED") .. ": "
            .. tostring(item.requiredWork), padding, line,
            Theme.colors.text.r, Theme.colors.text.g,
            Theme.colors.text.b, Theme.colors.text.a, font)
        line = line + 25
    end
    if item.prerequisite then
        local prerequisite = item.prerequisiteKnown
            and tr("UI_PNC_Research_PrerequisiteMet", "Prerequisite met")
            or tr("UI_PNC_Research_Prerequisite", "Requires") .. ": "
                .. tostring(item.prerequisite)
        self:drawText(Layout.Ellipsize(prerequisite, font, width),
            padding, line, Theme.colors.textMuted.r,
            Theme.colors.textMuted.g, Theme.colors.textMuted.b,
            Theme.colors.textMuted.a, font)
        line = line + 25
    end
    if item.disabledReason then
        local reason = tr(item.disabledReason,
            tr("UI_PNC_Research_Disabled_Generic",
                "This research cannot be started yet."))
        self:drawText(Layout.Ellipsize(reason, font, width), padding, line,
            Theme.colors.warning.r, Theme.colors.warning.g,
            Theme.colors.warning.b, Theme.colors.warning.a, font)
    end
end

function DetailPane:new(x, y, width, height)
    local object = ISPanel:new(x, y, width, height)
    setmetatable(object, self)
    self.__index = self
    return object
end

return DetailPane
