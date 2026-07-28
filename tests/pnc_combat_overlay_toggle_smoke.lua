local FILE =
    "Contents/mods/ProjectHoomans/42.19/media/lua/client/PNC/UI/PNC_Nameplates.lua"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

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

dofile(FILE)

assertEqual(
    PNC.Nameplates.IsCombatDebugEnabled(),
    false,
    "combat overlay defaults off"
)
assertEqual(
    PNC.Nameplates.ToggleCombatDebug(),
    true,
    "combat overlay toggles on"
)
assertEqual(writes[1].key, "showCombatDebug", "combat setting persisted")
assertEqual(writes[1].value, true, "combat enabled persisted")
assertEqual(
    halos[1],
    "UI_PNC_CombatOverlayEnabled",
    "combat enabled feedback"
)
assertEqual(
    PNC.Nameplates.ToggleCombatDebug(),
    false,
    "combat overlay toggles off"
)
assertEqual(writes[2].value, false, "combat disabled persisted")
assertEqual(
    halos[2],
    "UI_PNC_CombatOverlayDisabled",
    "combat disabled feedback"
)

print("pnc_combat_overlay_toggle_smoke: ok")
