local T = require "tests/support/test"

T.addPackagePaths({ { "ProjectHoomans", "shared" } })

local registered = {}
PNC = { AnimationScenes = {
    Register = function(id, definition)
        registered[id] = definition
        return true
    end,
} }

T.load("ProjectHoomans", "shared",
    "PNC/Core/Scavenge/PNC_ScavengeAnimationScenes.lua")

T.equal(registered["scavenge.loot"].bump, "Loot",
    "standard container scene")
T.equal(registered["scavenge.loot_high"].bump, "LootHigh",
    "high container scene")
T.equal(registered["scavenge.loot_low"].bump, "LootLow",
    "floor and corpse scene")
T.equal(registered["scavenge.loot"].durationMs, 1450,
    "loot transfer waits for scene duration")
T.truthy(registered["scavenge.loot"].interrupts.movement,
    "movement interrupts stale loot scenes")

T.finish("pnc_scavenge_animation_scenes_smoke")
