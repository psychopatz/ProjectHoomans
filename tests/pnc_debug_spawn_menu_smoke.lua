local ROOT = "Contents/mods/ProjectHoomans/42.20/media/lua/client/"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

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

dofile(ROOT .. "PNC/UI/Context/PNC_DebugSpawnMenu.lua")

local context = newMenu()
local square = {
    getX = function() return 10 end,
    getY = function() return 20 end,
    getZ = function() return 0 end,
}
local root = PNC.DebugSpawnMenu.Add(context, square)
assertEqual(context.options[1].name, "PNC Spawn", "spawn root")
assertEqual(#root.options, 3, "faction submenu count")
assertEqual(root.options[1].name, "Companion", "companion submenu")
assertEqual(root.options[2].name, "Neutral", "neutral submenu")
assertEqual(root.options[3].name, "Hostile", "hostile submenu")

local function choose(factionIndex, equipmentIndex)
    local option = root.options[factionIndex].submenu.options[equipmentIndex]
    option.callback(option.target, table.unpack(option.params))
end

for factionIndex = 1, 3 do
    assertEqual(#root.options[factionIndex].submenu.options, 4,
        "equipment choices for faction " .. tostring(factionIndex))
end

choose(1, 2)
assertEqual(sent.action, "spawn", "companion debug action")
assertEqual(sent.payload.faction, "colonist", "companion faction payload")
assertEqual(sent.payload.equipmentSpawnMode, "melee", "companion melee override")

choose(2, 3)
assertEqual(sent.payload.faction, "neutral", "neutral faction payload")
assertEqual(sent.payload.equipmentSpawnMode, "ranged", "neutral ranged override")

choose(3, 4)
assertEqual(sent.payload.faction, "hostile", "hostile faction payload")
assertEqual(sent.payload.equipmentSpawnMode, "both", "hostile both override")

choose(2, 1)
assertEqual(sent.payload.equipmentSpawnMode, nil, "sandbox chance mode has no override")
assertEqual(sent.payload.x, 10, "spawn square x")
assertEqual(sent.payload.y, 20, "spawn square y")

print("pnc_debug_spawn_menu_smoke: ok")
