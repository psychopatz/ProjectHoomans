PNC = PNC or {}

local Scenes = PNC.AnimationScenes
if not Scenes or not Scenes.Register then return false end

local function interrupts()
    return { movement = true, combat = true, externalBump = true,
        abstract = true }
end

Scenes.Register("scavenge.loot", {
    category = "scavenge", priority = 45, blocking = false,
    bump = "Loot", durationMs = 650, interrupts = interrupts(),
    pool = "scavenge.loot", weight = 1,
})

Scenes.Register("scavenge.loot_high", {
    category = "scavenge", priority = 45, blocking = false,
    bump = "LootHigh", durationMs = 650, interrupts = interrupts(),
    pool = "scavenge.loot", weight = 1,
})

Scenes.Register("scavenge.loot_low", {
    category = "scavenge", priority = 45, blocking = false,
    bump = "LootLow", durationMs = 650, interrupts = interrupts(),
    pool = "scavenge.loot", weight = 1,
})

Scenes.Register("scavenge.rip", {
    category = "scavenge", priority = 48, blocking = false,
    repeatMode = "once",
    steps = {
        { id = "grab_cloth", bump = "LootLow", durationMs = 400 },
        {
            id = "rip_cloth",
            bump = "RipSheets",
            durationMs = 1200,
            props = { fallbackSecondary = "Base.BurlapPiece" },
        },
    },
    onStart = function(_record, zombie, _scene, step)
        if step and step.id == "rip_cloth"
            and zombie and type(zombie.playSound) == "function"
        then
            pcall(zombie.playSound, zombie, "ClothesRipping")
        end
    end,
    interrupts = interrupts(),
    weight = 1,
})

return true
