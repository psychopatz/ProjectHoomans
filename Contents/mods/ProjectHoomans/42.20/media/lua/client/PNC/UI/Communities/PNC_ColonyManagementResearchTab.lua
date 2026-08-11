local ResearchTab = {}
local UPGRADE_TITLE_KEY = "UI_PNC_Research_DebugUpgradeStorage"

function ResearchTab.Create(window, UI, tr)
    local upgradeTitle = tr(UPGRADE_TITLE_KEY, "Debug: Upgrade Storage")
    window.researchUpgrade = UI.CreateButton(window, {
        id = "storage_capacity",
        title = upgradeTitle,
        target = window,
        onclick = ISPNCColonyManagementWindow.onResearchUpgrade,
        variant = "warning",
    })
end

function ResearchTab.Layout(window, Layout, content)
    Layout.SetBounds(window.researchUpgrade, content.x, content.y,
        math.min(260, content.width), 28)
end

function ResearchTab.ApplyVisibility(window, active, Layout)
    window.researchUpgrade:setVisible(active
        and window.snapshot and window.snapshot.storage
        and window.snapshot.storage.debugAuthorized == true)
    if active and Layout then
        window:layoutPane(window.detailsPane, window.layout.content.x,
            window.layout.content.y + 38, window.layout.content.width,
            math.max(60, window.layout.content.height - 38))
    end
end

function ResearchTab.OnUpgrade(window, button)
    PNC.Client.RequestColonyAction("research_debug_upgrade", {
        researchId = button and button.internal or "storage_capacity",
        storageId = window.snapshot and window.snapshot.storage
            and window.snapshot.storage.storageId,
    })
end

function ResearchTab.Rebuild(window, snapshot, tr)
    if window.tab ~= "research" then return false end
    local entry = snapshot.research and snapshot.research.entries
        and snapshot.research.entries[1] or nil
    if not entry then
        window:addDetail("NO RESEARCH AVAILABLE",
            "Research definitions are unavailable.")
        return true
    end
    window:addDetail(tr(entry.labelKey, "Storage Capacity"),
        "Current Tier " .. tostring(entry.currentLevel), "accent")
    window:addDetail("CURRENT CAPACITY", tostring(entry.currentValue))
    if entry.nextLevel then
        window:addDetail("NEXT TIER", "Tier " .. tostring(entry.nextLevel))
        window:addDetail("NEW CAPACITY", tostring(entry.nextValue))
        window:addDetail("INCREASE", "+" .. tostring(entry.increase), "success")
    else
        window:addDetail("MAXIMUM TIER",
            "No further debug upgrades are available.", "success")
    end
    return true
end

return ResearchTab
