local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "client", "")

local function newMenu()
    local menu = { options = {}, submenus = {} }
    function menu:addOption(label, target, callback, ...)
        local option = {
            name = label,
            target = target,
            callback = callback,
            params = { ... },
        }
        self.options[#self.options + 1] = option
        return option
    end
    function menu:addSubMenu(option, submenu)
        option.submenu = submenu
        self.submenus[#self.submenus + 1] = submenu
    end
    return menu
end

local sent
PNC = {
    Client = {
        SendDebug = function(action, payload)
            sent = { action = action, payload = payload }
            return true
        end,
    },
}
getText = function(key) return key end
ISContextMenu = { getNew = function() return newMenu() end }

T.load(ROOT .. "PNC/UI/Context/PNC_DebugSpawnMenu.lua")

local context = newMenu()
local square = {
    getX = function() return 10 end,
    getY = function() return 20 end,
    getZ = function() return 0 end,
}
local root = PNC.DebugSpawnMenu.Add(context, square)
T.equal(context.options[1].name, "PNC Spawn", "spawn root")
T.equal(#root.options, 3, "faction submenu count")
T.equal(root.options[1].name, "Companion", "companion submenu")
T.equal(root.options[2].name, "Neutral", "neutral submenu")
T.equal(root.options[3].name, "Hostile", "hostile submenu")

local function choose(factionIndex, equipmentIndex)
    local option = root.options[factionIndex].submenu.options[equipmentIndex]
    option.callback(option.target, table.unpack(option.params))
end

for factionIndex = 1, 3 do
    T.equal(#root.options[factionIndex].submenu.options, 4,
        "equipment choices for faction " .. tostring(factionIndex))
end

choose(1, 2)
T.equal(sent.action, "spawn", "companion debug action")
T.equal(sent.payload.faction, "colonist", "companion faction payload")
T.equal(sent.payload.equipmentSpawnMode, "melee", "companion melee override")

choose(2, 3)
T.equal(sent.payload.faction, "neutral", "neutral faction payload")
T.equal(sent.payload.equipmentSpawnMode, "ranged", "neutral ranged override")

choose(3, 4)
T.equal(sent.payload.faction, "hostile", "hostile faction payload")
T.equal(sent.payload.equipmentSpawnMode, "both", "hostile both override")

choose(2, 1)
T.equal(sent.payload.equipmentSpawnMode, nil, "sandbox chance mode has no override")
T.equal(sent.payload.x, 10, "spawn square x")
T.equal(sent.payload.y, 20, "spawn square y")
T.finish("pnc_debug_spawn_menu_smoke")

T.finish("pnc_debug_spawn_menu_smoke")
