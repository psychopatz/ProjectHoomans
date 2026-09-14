local T = require "tests/support/test"

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

local CLIENT_ROOT = T.path("ProjectHoomans", "client", "")
local debugAuthorized = false
local registeredProvider
local sent = {}
local anchorTarget
local simulatedShot
local simulationActive = false
local inspectorTarget

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
    NameplateFirearmAnchor = {
        SetTarget = function(body, id, playerIndex)
            anchorTarget = {
                body = body,
                id = id,
                playerIndex = playerIndex,
            }
        end,
        ToggleTarget = function(body, id, playerIndex)
            anchorTarget = {
                body = body,
                id = id,
                playerIndex = playerIndex,
            }
        end,
    },
    ClientFirearmEffects = {
        IsSimulationActive = function()
            return simulationActive
        end,
        ToggleSimulation = function(body, id, playerIndex)
            simulationActive = not simulationActive
            simulatedShot = {
                body = body,
                id = id,
                playerIndex = playerIndex,
            }
        end,
    },
    NPCCoordinateDebugUI = {
        Open = function(body, id, playerIndex)
            inspectorTarget = {
                body = body,
                id = id,
                playerIndex = playerIndex,
            }
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

T.load(CLIENT_ROOT .. "PNC/UI/Context/Providers/PNC_ContextProvider_Debug.lua")

T.equal(registeredProvider.id, "debug", "debug provider registered")
T.equal(registeredProvider.isEnabled(), false, "provider hidden without debug authorization")
local unauthorizedMenu = newMenu()
registeredProvider.addOptions(unauthorizedMenu, { id = "npc_one" }, {}, {})
T.equal(#unauthorizedMenu.options, 0,
    "debug provider refuses direct option construction without authorization")
debugAuthorized = true
T.equal(registeredProvider.isEnabled(), true, "provider enabled with debug authorization")

local menu = newMenu()
local selectedBody = {}
registeredProvider.addOptions(
    menu,
    { id = "npc_one", zombie = selectedBody },
    {},
    { playerNum = 0 }
)

T.equal(#menu.options, 1, "debug commands are grouped under one NPC submenu entry")
T.equal(menu.options[1].name, "Debug", "debug submenu uses a readable fallback label")
local debugMenu = menu.options[1].submenu
T.equal(debugMenu ~= nil, true, "debug submenu attached")
T.equal(findOption(debugMenu, "Force Live") ~= nil, true, "debug action moved into debug submenu")
T.equal(findOption(debugMenu, "Debug Bandage All (Free)") ~= nil, true,
    "missing translation falls back to readable bandage-all label")
T.equal(findOption(debugMenu, "Orders") ~= nil, true, "debug orders remain available")
T.equal(findOption(debugMenu, "Combat") ~= nil, true, "debug combat controls remain available")
T.equal(
    findOption(debugMenu, "Animation Scene Lab") ~= nil,
    true,
    "scene lab is available from the NPC debug submenu"
)
T.equal(
    findOption(debugMenu, "NPC Presentation Lab") ~= nil,
    true,
    "NPC presentation lab is the unified animation/firearm entry point"
)
T.falsy(
    findOption(debugMenu, "Debug: Firearm Anchor Probe"),
    "old standalone firearm anchor probe was removed"
)
T.falsy(
    findOption(debugMenu, "Debug: Start Firearm Simulation"),
    "old standalone firearm simulation was removed"
)
T.falsy(
    findOption(debugMenu, "Debug: NPC Coordinate Inspector"),
    "old standalone coordinate inspector was removed"
)
local infectionOption = findOption(debugMenu, "Infection")
T.equal(infectionOption ~= nil, true, "infection debug submenu missing")
local clearOption = findOption(infectionOption.submenu, "Clear Knox Infection")
T.equal(clearOption ~= nil, true, "infection clear action missing")
T.equal(clearOption.notAvailable, false, "infection clear disabled for infected NPC")
clearOption.callback()
T.equal(sent[1].action, "clear_infection", "world menu infection clear action")
T.equal(sent[1].payload.id, "npc_one", "world menu infection clear NPC")
local sentCount = #sent
debugAuthorized = false
clearOption.callback()
T.equal(#sent, sentCount, "stale debug option is gated at callback time")
debugAuthorized = true

local bandageOption = findOption(debugMenu, "Bandage State")
T.equal(bandageOption ~= nil, true, "bandage debug submenu missing")
local almostDirty = findOption(
    bandageOption.submenu,
    "Make Almost Dirty: Left Hand"
)
T.equal(almostDirty ~= nil, true, "almost-dirty bandage action missing")
almostDirty.callback()
T.equal(sent[2].action, "bandage_almost_dirty", "world menu almost-dirty action")
T.equal(sent[2].payload.partId, "Hand_L", "world menu almost-dirty part")
T.finish("pnc_context_debug_smoke")

T.finish("pnc_context_debug_smoke")
