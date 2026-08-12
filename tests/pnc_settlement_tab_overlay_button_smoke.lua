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
] = function() return { Handle = function() return true end } end
local browserRebuilt = false
package.preload[
    "PNC/UI/Communities/ColonyManagement/SettlementManagement/PNC_SettlementManagement_FacilityBrowser"
] = function() return {
    Rebuild = function() browserRebuilt = true end,
    GetSelected = function() return nil end,
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

print("pnc_settlement_tab_overlay_button_smoke: ok")
