local T = require "tests/support/test"

package.preload["ISUI/ISContextMenu"] = function() return {} end

local function hasPath(list, expected)
    for i = 1, #list do
        if list[i] and list[i].path == expected then return true end
    end
    return false
end

local debugSent = {}
local function newMenu()
    local menu = { options = {} }
    function menu:addOption(name, target, callback)
        local option = { name = name, target = target, callback = callback }
        self.options[#self.options + 1] = option
        return option
    end
    function menu:getNew() return newMenu() end
    function menu:addSubMenu(option, child) option.subMenu = child end
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

getGameTime = function()
    return { getWorldAgeHours = function() return 50 end }
end
getSpecificPlayer = function() return {} end
getTexture = function(path) return path end
ZombRand = function(n) return 0 end

PNC = {
    Core = {
        IsAuthority = function() return true end,
        Now = function() return 1000 end,
        Clamp = function(v, lo, hi)
            v = tonumber(v) or 0
            return math.max(lo, math.min(hi, v))
        end,
    },
    Health = {
        ApplyDamage = function(record, dmg)
            record.health.hp = math.max(0, (record.health.hp or 100) - (dmg or 0))
            return true, { hp = record.health.hp }
        end,
        Recover = function(record)
            record.health.hp = record.health.maxHp or 100
            record.health.state = "healthy"
            if record.health.body then
                record.health.body.wounds = {}
            end
        end,
    },
    CharacterWindowTabs = {},
    CharacterWindowShared = {
        GetSnapshot = function(snapshot, payload)
            return payload and payload.snapshot or snapshot or {}
        end,
        Text = function(_, fallback) return fallback end,
        Clamp = function(value, minimum, maximum)
            value = tonumber(value) or 0
            return math.max(minimum, math.min(maximum, value))
        end,
    },
    Client = {
        CanUseDebug = function() return true end,
        SendDebug = function(action, payload)
            debugSent[#debugSent + 1] = { action = action, payload = payload }
        end,
    },
}

T.load(T.path("ProjectHoomans", "shared", "PNC/Core/Health/PNC_NPCWounds.lua"))
T.load(T.path("ProjectHoomans", "client", "PNC/UI/CharacterWindow/PNC_CharacterWindow_Health.lua"))

local Health = PNC.CharacterWindowHealth
local Wounds = PNC.NPCWounds

-- 1. Verify vanilla BodyDamage overlay resolution for all wound types & states
local burnLayers = Health.ResolvePartOverlays("male", "forearm_l", "ForeArm_L", {
    type = "burn", bleeding = true, bandaged = false,
}, {})
T.equal(#burnLayers, 1, "burn overlay count")
T.equal(burnLayers[1].path, "media/ui/BodyDamage/male_burn_forearm_l", "burn uses burn texture, not scratch")

local glassLayers = Health.ResolvePartOverlays("female", "hand_r", "Hand_R", {
    type = "deep_wound_glass", bandaged = false,
}, {})
T.truthy(hasPath(glassLayers, "media/ui/BodyDamage/female_deepwound_hand_r"), "glass deep wound shows deepwound")
T.truthy(hasPath(glassLayers, "media/ui/BodyDamage/female_glass_hand_r"), "glass deep wound shows lodged glass")

local bulletLayers = Health.ResolvePartOverlays("male", "torso_upper", "Torso_Upper", {
    type = "bullet", bandaged = false,
}, {})
T.truthy(hasPath(bulletLayers, "media/ui/BodyDamage/male_bullet_torso_upper"), "bullet shows bullet texture")

local fractureLayers = Health.ResolvePartOverlays("male", "shin_l", "LowerLeg_L", {
    type = "fracture", bandaged = false, splinted = false,
}, {})
T.truthy(hasPath(fractureLayers, "media/ui/BodyDamage/male_bones_shin_l"), "un-splinted fracture shows bones")

local splintedLayers = Health.ResolvePartOverlays("male", "shin_l", "LowerLeg_L", {
    type = "fracture", bandaged = false, splinted = true,
}, {})
T.truthy(hasPath(splintedLayers, "media/ui/BodyDamage/male_splint_shin_l"), "splinted fracture shows splint")
T.truthy(not hasPath(splintedLayers, "media/ui/BodyDamage/male_bones_shin_l"), "splint replaces bones")

local stitchedLayers = Health.ResolvePartOverlays("male", "head", "Head", {
    type = "deep_wound", stitched = true, bandaged = false,
}, {})
T.truthy(hasPath(stitchedLayers, "media/ui/BodyDamage/male_stitches_head"), "stitched shows stitches texture")

local dirtyBandageLayers = Health.ResolvePartOverlays("male", "upperarm_r", "UpperArm_R", {
    type = "burn", bandaged = true, bandageDirty = true, infected = true,
}, {})
T.equal(#dirtyBandageLayers, 1, "bandaged hides burn and infection glow")
T.equal(dirtyBandageLayers[1].path, "media/ui/BodyDamage/male_bandagedirty_upperarm_r", "dirty bandage texture")

local infectedBiteLayers = Health.ResolvePartOverlays("male", "neck", "Neck", {
    type = "bite", bandaged = false, infected = true,
}, { infection = { active = true, partId = "Neck" } })
T.equal(infectedBiteLayers[1].path, "media/ui/BodyDamage/male_infection_neck", "infection glow renders beneath bite")
T.equal(infectedBiteLayers[2].path, "media/ui/BodyDamage/male_bite_neck", "bite renders above infection glow")

-- 2. Verify ApplyDebugWound accepts all 8 wound types + aliases
local record = { id = "npc_debug_health", alive = true, health = { hp = 100, maxHp = 100 } }
local expectedTypes = {
    { input = "scratch", expected = "scratch", part = "Head" },
    { input = "laceration", expected = "laceration", part = "Neck" },
    { input = "bite", expected = "bite", part = "Torso_Upper" },
    { input = "burned", expected = "burn", part = "ForeArm_L" },
    { input = "fractured", expected = "fracture", part = "LowerLeg_L" },
    { input = "deep_wound", expected = "deep_wound", part = "UpperArm_R" },
    { input = "glass", expected = "deep_wound_glass", part = "Hand_R" },
    { input = "bullet", expected = "bullet", part = "Torso_Lower" },
}
for i = 1, #expectedTypes do
    local tc = expectedTypes[i]
    local ok, detail = Wounds.ApplyDebugWound(record, nil, tc.part, tc.input)
    T.equal(ok, true, "debug wound applied " .. tc.input)
    local wound = record.health.body.wounds and record.health.body.wounds[tc.part]
    T.truthy(wound, "debug wound exists on " .. tc.part)
    T.equal(detail.partId, tc.part, "debug wound part " .. tc.input)
    T.equal(wound.type, tc.expected, "debug wound normalized type " .. tc.input)
end

-- 3. Verify ApplyDebugWoundState covers all 8 state actions
local body = record.health.body
local ok, err = Wounds.ApplyDebugWoundState(record, nil, "ForeArm_L", "dirty_bandage")
T.truthy(ok, "dirty_bandage ok: " .. tostring(err))
T.equal(body.wounds.ForeArm_L.bandaged, true, "dirty_bandage sets bandaged")
T.equal(body.wounds.ForeArm_L.bandageDirty, true, "dirty_bandage sets bandageDirty")

ok = Wounds.ApplyDebugWoundState(record, nil, "UpperArm_R", "toggle_stitched")
T.truthy(ok, "toggle_stitched ok")
T.equal(body.wounds.UpperArm_R.stitched, true, "toggle_stitched enables stitches")
T.truthy(not body.wounds.UpperArm_R.bleeding, "toggle_stitched stops bleeding")

ok = Wounds.ApplyDebugWoundState(record, nil, "LowerLeg_L", "toggle_splint")
T.truthy(ok, "toggle_splint ok")
T.equal(body.wounds.LowerLeg_L.splinted, true, "toggle_splint enables splint")

ok = Wounds.ApplyDebugWoundState(record, nil, "Head", "toggle_ordinary_infection")
T.truthy(ok, "toggle_ordinary_infection ok")
T.equal(body.wounds.Head.infected, true, "toggle_ordinary_infection enables infection")

ok = Wounds.ApplyDebugWoundState(record, nil, "Neck", "toggle_bleeding")
T.truthy(ok, "toggle_bleeding ok")
T.equal(body.wounds.Neck.bleedingRate, 0, "toggle_bleeding flips bleedingRate to 0")

ok = Wounds.ApplyDebugWoundState(record, nil, "Hand_R", "clear_part_wound")
T.truthy(ok, "clear_part_wound ok")
T.equal(body.wounds.Hand_R, nil, "clear_part_wound removes wound")

ok = Wounds.ApplyDebugWoundState(record, nil, nil, "incapacitate")
T.truthy(ok, "incapacitate ok")
T.equal(record.health.state, "incapacitated", "incapacitate sets health.state")

ok = Wounds.ApplyDebugWoundState(record, nil, nil, "heal_all")
T.truthy(ok, "heal_all ok")
T.equal(record.health.state, "healthy", "heal_all clears incapacitated")
T.equal(record.health.hp, 100, "heal_all restores health")

-- 4. Verify Debug context menu exposes all 8 wound types & 8 state actions
local view = {
    npcId = "npc_debug_health",
    snapshot = { bodyHealth = { wounds = { ForeArm_L = { type = "burn", bandaged = false } } } },
    payload = {},
    healthHitRegions = { { x = 10, y = 10, width = 40, height = 20, partId = "ForeArm_L" } },
    getAbsoluteX = function() return 0 end,
    getAbsoluteY = function() return 0 end,
}
T.equal(PNC.CharacterWindowTabs.OnHealthRightMouseUp(view, 20, 15), true, "debug context opened")

local injuryOption, stateOption
for i = 1, #rootMenu.options do
    if rootMenu.options[i].name == "Debug Injury" then injuryOption = rootMenu.options[i] end
    if rootMenu.options[i].name == "Debug Wound & Body States" then stateOption = rootMenu.options[i] end
end
T.truthy(injuryOption and injuryOption.subMenu, "Debug Injury submenu exists")
T.truthy(stateOption and stateOption.subMenu, "Debug Wound & Body States submenu exists")

local selectedPartTypeMenu = injuryOption.subMenu.options[2].subMenu
T.equal(#selectedPartTypeMenu.options, 8, "all 8 wound types in selected part submenu")
selectedPartTypeMenu.options[4].callback()
T.equal(debugSent[#debugSent].action, "damage_part", "burn debug action")
T.equal(debugSent[#debugSent].payload.partId, "ForeArm_L", "burn debug part")
T.equal(debugSent[#debugSent].payload.woundType, "burn", "burn debug woundType")

T.equal(#stateOption.subMenu.options, 8, "all 8 state actions in wound state submenu")
stateOption.subMenu.options[1].callback()
T.equal(debugSent[#debugSent].action, "debug_wound_state", "dirty bandage debug action")
T.equal(debugSent[#debugSent].payload.stateAction, "dirty_bandage", "dirty bandage stateAction")

T.finish("pnc_health_ui_overlays_and_debug_smoke")
