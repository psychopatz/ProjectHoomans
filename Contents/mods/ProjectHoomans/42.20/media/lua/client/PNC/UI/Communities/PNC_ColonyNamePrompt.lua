require "PsychopatzCore/UI/PsychopatzUI"

PNC = PNC or {}
PNC.ColonyNamePrompt = PNC.ColonyNamePrompt or {}

local Prompt = PNC.ColonyNamePrompt
local UI = PsychopatzCore.UI
local Layout = UI.Layout
local Theme = UI.Theme

Prompt.shownRevisions = Prompt.shownRevisions or {}

local function tr(key, fallback)
    local value = getText and getText(key) or nil
    if not value or value == key then return fallback end
    return value
end

local function presentation(mode)
    if mode == "rename" then
        return {
            windowTitle = tr("UI_PNC_ColonyNamePrompt_RenameTitle", "CHANGE NAME"),
            prompt = tr("UI_PNC_ColonyNamePrompt_RenameDescription",
                "Enter a new faction name:"),
            save = tr("UI_PNC_ColonyNamePrompt_RenameSave", "SAVE"),
            cancel = tr("UI_PNC_ColonyNamePrompt_RenameCancel", "CANCEL"),
        }
    end
    return {
        windowTitle = tr("UI_PNC_ColonyNamePrompt_FirstTitle", "NAME YOUR FACTION"),
        prompt = tr("UI_PNC_ColonyNamePrompt_FirstDescription",
            "Your first companion has joined. Name your faction:"),
        save = tr("UI_PNC_ColonyNamePrompt_FirstSave", "Name Faction"),
        cancel = tr("UI_PNC_ColonyNamePrompt_FirstCancel", "Later"),
    }
end

ISPNCColonyNamePrompt = PsychopatzWindow:derive("ISPNCColonyNamePrompt")

function ISPNCColonyNamePrompt:initialise()
    PsychopatzWindow.initialise(self)
end

function ISPNCColonyNamePrompt:createChildren()
    PsychopatzWindow.createChildren(self)
    local copy = presentation(self.mode)
    self.promptText = copy.prompt
    self.nameEntry = UI.CreateTextEntry(self, {
        width = 1,
        height = 1,
        maxTextLength = 80,
    })
    self.saveButton = UI.CreateButton(self, {
        id = "save",
        title = copy.save,
        target = self,
        onclick = ISPNCColonyNamePrompt.onSave,
        variant = "primary",
    })
    self.cancelButton = UI.CreateButton(self, {
        id = "cancel",
        title = copy.cancel,
        target = self,
        onclick = ISPNCColonyNamePrompt.onCancel,
        variant = "quiet",
    })
    self:requestResponsiveLayout(true)
end

function ISPNCColonyNamePrompt:onResponsiveLayout()
    local rect = self:getContentRect({ top = 30, bottom = 12 })
    local entryY = rect.y + Layout.Pixels(38, self.uiScale)
    Layout.SetBounds(
        self.nameEntry,
        rect.x,
        entryY,
        rect.width,
        Layout.Pixels(28, self.uiScale)
    )
    local buttons = Layout.Flow(
        { self.saveButton, self.cancelButton },
        { x = rect.x, y = entryY + Layout.Pixels(40, self.uiScale), width = rect.width },
        { scale = self.uiScale, minWidth = 100 }
    )
    self.buttonsBottom = buttons.bottom
end

function ISPNCColonyNamePrompt:onSave()
    local name = self.nameEntry and self.nameEntry:getText() or ""
    local ok
    local reason
    self.errorText = nil
    if PNC.Client and PNC.Client.RenameFaction then
        ok, reason = PNC.Client.RenameFaction(name)
    else
        ok, reason = false, "faction_rename_unavailable"
    end
    if ok then
        self:close()
    else
        self.errorText = tostring(reason or tr(
            "UI_PNC_ColonyNamePrompt_RenameError",
            "Unable to rename faction"))
    end
end

function ISPNCColonyNamePrompt:onCancel()
    self:close()
end

function ISPNCColonyNamePrompt:onLater()
    self:onCancel()
end

function ISPNCColonyNamePrompt:render()
    PsychopatzWindow.render(self)
    local rect = self:getContentRect({ top = 30, bottom = 12 })
    self:drawText(
        self.promptText or tr("UI_PNC_ColonyNamePrompt_FirstDescription",
            "Your first companion has joined. Name your faction:"),
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
    object.mode = options and options.mode or "first"
    return object
end

function Prompt.Close()
    if Prompt.instance then
        Prompt.instance:close()
        return true
    end
    return false
end

function Prompt.Open(options)
    options = type(options) == "table" and options or {}
    local snapshot = type(options.snapshot) == "table"
        and options.snapshot or {}
    local faction = type(options.faction) == "table"
        and options.faction or snapshot.faction or nil
    if type(faction) ~= "table" then return false end

    local mode = options.mode == "rename" and "rename" or "first"
    local copy = presentation(mode)
    Prompt.Close()
    local window = UI.NewWindow(ISPNCColonyNamePrompt, {
        title = copy.windowTitle,
        mode = mode,
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
    window.nameEntry:setText(tostring(faction.name or tr(
        "UI_PNC_ColonyNamePrompt_DefaultName", "Survivor Group")))
    window:addToUIManager()
    window:setVisible(true)
    window:bringToTop()
    if window.nameEntry.focus then window.nameEntry:focus() end
    Prompt.instance = window
    return true
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
    return Prompt.Open({ snapshot = snapshot, mode = "first" })
end

return Prompt
