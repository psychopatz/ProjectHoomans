--[[
    PNC Starting Equipment Catalog
    Content-only definitions for identity-seeded equipment generation. Add
    future categories such as medical, ammunition, or tools beside the weapon
    categories without changing the generic pool service.
]]

PNC = PNC or {}

local Inventory = PNC.Inventory
if not Inventory or not Inventory.RegisterEquipmentSpawnPool then return end

Inventory.RegisterEquipmentSpawnPool("Default", {
    categories = {
        meleeWeapon = {
            "Base.Hammer",
            "Base.KitchenKnife",
            "Base.BaseballBat",
            "Base.Pipe",
            "Base.HandAxe",
            "Base.Crowbar",
            "Base.PipeWrench",
            "Base.Wrench",
            "Base.Scalpel",
            "Base.Shovel",
            "Base.GardenFork",
        },
        rangedWeapon = {
            {
                type = "Base.Pistol",
                weight = 5,
                grants = {
                    { key = "ammo_9mm", type = "Base.Bullets9mm", stack = 24, preferredContainer = "bag" },
                },
            },
            {
                type = "Base.Revolver",
                weight = 3,
                grants = {
                    { key = "ammo_38", type = "Base.Bullets38", stack = 18, preferredContainer = "bag" },
                },
            },
            {
                type = "Base.DoubleBarrelShotgun",
                weight = 2,
                grants = {
                    { key = "ammo_shells", type = "Base.ShotgunShells", stack = 12, preferredContainer = "bag" },
                },
            },
        },
    },
})
