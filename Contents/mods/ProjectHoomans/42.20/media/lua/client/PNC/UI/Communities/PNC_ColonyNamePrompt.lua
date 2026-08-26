require "PsychopatzCore/UI/PsychopatzUI"

PNC = PNC or {}
PNC.ColonyNamePrompt = PNC.ColonyNamePrompt or {}

local Prompt = PNC.ColonyNamePrompt
local UI = PsychopatzCore.UI
local Layout = UI.Layout
local Theme = UI.Theme

Prompt.shownRevisions = Prompt.shownRevisions or {}

ISPNCColonyNamePrompt = PsychopatzWindow:derive("ISPNCColonyNamePrompt")

function ISPNCColonyNamePrompt:initialise()
    PsychopatzWindow.initialise(self)
end

function ISPNCColonyNamePrompt:createChildren()
    PsychopatzWindow.createChildren(self)
    self.nameEntry = UI.CreateTextEntry(self, {
        width = 1,
        height = 1,
    })
    self.saveButton = UI.CreateButton(self, {
        id = "save",
        title = "Name Faction",
        target = self,
        onclick = ISPNCColonyNamePrompt.onSave,
        variant = "primary",
    })
    self.laterButton = UI.CreateButton(self, {
        id = "later",
        title = "Later",
        target = self,
        onclick = ISPNCColonyNamePrompt.onLater,
        variant = "quiet",
    })
    self:requestResponsiveLayout(true)
end

function ISPNCColonyNamePrompt:onResponsiveLayout()
    local rect = self:getContentRect({ top = 30, bottom = 12 })
    local entryY = rect.y + 38
    Layout.SetBounds(
        self.nameEntry,
        rect.x,
        entryY,
        rect.width,
        Layout.Pixels(28, self.uiScale)
    )
    local buttons = Layout.Flow(
        { self.saveButton, self.laterButton },
        { x = rect.x, y = entryY + Layout.Pixels(40, self.uiScale), width = rect.width },
        { scale = self.uiScale, minWidth = 100 }
    )
    self.buttonsBottom = buttons.bottom
end

function ISPNCColonyNamePrompt:onSave()
    local name = self.nameEntry and self.nameEntry:getText() or ""
    local ok
    local reason
    if PNC.Client and PNC.Client.RenameFaction then
        ok, reason = PNC.Client.RenameFaction(name)
    else
        ok, reason = false, "rename_unavailable"
    end
    if ok then
        self:close()
    else
        self.errorText = tostring(reason or "Unable to rename faction")
    end
end

function ISPNCColonyNamePrompt:onLater()
    self:close()
end

function ISPNCColonyNamePrompt:render()
    PsychopatzWindow.render(self)
    local rect = self:getContentRect({ top = 30, bottom = 12 })
    self:drawText(
        "Your first companion has joined. Name your faction:",
        rect.x,
        rect.y + 8,
        Theme.colors.text.r,
        Theme.colors.text.g,
        Theme.colors.text.b,
        Theme.colors.text.a,
        UIFont.Small
    )
    if self.errorText then
        self:drawText(
            self.errorText,
            rect.x,
            (self.buttonsBottom or rect.y) + 6,
            Theme.colors.danger.r,
            Theme.colors.danger.g,
            Theme.colors.danger.b,
            Theme.colors.danger.a,
            UIFont.Small
        )
    end
end

function ISPNCColonyNamePrompt:close()
    self:setVisible(false)
    self:removeFromUIManager()
    Prompt.instance = nil
end

function ISPNCColonyNamePrompt:new(x, y, width, height, options)
    local object = PsychopatzWindow:new(x, y, width, height, options)
    setmetatable(object, self)
    self.__index = self
    return object
end

function Prompt.OpenIfNeeded(snapshot)
    local faction = snapshot and snapshot.faction or nil
    if not faction or faction.renamePending ~= true
        or #(snapshot.people or {}) < 1
    then
        return false
    end
    local revision = tonumber(faction.revision) or 0
    if Prompt.shownRevisions[faction.id] == revision then return false end
    Prompt.shownRevisions[faction.id] = revision
    if Prompt.instance then Prompt.instance:close() end
    local window = UI.NewWindow(ISPNCColonyNamePrompt, {
        title = "NAME YOUR FACTION",
        resizable = false,
        persistGeometry = false,
        responsiveSpec = {
            width = 430,
            height = 170,
            minWidth = 430,
            minHeight = 170,
            maxWidth = 430,
            maxHeight = 170,
            anchor = "center",
        },
    })
    window:initialise()
    window:instantiate()
    window.nameEntry:setText(tostring(faction.name or "Survivor Group"))
    window:addToUIManager()
    window:setVisible(true)
    window:bringToTop()
    if window.nameEntry.focus then window.nameEntry:focus() end
    Prompt.instance = window
    return true
end

return Prompt
