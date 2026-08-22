local T = require "tests/support/test"

local FILE =
    T.path("ProjectHoomans", "client", "PNC/UI/PNC_Nameplates.lua")

local writes = {}
local halos = {}

ISUIElement = {}
function ISUIElement:derive()
    local class = {}
    class.__index = class
    setmetatable(class, { __index = self })
    return class
end
function ISUIElement:initialise() end
function ISUIElement:new()
    return setmetatable({}, { __index = self })
end

package.preload["ISUI/ISUIElement"] = function() return ISUIElement end
package.preload["PsychopatzCore/Settings/PsychopatzSettings"] = function()
    PsychopatzCore = PsychopatzCore or {}
    PsychopatzCore.Settings = {
        Open = function(_, specification)
            local values = {}
            for key, value in pairs(specification.defaults or {}) do
                values[key] = value
            end
            return {
                values = values,
                Set = function(_, key, value)
                    values[key] = value
                    writes[#writes + 1] = { key = key, value = value }
                end,
            }
        end,
    }
    return PsychopatzCore.Settings
end

local dependencies = {
    "PNC/UI/Nameplates/PNC_NameplatePresentation",
    "PNC/UI/Nameplates/PNC_NameplateDebug",
    "PNC/UI/Nameplates/PNC_NameplateBodies",
    "PNC/UI/Nameplates/PNC_NameplateEntries",
    "PNC/UI/Nameplates/PNC_NameplateRenderer",
}
for _, dependency in ipairs(dependencies) do
    package.preload[dependency] = function() return true end
end

PNC = {
    NameplateDebug = {
        DescribeSnapshot = function() return "" end,
    },
    NameplateEntries = {
        Refresh = function() end,
    },
    NameplateRenderer = {
        Render = function() end,
    },
}
Events = {
    OnCreatePlayer = { Add = function() end },
    OnGameStart = { Add = function() end },
    OnPreUIDraw = { Add = function() end },
    OnResetLua = { Add = function() end },
}
getSpecificPlayer = function() return {} end
getText = function(key) return key end
HaloTextHelper = {
    addText = function(_, text) halos[#halos + 1] = text end,
}

T.load(FILE)

T.equal(
    PNC.Nameplates.IsCombatDebugEnabled(),
    false,
    "combat overlay defaults off"
)
T.equal(
    PNC.Nameplates.ToggleCombatDebug(),
    true,
    "combat overlay toggles on"
)
T.equal(writes[1].key, "showCombatDebug", "combat setting persisted")
T.equal(writes[1].value, true, "combat enabled persisted")
T.equal(
    halos[1],
    "UI_PNC_CombatOverlayEnabled",
    "combat enabled feedback"
)
T.equal(
    PNC.Nameplates.ToggleCombatDebug(),
    false,
    "combat overlay toggles off"
)
T.equal(writes[2].value, false, "combat disabled persisted")
T.equal(
    halos[2],
    "UI_PNC_CombatOverlayDisabled",
    "combat disabled feedback"
)
T.equal(
    PNC.Nameplates.IsAnimationDebugEnabled(),
    false,
    "animation overlay defaults off"
)
T.equal(
    PNC.Nameplates.ToggleAnimationDebug(),
    true,
    "animation overlay toggles on"
)
T.equal(
    writes[3].key,
    "showAnimationDebug",
    "animation setting persisted"
)
T.equal(writes[3].value, true, "animation enabled persisted")
T.equal(
    halos[3],
    "PNC animation tracks enabled",
    "animation enabled feedback"
)
T.equal(
    PNC.Nameplates.ToggleAnimationDebug(),
    false,
    "animation overlay toggles off"
)
T.equal(writes[4].value, false, "animation disabled persisted")
T.equal(
    PNC.Nameplates.IsAnimationSceneDebugEnabled(),
    false,
    "scene overlay defaults off"
)
T.equal(
    PNC.Nameplates.ToggleAnimationSceneDebug(),
    true,
    "scene overlay toggles on"
)
T.equal(
    writes[5].key,
    "showAnimationSceneDebug",
    "scene overlay setting persisted"
)
T.equal(
    halos[5],
    "PNC scene overlay enabled",
    "scene overlay enabled feedback"
)
T.equal(
    PNC.Nameplates.ToggleAnimationSceneDebug(),
    false,
    "scene overlay toggles off"
)
T.equal(writes[6].value, false,
    "scene overlay disabled persisted")

T.equal(
    PNC.Nameplates.IsFactionDebugEnabled(),
    false,
    "faction world overlay defaults off"
)
T.equal(
    PNC.Nameplates.ToggleFactionDebug(),
    true,
    "faction world overlay toggles on"
)
T.equal(writes[7].key, "showFactionDebug",
    "faction overlay setting persisted")
T.equal(halos[7], "UI_PNC_FactionOverlayEnabled",
    "faction overlay enabled feedback")
T.equal(
    PNC.Nameplates.ToggleFactionDebug(),
    false,
    "faction world overlay toggles off"
)
T.equal(writes[8].value, false,
    "faction overlay disabled persisted")

T.equal(
    #PNC.Nameplates.GetOverlayDefinitions(),
    7,
    "all overlay types share one registry"
)
T.equal(
    PNC.Nameplates.GetOverlaySummary(),
    "ON: none",
    "central overlay summary reports inactive state"
)
T.equal(
    PNC.Nameplates.ToggleOverlay("path"),
    true,
    "central dispatcher toggles path overlay"
)
T.equal(
    PNC.Nameplates.IsOverlayEnabled("path"),
    true,
    "central registry reports path overlay state"
)
T.equal(
    PNC.Nameplates.GetOverlaySummary(),
    "ON: Paths",
    "central overlay summary lists active type"
)
T.finish("pnc_combat_overlay_toggle_smoke")

T.finish("pnc_combat_overlay_toggle_smoke")
