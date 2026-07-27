local CLIENT_ROOT = "Contents/mods/ProjectHoomans/42.19/media/lua/client/"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local function newMenu()
    local menu = { options = {} }
    function menu:addOption(name, target, callback)
        local option = { name = name, target = target, callback = callback }
        self.options[#self.options + 1] = option
        return option
    end
    function menu:getNew()
        return newMenu()
    end
    function menu:addSubMenu(option, child)
        option.subMenu = child
    end
    return menu
end

local registeredProvider
local selected = {}
local bandageItem = {}
local ragItem = {}
local player = {
    getX = function() return 10 end,
    getY = function() return 10 end,
    getZ = function() return 0 end,
}

PNC = {
    Const = { BANDAGE_RANGE = 3 },
    ContextHub = {
        RegisterProvider = function(provider)
            registeredProvider = provider
        end,
    },
    Network = {
        ClientState = {
            snapshots = {},
            characterPayloads = {},
        },
    },
    NPCWounds = {
        Parts = {
            Hand_R = { label = "Right Hand" },
        },
    },
    Treatment = {
        ListBandages = function()
            return {
                {
                    fullType = "Base.Bandage",
                    name = "Bandage",
                    count = 2,
                    item = bandageItem,
                },
                {
                    fullType = "Base.RippedSheets",
                    name = "Rag",
                    count = 3,
                    item = ragItem,
                },
            }
        end,
    },
    Client = {
        CanUseDebug = function() return false end,
        SendBandage = function(npcId, partId, debugFree, bandageType)
            selected[#selected + 1] = {
                npcId = npcId,
                partId = partId,
                debugFree = debugFree,
                bandageType = bandageType,
            }
        end,
    },
}

getText = function(key) return key end
ISContextMenu = {
    getNew = function()
        return newMenu()
    end,
}

dofile(CLIENT_ROOT .. "PNC/UI/Context/PNC_BandageMenu.lua")
dofile(CLIENT_ROOT
    .. "PNC/UI/Context/Providers/PNC_ContextProvider_Bandage.lua")

local entry = {
    id = "npc_bandage_menu",
    x = 11,
    y = 10,
    z = 0,
    snapshot = {
        bodyHealth = {
            wounds = {
                Hand_R = {
                    type = "laceration",
                    bandaged = false,
                },
            },
        },
    },
}
local menu = newMenu()

assertEqual(registeredProvider.id, "bandage", "bandage provider registered")
assertEqual(registeredProvider.isEnabled(entry), true, "open wound enables provider")
registeredProvider.addOptions(menu, entry, player)

local woundOption = menu.options[1]
assertEqual(woundOption.name, "Bandage Right Hand (laceration)",
    "world context keeps wound-specific root")
assertEqual(woundOption.subMenu.options[1].name, "Bandage (2)",
    "world context groups bandage count")
assertEqual(woundOption.subMenu.options[2].name, "Rag (3)",
    "world context groups rag count")
assertEqual(woundOption.subMenu.options[2].itemForTexture, ragItem,
    "world context uses representative material icon")

woundOption.subMenu.options[2].callback()
assertEqual(selected[1].npcId, "npc_bandage_menu", "selected npc")
assertEqual(selected[1].partId, "Hand_R", "selected wound")
assertEqual(selected[1].debugFree, false, "selected material is consumed")
assertEqual(selected[1].bandageType, "Base.RippedSheets",
    "selected material type reaches timed action")

entry.x = 20
menu = newMenu()
registeredProvider.addOptions(menu, entry, player)
assertEqual(menu.options[1].notAvailable, true,
    "out-of-range wound action unavailable")
assertEqual(menu.options[1].subMenu.options[1].notAvailable, true,
    "out-of-range material unavailable")

print("pnc_bandage_context_menu_smoke: ok")
