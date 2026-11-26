local T = require "tests/support/test"
T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "server" },
})

PNC = {
    Core = { Now = function() return 1000 end },
    Animation = {},
}

local Scenes = T.load("ProjectHoomans", "shared",
    "PNC/Core/Visuals/PNC_AnimationScenes.lua")
local ActionProps = T.load("ProjectHoomans", "shared",
    "PNC/Core/Visuals/PNC_ActionProps.lua")
local Packs = T.load("ProjectHoomans", "shared",
    "PNC/Core/Visuals/PNC_AnimationPacks.lua")

-- Register a base ProjectHoomans scene.
local okBase = Scenes.Register("ambient.roam.eat", {
    bump = "Base_Eat",
    durationMs = 2000,
})
T.equal(okBase, true, "base scene registers")

-- 1. Modder Pack A replaces ambient.roam.eat with custom bump + dual-hand props
--    and adds a conditional rifle walk stance + a pool variation.
local okPackA = Packs.RegisterPack("pack_tactical", {
    priority = 100,
    locomotion = {
        walk = {
            {
                when = { weaponClass = "rifle" },
                vars = { walkType = "TacticalWalk", animSpeed = 1.05 },
            },
        },
    },
    scenes = {
        ["ambient.roam.eat"] = {
            mode = "replace",
            steps = {
                {
                    id = "bite",
                    bumpType = "Tactical_EatApple",
                    durationMs = 2500,
                    props = {
                        primaryFrom = "action_item",
                        fallbackPrimary = "Base.Apple",
                        secondary = "Base.Knife",
                        equipmentMode = "holster_weapon",
                    },
                },
            },
        },
        ["combat.melee.slash_alt"] = {
            mode = "add_to_pool",
            pool = "combat.melee.onehand",
            weight = 30,
            bumpType = "Tactical_Slash02",
        },
    },
})
T.equal(okPackA, true, "modder pack A registers cleanly")
T.equal(Scenes.Get("ambient.roam.eat").bump, "Tactical_EatApple",
    "pack A replaces base scene bump")
T.truthy(Scenes.Pools["combat.melee.onehand"]
    and #Scenes.Pools["combat.melee.onehand"] == 1,
    "add_to_pool adds variation to weighted pool")

-- 2. Data-driven ActionProps resolves fallback apple + secondary knife,
--    and prefers actual action item (banana) when present.
local propFallback = ActionProps.Resolve({
    visualState = {
        sceneId = "ambient.roam.eat",
        sceneStepId = "bite",
        sceneRevision = 10,
    },
    actionInformation = {},
})
T.truthy(propFallback, "ActionProps resolves declared step props")
T.equal(propFallback.primaryFullType, "Base.Apple",
    "fallbackPrimary supplies Base.Apple when no action item is set")
T.equal(propFallback.secondaryFullType, "Base.Knife",
    "secondary hand prop supplies Base.Knife")
T.equal(propFallback.hand, "both", "dual-hand descriptor sets hand='both'")
T.equal(propFallback.equipmentMode, "holster_weapon",
    "equipmentMode is preserved on prop descriptor")

local propDynamic = ActionProps.Resolve({
    visualState = {
        sceneId = "ambient.roam.eat",
        sceneStepId = "bite",
        sceneRevision = 11,
    },
    actionInformation = {
        activityItemFullType = "Base.Banana",
        activityItemID = 99,
    },
})
T.equal(propDynamic.primaryFullType, "Base.Banana",
    "primaryFrom='action_item' uses actual NPC inventory food item")
T.equal(propDynamic.primaryItemID, 99, "action item ID is preserved")

-- 3. Higher-priority Pack B overrides Pack A; unregistering rolls back cleanly.
Packs.RegisterPack("pack_override", {
    priority = 200,
    scenes = {
        ["ambient.roam.eat"] = {
            mode = "replace",
            bumpType = "Override_Eat",
        },
    },
})
T.equal(Scenes.Get("ambient.roam.eat").bump, "Override_Eat",
    "higher priority pack wins")
Packs.UnregisterPack("pack_override")
T.equal(Scenes.Get("ambient.roam.eat").bump, "Tactical_EatApple",
    "unregistering pack B restores pack A")
Packs.UnregisterPack("pack_tactical")
T.equal(Scenes.Get("ambient.roam.eat").bump, "Base_Eat",
    "unregistering pack A restores original base ProjectHoomans scene")
T.equal(Scenes.Get("combat.melee.slash_alt"), nil,
    "pack-only pool variation is removed on unregister")

-- 4. Conditional locomotion profile resolution.
Packs.RegisterPack("pack_loco", {
    priority = 100,
    locomotion = {
        walk = {
            {
                when = { weaponClass = "rifle" },
                vars = { walkType = "TacticalWalk", animSpeed = 1.05 },
            },
        },
    },
})
local rifleWalk = Packs.ResolveLocomotion("walk", { weaponClass = "rifle" })
T.truthy(rifleWalk, "conditional rifle walk matches rifle context")
T.equal(rifleWalk.walkType, "TacticalWalk", "tactical walkType applied")
T.equal(Packs.ResolveLocomotion("walk", { weaponClass = "pistol" }), nil,
    "non-matching weaponClass falls back to base locomotion")

-- 5. Direct visualState prop override (for PuppetOpera beats).
local operaProp = ActionProps.Resolve({
    visualState = {
        propPrimary = "Base.Apple",
        propSecondary = "Base.WaterBottleFull",
        sceneRevision = 42,
    },
})
T.truthy(operaProp, "PuppetOpera visual prop override resolves directly")
T.equal(operaProp.primaryFullType, "Base.Apple", "opera primary prop set")
T.equal(operaProp.secondaryFullType, "Base.WaterBottleFull",
    "opera secondary prop set")
