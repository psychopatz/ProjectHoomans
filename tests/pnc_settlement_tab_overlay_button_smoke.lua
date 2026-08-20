local function equal(actual, expected, message)
    if actual ~= expected then
        error((message or "assertion failed") .. ": expected "
            .. tostring(expected) .. ", got " .. tostring(actual))
    end
end

package.path = table.concat({
    "Contents/mods/ProjectHoomans/42.20/media/lua/client/?.lua",
    package.path,
}, ";")

getText = function(key) return key end

local styled
PsychopatzCore = { UI = {
    SetButtonVariant = function(button, variant)
        styled = { button = button, variant = variant }
    end,
} }
package.preload["PsychopatzCore/UI/PsychopatzUI"] = function()
    return PsychopatzCore.UI
end
package.preload[
    "PNC/UI/Communities/ColonyManagement/SettlementManagement/PNC_SettlementManagement_Actions"
] = function() return {
    Handle = function() return true end,
    NextAnchorRole = function() return "work.craft" end,
    AnchorAssignLabel = function() return "ASSIGN CRAFT TABLE" end,
    AreaRole = function() return "workshop.room" end,
} end
local browserRebuilt = false
local selectedFacility
package.preload[
    "PNC/UI/Communities/ColonyManagement/SettlementManagement/PNC_SettlementManagement_FacilityBrowser"
] = function() return {
    Rebuild = function() browserRebuilt = true end,
    GetSelected = function() return selectedFacility end,
} end
package.preload[
    "PNC/UI/Communities/ColonyManagement/PNC_SettlementLayoutOverlay"
] = function()
    return {
        SetSettlement = function() end,
        IsEnabled = function() return true end,
    }
end

PNC = { FacilityDefinitions = { Get = function() end } }
local BaseTab = require(
    "PNC/UI/Communities/ColonyManagement/SettlementManagement/PNC_SettlementManagement_Tab"
)
local title
local overlayButton = { setTitle = function(_, value) title = value end }
local window = {
    baseControls = { overlay = overlayButton },
    baseContextControls = {},
}

equal(BaseTab.Rebuild(window, { settlement = { facilities = {} } }), true,
    "base tab rebuild")
equal(title, "HIDE BASE LAYOUT", "enabled overlay title")
equal(styled.button, overlayButton, "overlay button styling target")
equal(styled.variant, "warning", "enabled overlay style")
equal(browserRebuilt, true, "facility browser rebuild")

local function control(id)
    return { internal = id, setVisible = function(self, visible)
        self.visible = visible
    end, setTitle = function(self, value) self.title = value end }
end
local upgrade, cancel, destroy = control("facility_upgrade"),
    control("facility_cancel_construction"), control("facility_destroy")
window.tab = "base"
window.baseContextControls = { upgrade, cancel, destroy }
selectedFacility = { constructionState = "UNDER_CONSTRUCTION",
    constructionWorkOrderId = "work:1" }
BaseTab.UpdateContextControls(window)
equal(upgrade.visible, false, "upgrade hidden before building completes")
equal(cancel.visible, true, "cancel construction is available before completion")
equal(destroy.visible, false, "deconstruction is hidden before completion")
selectedFacility.constructionState = "BUILT"
BaseTab.UpdateContextControls(window)
equal(upgrade.visible, true, "upgrade unlocks after construction")

print("pnc_settlement_tab_overlay_button_smoke: ok")
