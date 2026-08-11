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
ISComboBox = {}
package.preload["ISUI/ISComboBox"] = function() return ISComboBox end

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
    "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Components"
] = function() return { SetRows = function() end } end
package.preload[
    "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Presentation"
] = function() return { BuildSettlement = function() return {} end } end
package.preload[
    "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared"
] = function() return { SettlementReason = function(value) return value end } end
package.preload["PsychopatzCore/World/PC_GridRegion"] = function()
    return {}
end
package.preload[
    "PsychopatzCore/UI/World/PsychopatzGridRegionSelector"
] = function() return {} end
package.preload[
    "PNC/UI/Communities/ColonyManagement/PNC_FacilityBuildModal"
] = function() return {} end
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
    "PNC/UI/Communities/ColonyManagement/PNC_SettlementManagementTab"
)
local title
local overlayButton = { setTitle = function(_, value) title = value end }
local combo = {
    selected = 1,
    getOptionData = function() return nil end,
    clear = function() end,
    addOptionWithData = function() end,
}
local window = {
    baseFacilityCombo = combo,
    baseControls = { overlay = overlayButton },
    details = {},
}

equal(BaseTab.Rebuild(window, { settlement = { facilities = {} } }), true,
    "base tab rebuild")
equal(title, "HIDE BASE LAYOUT", "enabled overlay title")
equal(styled.button, overlayButton, "overlay button styling target")
equal(styled.variant, "warning", "enabled overlay style")

print("pnc_settlement_tab_overlay_button_smoke: ok")
