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
local sent = {}

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
        SendDebug = function(action, payload)
            sent[#sent + 1] = { action = action, payload = payload }
        end,
    },
    ContextHub = {
        RegisterProvider = function(provider)
            registeredProvider = provider
        end,
    },
    Network = {
        ClientState = {
            snapshots = {
                npc_one = {
                    healthState = "incapacitated",
                    canRevive = true,
                    bodyHealth = {
                        infection = { active = true, stage = "fever" },
                        wounds = {
                            Hand_L = {
                                bandaged = true,
                                bandageDirty = false,
                            },
                        },
                    },
                },
            },
        },
    },
    NPCWounds = {
        Parts = {
            Hand_L = { label = "Left Hand" },
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
assertEqual(findOption(debugMenu, "Debug Bandage All (Free)") ~= nil, true,
    "missing translation falls back to readable bandage-all label")
assertEqual(findOption(debugMenu, "Orders") ~= nil, true, "debug orders remain available")
assertEqual(findOption(debugMenu, "Combat") ~= nil, true, "debug combat controls remain available")
local infectionOption = findOption(debugMenu, "Infection")
assertEqual(infectionOption ~= nil, true, "infection debug submenu missing")
local clearOption = findOption(infectionOption.submenu, "Clear Knox Infection")
assertEqual(clearOption ~= nil, true, "infection clear action missing")
assertEqual(clearOption.notAvailable, false, "infection clear disabled for infected NPC")
clearOption.callback()
assertEqual(sent[1].action, "clear_infection", "world menu infection clear action")
assertEqual(sent[1].payload.id, "npc_one", "world menu infection clear NPC")

local bandageOption = findOption(debugMenu, "Bandage State")
assertEqual(bandageOption ~= nil, true, "bandage debug submenu missing")
local almostDirty = findOption(
    bandageOption.submenu,
    "Make Almost Dirty: Left Hand"
)
assertEqual(almostDirty ~= nil, true, "almost-dirty bandage action missing")
almostDirty.callback()
assertEqual(sent[2].action, "bandage_almost_dirty", "world menu almost-dirty action")
assertEqual(sent[2].payload.partId, "Hand_L", "world menu almost-dirty part")

print("pnc_context_debug_smoke: ok")
