local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error((message or "assertEqual failed") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
    end
end

local function findOption(menu, name)
    local i
    for i = 1, #menu.options do
        if menu.options[i].name == name then
            return menu.options[i]
        end
    end
    return nil
end

local function newMenu()
    local menu = { options = {}, submenus = {} }
    function menu:addOption(label, target, callback)
        local option = { name = label, target = target, callback = callback }
        self.options[#self.options + 1] = option
        return option
    end
    function menu:addSubMenu(option, submenu)
        option.submenu = submenu
        self.submenus[#self.submenus + 1] = submenu
    end
    return menu
end

local CLIENT_ROOT = "Contents/mods/ProjectHoomans/42.19/media/lua/client/"
local debugAuthorized = false
local registeredProvider

PNC = {
    Const = {
        ORDER_FOLLOW = "follow",
        ORDER_GUARD = "guard",
        ORDER_PATROL = "patrol",
        ORDER_ROAM = "roam",
        ORDER_HOSTILE_HUNT = "hostile_hunt",
        ROAM_MODE_AREA = "area",
        ROAM_DEFAULT_RADIUS = 10,
        ROAM_TARGET_RADIUS = 2,
    },
    Client = {
        CanUseDebug = function() return debugAuthorized end,
        SendDebug = function() end,
    },
    ContextHub = {
        RegisterProvider = function(provider)
            registeredProvider = provider
        end,
    },
    Network = {
        ClientState = {
            snapshots = {
                npc_one = { healthState = "incapacitated", canRevive = true },
            },
        },
    },
}

-- Simulate a missing/stale translation table: PZ returns the key verbatim.
getText = function(key) return key end
ISContextMenu = { getNew = function() return newMenu() end }

dofile(CLIENT_ROOT .. "PNC/UI/Context/Providers/PNC_ContextProvider_Debug.lua")

assertEqual(registeredProvider.id, "debug", "debug provider registered")
assertEqual(registeredProvider.isEnabled(), false, "provider hidden without debug authorization")
debugAuthorized = true
assertEqual(registeredProvider.isEnabled(), true, "provider enabled with debug authorization")

local menu = newMenu()
registeredProvider.addOptions(menu, { id = "npc_one" }, {}, {})

assertEqual(#menu.options, 1, "debug commands are grouped under one NPC submenu entry")
assertEqual(menu.options[1].name, "Debug", "debug submenu uses a readable fallback label")
local debugMenu = menu.options[1].submenu
assertEqual(debugMenu ~= nil, true, "debug submenu attached")
assertEqual(findOption(debugMenu, "Force Live") ~= nil, true, "debug action moved into debug submenu")
assertEqual(findOption(debugMenu, "Debug Revive (Free)") ~= nil, true, "missing translation falls back to readable revive label")
assertEqual(findOption(debugMenu, "Orders") ~= nil, true, "debug orders remain available")
assertEqual(findOption(debugMenu, "Combat") ~= nil, true, "debug combat controls remain available")

print("pnc_context_debug_smoke: ok")
