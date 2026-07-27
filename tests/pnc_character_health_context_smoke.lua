local ROOT = "Contents/mods/ProjectHoomans/42.19/media/lua/client/PNC/UI/CharacterWindow/"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected) .. " actual=" .. tostring(actual))
    end
end

package.preload["ISUI/ISContextMenu"] = function() return {} end

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

local rootMenu
ISContextMenu = {
    get = function(_, x, y)
        rootMenu = newMenu()
        rootMenu.x = x
        rootMenu.y = y
        return rootMenu
    end,
}

local sent = {}
local debugSent = {}
local bandageItem = {}
PNC = {
    CharacterWindowTabs = {},
    CharacterWindowShared = {
        GetSnapshot = function(snapshot, payload) return payload and payload.snapshot or snapshot or {} end,
        Text = function(_, fallback) return fallback end,
    },
    Treatment = {
        ListBandages = function()
            return { { fullType = "Base.Bandage", name = "Bandage", count = 2, item = bandageItem } }
        end,
    },
    NPCWounds = {
        PartOrder = { "Head", "Hand_R" },
        Parts = {
            Head = { label = "Head" },
            Hand_R = { label = "Right Hand" },
        },
    },
    Client = {
        CanUseDebug = function() return true end,
        SendBandage = function(npcId, partId, debugFree, bandageType)
            sent[#sent + 1] = { npcId, partId, debugFree, bandageType }
        end,
        SendDebug = function(action, payload)
            debugSent[#debugSent + 1] = { action = action, payload = payload }
        end,
    },
}

getSpecificPlayer = function() return {} end

dofile(ROOT .. "PNC_CharacterWindow_Health.lua")

local view = {
    npcId = "npc_health_menu",
    snapshot = { bodyHealth = { wounds = { Head = { type = "bite", bandaged = false } } } },
    payload = {},
    healthHitRegions = { { x = 10, y = 10, width = 40, height = 20, partId = "Head" } },
    getAbsoluteX = function() return 100 end,
    getAbsoluteY = function() return 200 end,
}

assertEqual(PNC.CharacterWindowTabs.OnHealthRightMouseUp(view, 20, 15), true, "health right-click handled")
assertEqual(rootMenu.x, 120, "context absolute x")
assertEqual(rootMenu.y, 215, "context absolute y")
assertEqual(rootMenu.options[1].name, "Bandage", "vanilla bandage option")
assertEqual(rootMenu.options[1].subMenu.options[1].itemForTexture, bandageItem, "actual item icon")

rootMenu.options[1].subMenu.options[1].callback()
assertEqual(sent[1][1], "npc_health_menu", "standard bandage npc")
assertEqual(sent[1][2], "Head", "standard bandage part")
assertEqual(sent[1][3], false, "standard bandage consumes")
assertEqual(sent[1][4], "Base.Bandage", "selected bandage type")

rootMenu.options[2].callback()
assertEqual(sent[2][3], true, "debug bandage no-consume flag")

assertEqual(rootMenu.options[3].name, "Debug Injury", "debug injury option")
local damageMenu = rootMenu.options[3].subMenu
assertEqual(damageMenu.options[1].name, "Random Body Part", "random injury option")
assertEqual(damageMenu.options[2].name, "Injure Head", "clicked body-part injury")
assertEqual(damageMenu.options[3].name, "Choose Body Part", "specific body-part submenu")
damageMenu.options[1].callback()
assertEqual(debugSent[1].action, "damage_part", "random injury action")
assertEqual(debugSent[1].payload.partId, nil, "random injury omits body part")
damageMenu.options[2].callback()
assertEqual(debugSent[2].payload.partId, "Head", "clicked injury part")
damageMenu.options[3].subMenu.options[2].callback()
assertEqual(debugSent[3].payload.partId, "Hand_R", "chosen injury part")

assertEqual(rootMenu.options[4].name, "Debug Infection", "debug infection option")
local infectionMenu = rootMenu.options[4].subMenu
assertEqual(infectionMenu.options[1].name, "Status: NOT INFECTED", "infection status")
infectionMenu.options[2].callback()
assertEqual(debugSent[4].action, "infection", "force infection action")
assertEqual(debugSent[4].payload.partId, "Head", "force infection selected part")
assertEqual(debugSent[4].payload.stage, "incubating", "force infection initial stage")
infectionMenu.options[3].callback()
assertEqual(debugSent[5].payload.stage, "fever", "advance infection fever")

view.snapshot.bodyHealth.wounds = {}
view.healthHitRegions = {}
assertEqual(PNC.CharacterWindowTabs.OnHealthRightMouseUp(view, 70, 70), true, "blank health debug menu")
assertEqual(rootMenu.options[1].name, "Debug Injury", "blank health menu only offers debug injury")
assertEqual(rootMenu.options[2].name, "Debug Infection", "blank health menu offers infection debug")

local healthUIPath = "Contents/mods/ProjectHoomans/42.19/media/lua/client/PNC/UI/CharacterWindow/PNC_CharacterWindow_Health.lua"
local healthUIFile = assert(io.open(healthUIPath, "r"))
local healthUISource = healthUIFile:read("*a")
healthUIFile:close()
assert(string.find(healthUISource, "media/ui/BodyDamage/", 1, true), "vanilla body-damage textures are not used")
assert(string.find(healthUISource, '"_bandage_"', 1, true), "vanilla bandage overlays are not used")
assert(string.find(healthUISource, '"_bite_"', 1, true), "vanilla bite overlays are not used")
assert(not string.find(healthUISource, "bps_node_diamond", 1, true), "generic wound diamonds returned")

print("pnc_character_health_context_smoke: ok")
