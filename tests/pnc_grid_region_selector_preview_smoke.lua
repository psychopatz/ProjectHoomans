local T = require "tests/support/test"

T.addPackagePaths({
    { "PsychopatzCore", "client" },
    { "PsychopatzCore", "common" },
})

ISPanelJoypad = {
    derive = function(base)
        local derived = {}
        setmetatable(derived, { __index = base })
        return derived
    end,
    new = function(_, x, y, width, height)
        return { x = x, y = y, width = width, height = height }
    end,
    prerender = function() end,
}
package.preload["ISUI/ISPanelJoypad"] = function()
    return ISPanelJoypad
end

ISUIElement = {
    new = function(_, x, y, width, height)
        return { x = x, y = y, width = width, height = height }
    end,
}
package.preload["ISUI/ISUIElement"] = function()
    return ISUIElement
end

PsychopatzCore = {
    UI = {
        Theme = { colors = {
            window = { a = 1, r = 0, g = 0, b = 0 },
            borderStrong = { a = 1, r = 1, g = 1, b = 1 },
            accent = { r = 1, g = 1, b = 1 },
            text = { r = 1, g = 1, b = 1 },
            textMuted = { r = 1, g = 1, b = 1 },
            danger = { r = 1, g = 0, b = 0 },
            success = { r = 0, g = 1, b = 0 },
        } },
        Layout = { Ellipsize = function(value) return value end },
    },
}

package.preload["PsychopatzCore/UI/Components/PsychopatzUIControls"] =
    function() return {} end
package.preload["PsychopatzCore/World/PC_GridRegion"] = function()
    return {
        new = function() return { levels = {} } end,
        normalize = function(region)
            return region or { levels = {} }
        end,
    }
end
package.preload["PsychopatzCore/World/PC_GridRegionEditor"] = function()
    return {}
end
package.preload["PsychopatzCore/World/PsychopatzSquareRules"] = function()
    return {}
end

getCore = function()
    return { getScreenWidth = function() return 1280 end }
end
getSpecificPlayer = function()
    return { getZ = function() return 0 end }
end
getCell = function()
    return { getGridSquare = function() return {} end }
end

local Selector = T.load("PsychopatzCore", "client",
    "PsychopatzCore/UI/World/PsychopatzGridRegionSelector.lua")
local region = { levels = { [0] = { rows = { [4] = { 0, 2 } } } } }
local selector = Selector:new({
    player = getSpecificPlayer(0),
    tileValidator = function(x)
        return x <= 1, x <= 1 and nil or "OUTSIDE_BASE"
    end,
})

local invalid, count, reason = selector:collectInvalidTiles(region)
T.equal(count, 1, "selector did not count invalid preview tiles")
T.equal(reason, "OUTSIDE_BASE", "selector lost invalid tile reason")
T.equal(invalid.levels[0].rows[4][1], 2,
    "selector invalid preview started at the wrong tile")
T.equal(invalid.levels[0].rows[4][2], 2,
    "selector invalid preview ended at the wrong tile")

Selector.instance = selector
T.truthy(Selector.IsWorldInputOwned(),
    "selector did not claim world input while open")
T.equal(Selector.WorldInputOwner(), "PsychopatzCore.GridRegionSelector",
    "selector exposed the wrong world-input owner")
Selector.instance = nil

T.finish("pnc_grid_region_selector_preview_smoke")
