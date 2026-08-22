local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "client", "PNC/UI/CharacterWindow/")
local BANDAGE_MENU_FILE =
    T.path("ProjectHoomans", "client", "PNC/UI/Context/PNC_BandageMenu.lua")

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
getGameTime = function()
    return { getWorldAgeHours = function() return 100 end }
end

T.load(BANDAGE_MENU_FILE)
T.load(ROOT .. "PNC_CharacterWindow_Health.lua")

local view = {
    npcId = "npc_health_menu",
    snapshot = { bodyHealth = { wounds = { Head = { type = "bite", bandaged = false } } } },
    payload = {},
    healthHitRegions = { { x = 10, y = 10, width = 40, height = 20, partId = "Head" } },
    getAbsoluteX = function() return 100 end,
    getAbsoluteY = function() return 200 end,
}

T.equal(PNC.CharacterWindowTabs.OnHealthRightMouseUp(view, 20, 15), true, "health right-click handled")
T.equal(rootMenu.x, 120, "context absolute x")
T.equal(rootMenu.y, 215, "context absolute y")
T.equal(rootMenu.options[1].name, "Bandage", "vanilla bandage option")
T.equal(rootMenu.options[1].subMenu.options[1].name, "Bandage (2)",
    "character menu groups bandages by type and count")
T.equal(rootMenu.options[1].subMenu.options[1].itemForTexture, bandageItem, "actual item icon")

rootMenu.options[1].subMenu.options[1].callback()
T.equal(sent[1][1], "npc_health_menu", "standard bandage npc")
T.equal(sent[1][2], "Head", "standard bandage part")
T.equal(sent[1][3], false, "standard bandage consumes")
T.equal(sent[1][4], "Base.Bandage", "selected bandage type")

rootMenu.options[2].callback()
T.equal(sent[2][3], true, "debug bandage no-consume flag")

T.equal(rootMenu.options[3].name, "Debug Injury", "debug injury option")
local damageMenu = rootMenu.options[3].subMenu
T.equal(damageMenu.options[1].name, "Random Body Part", "random injury option")
T.equal(damageMenu.options[2].name, "Injure Head", "clicked body-part injury")
T.equal(damageMenu.options[3].name, "Choose Body Part", "specific body-part submenu")
damageMenu.options[1].callback()
T.equal(debugSent[1].action, "damage_part", "random injury action")
T.equal(debugSent[1].payload.partId, nil, "random injury omits body part")
damageMenu.options[2].callback()
T.equal(debugSent[2].payload.partId, "Head", "clicked injury part")
damageMenu.options[3].subMenu.options[2].callback()
T.equal(debugSent[3].payload.partId, "Hand_R", "chosen injury part")

T.equal(rootMenu.options[4].name, "Debug Infection", "debug infection option")
local infectionMenu = rootMenu.options[4].subMenu
T.equal(infectionMenu.options[1].name, "Status: NOT INFECTED", "infection status")
infectionMenu.options[2].callback()
T.equal(debugSent[4].action, "infection", "force infection action")
T.equal(debugSent[4].payload.partId, "Head", "force infection selected part")
T.equal(debugSent[4].payload.stage, "incubating", "force infection initial stage")
infectionMenu.options[3].callback()
T.equal(debugSent[5].payload.stage, "fever", "advance infection fever")
T.equal(infectionMenu.options[6].name, "Clear Knox Infection", "infection clear option")
T.equal(infectionMenu.options[6].notAvailable, true, "healthy infection clear disabled")

view.snapshot.bodyHealth.infection = { active = true, stage = "incubating" }
T.equal(PNC.CharacterWindowTabs.OnHealthRightMouseUp(view, 20, 15), true,
    "infected health debug menu")
infectionMenu = rootMenu.options[4].subMenu
T.equal(infectionMenu.options[6].notAvailable, false, "infected clear enabled")
infectionMenu.options[6].callback()
T.equal(debugSent[6].action, "clear_infection", "clear infection action")
T.equal(debugSent[6].payload.id, "npc_health_menu", "clear infection npc")

view.snapshot.bodyHealth.wounds.Head = {
    type = "bite",
    bandaged = true,
    bandageDirty = false,
    dirtyAtWorldHour = 100.02,
    damage = 8,
    bandageInitialDamage = 12,
    bandageHealedPoints = 4,
    healRatePerWorldHour = 2,
}
T.equal(PNC.CharacterWindowTabs.OnHealthRightMouseUp(view, 20, 15), true,
    "bandaged health debug menu")
T.equal(rootMenu.options[1].name, "Debug Bandage State", "bandage debug submenu")
T.equal(rootMenu.options[1].subMenu.options[1].name,
    "Status: clean, 0.020 world h remaining", "bandage dirty timer status")
rootMenu.options[1].subMenu.options[2].callback()
T.equal(debugSent[7].action, "bandage_almost_dirty", "almost-dirty action")
T.equal(debugSent[7].payload.partId, "Head", "almost-dirty selected part")

view.snapshot.bodyHealth.wounds = {}
view.healthHitRegions = {}
T.equal(PNC.CharacterWindowTabs.OnHealthRightMouseUp(view, 70, 70), true, "blank health debug menu")
T.equal(rootMenu.options[1].name, "Debug Injury", "blank health menu only offers debug injury")
T.equal(rootMenu.options[2].name, "Debug Infection", "blank health menu offers infection debug")

local healthUISource = T.read(
    "ProjectHoomans", "client", "PNC/UI/CharacterWindow/PNC_CharacterWindow_Health.lua"
)
T.truthy(string.find(healthUISource, "media/ui/BodyDamage/", 1, true), "vanilla body-damage textures are not used")
T.truthy(string.find(healthUISource, '"_bandage_"', 1, true), "vanilla bandage overlays are not used")
T.truthy(string.find(healthUISource, '"_bite_"', 1, true), "vanilla bite overlays are not used")
T.truthy(not string.find(healthUISource, "bps_node_diamond", 1, true), "generic wound diamonds returned")
T.truthy(not string.find(healthUISource, "HP %.1f / %.1f", 1, true),
    "numeric HP returned to the health panel")
T.truthy(string.find(healthUISource, "DEBUG Dirty in:", 1, true),
    "bandage dirty timer diagnostics missing")
T.truthy(string.find(healthUISource, "DEBUG Healed:", 1, true),
    "bandage healing-point diagnostics missing")
T.finish("pnc_character_health_context_smoke")

T.finish("pnc_character_health_context_smoke")
