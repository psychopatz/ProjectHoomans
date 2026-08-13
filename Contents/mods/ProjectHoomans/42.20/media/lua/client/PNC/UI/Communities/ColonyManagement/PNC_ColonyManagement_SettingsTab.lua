require "ISUI/ISTextEntryBox"
require "PsychopatzCore/UI/PsychopatzUI"

local Shared = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared"
local Tab = {}
local UI = PsychopatzCore.UI

function Tab.Create(window)
    window.factionNameEntry = ISTextEntryBox:new("", 0, 0, 1, 1)
    window.factionNameEntry:initialise()
    window.factionNameEntry:instantiate()
    if window.factionNameEntry.setMaxTextLength then
        window.factionNameEntry:setMaxTextLength(80)
    end
    window:addChild(window.factionNameEntry)
    window.factionRenameButton = UI.CreateButton(window, {
        id = "faction_rename",
        title = Shared.Tr("UI_PNC_ColonySettings_Rename", "RENAME FACTION"),
        target = window,
        onclick = ISPNCColonyManagementWindow.onColonySettingsControl,
        variant = "primary",
    })
end

function Tab.Layout(window, Layout, content)
    local buttonWidth = math.min(180, math.max(120,
        math.floor(content.width * 0.28)))
    local gap = 8
    Layout.SetBounds(window.factionNameEntry, content.x, content.y,
        math.max(80, content.width - buttonWidth - gap), 28)
    Layout.SetBounds(window.factionRenameButton,
        content.x + content.width - buttonWidth, content.y,
        buttonWidth, 28)
end

function Tab.Apply(window, active, Layout)
    window.factionNameEntry:setVisible(active)
    window.factionRenameButton:setVisible(active)
    if active and Layout then
        window:layoutPane(window.detailsPane, window.layout.content.x,
            window.layout.content.y + 40, window.layout.content.width,
            math.max(60, window.layout.content.height - 40))
    end
end

function Tab.Rebuild(window, snapshot)
    local faction = snapshot and snapshot.faction or nil
    local revision = faction and tonumber(faction.revision) or -1
    if window.boundFactionRevision ~= revision then
        window.factionNameEntry:setText(tostring(
            faction and faction.name or ""))
        window.boundFactionRevision = revision
    end
    if not faction then
        window:addDetail(
            Shared.Tr("UI_PNC_ColonySettings_NoFaction", "NO FACTION"),
            Shared.Tr("UI_PNC_ColonySettings_NoFactionHelp",
                "Recruit a companion to establish your faction."))
        window.factionRenameButton:setEnable(false)
        return true
    end
    window.factionRenameButton:setEnable(true)
    window:addDetail(
        Shared.Tr("UI_PNC_ColonySettings_CurrentFaction", "CURRENT FACTION"),
        tostring(faction.name or ""), "accent")
    local result = snapshot.actionResult
    if result and result.action == "faction_rename" then
        window:addDetail(
            result.ok and Shared.Tr("UI_PNC_ColonySettings_Renamed", "SAVED")
                or Shared.Tr("UI_PNC_ColonySettings_RenameFailed", "RENAME FAILED"),
            tostring(result.reason or ""),
            result.ok and "success" or "danger")
    end
    return true
end

function Tab.OnControl(window, button)
    if not button or button.internal ~= "faction_rename" then return false end
    local name = window.factionNameEntry
        and window.factionNameEntry:getText() or ""
    local ok
    local reason
    if PNC.Client and PNC.Client.RenameFaction then
        ok, reason = PNC.Client.RenameFaction(name)
    else
        ok, reason = false, "faction_rename_unavailable"
    end
    if ok and window.refresh then window:refresh() end
    return ok, reason
end

return Tab
