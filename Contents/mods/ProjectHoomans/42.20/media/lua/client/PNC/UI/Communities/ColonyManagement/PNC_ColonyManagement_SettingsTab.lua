local Shared = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared"
local Tab = {}

function Tab.Create() end

function Tab.Layout() end

function Tab.Apply(window, active, Layout)
    if active and Layout then
        window:layoutPane(window.detailsPane, window.layout.content.x,
            window.layout.content.y, window.layout.content.width,
            math.max(60, window.layout.content.height))
    end
end

function Tab.Rebuild(window, snapshot)
    local faction = snapshot and snapshot.faction or nil
    if not faction then
        window:addDetail(
            Shared.Tr("UI_PNC_ColonySettings_NoFaction", "NO FACTION"),
            Shared.Tr("UI_PNC_ColonySettings_NoFactionHelp",
                "Recruit a companion to establish your faction."))
        return true
    end
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

function Tab.OnControl() return false end

return Tab
