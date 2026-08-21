PNC = PNC or {}

local Scenes = PNC.AnimationScenes
if not Scenes or not Scenes.Register then return false end

local function interrupts()
    return { movement = true, combat = true, externalBump = true,
        abstract = true }
end

Scenes.Register("scavenge.loot", {
    category = "scavenge", priority = 45, blocking = false,
    bump = "Loot", durationMs = 1450, interrupts = interrupts(),
})

Scenes.Register("scavenge.loot_high", {
    category = "scavenge", priority = 45, blocking = false,
    bump = "LootHigh", durationMs = 1450, interrupts = interrupts(),
})

Scenes.Register("scavenge.loot_low", {
    category = "scavenge", priority = 45, blocking = false,
    bump = "LootLow", durationMs = 1450, interrupts = interrupts(),
})

return true
