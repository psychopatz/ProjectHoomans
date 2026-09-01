PNC = PNC or {}
PNC.CommandHub = PNC.CommandHub or {}

local Presentation = {}
local Registry = require "PNC/UI/CommandHub/PNC_CommandHub_WorkRegistry"
local UI = PsychopatzCore.UI
local Layout = UI.Layout
local Theme = UI.Theme

function Presentation.Translate(key, fallback)
    if not key or key == "" then return fallback end
    local value = getText and getText(key) or nil
    return value and value ~= "" and value ~= key and value or fallback
end

function Presentation.ClientState()
    return PNC.Network and PNC.Network.ClientState or {}
end

function Presentation.ReadSnapshot()
    local client = PNC.ColonyManagementClient
    if client and client.ReadSnapshot then return client.ReadSnapshot() end
    local current = Presentation.ClientState()
    return {
        snapshot = current.colonyManagement or {},
        revision = tonumber(current.colonyManagementRevision) or 0,
        receivedAt = current.lastColonyManagementReceiveAt,
    }
end

function Presentation.TitleFor(definition)
    return Presentation.Translate(definition and definition.titleKey,
        definition and definition.titleFallback or "WORK")
end

function Presentation.PersonName(person)
    return tostring(person and (person.name or person.id) or "COLONIST")
end

function Presentation.IsAllowed(person, job)
    local allowed = person and person.allowedJobs
    return not allowed or allowed[job] ~= false
end

local function activityFor(person)
    if person and person.actionInformation then
        local information = person.actionInformation
        return tostring(information.label or information.activity or "")
    end
    return tostring(person and (person.activity or person.job) or "IDLE")
end

local function enabledCount(person)
    local count = 0
    for _, definition in ipairs(Registry.All()) do
        if Presentation.IsAllowed(person, definition.id) then count = count + 1 end
    end
    return count
end

function Presentation.DrawPersonRow(list, y, entry, alternate)
    local person = entry.item or {}
    local selected = list.selected == entry.index
    UI.DrawListSelection(list, y, list.itemheight, selected, alternate)
    list:drawText(Layout.Ellipsize(Presentation.PersonName(person), UIFont.Small,
        list:getWidth() - 18), 10, y + 7,
        Theme.colors.text.r, Theme.colors.text.g, Theme.colors.text.b,
        Theme.colors.text.a, UIFont.Small)
    list:drawText(Layout.Ellipsize(activityFor(person), UIFont.Small,
        list:getWidth() - 18), 10, y + 28,
        Theme.colors.textMuted.r, Theme.colors.textMuted.g,
        Theme.colors.textMuted.b, Theme.colors.textMuted.a, UIFont.Small)
    list:drawText(tostring(enabledCount(person)) .. "/"
        .. tostring(#Registry.All()) .. " "
        .. Presentation.Translate("UI_PNC_Work_AllowedShort", "ALLOWED"),
        10, y + 46, Theme.colors.accent.r, Theme.colors.accent.g,
        Theme.colors.accent.b, Theme.colors.accent.a, UIFont.Small)
    return y + list.itemheight
end

return Presentation
