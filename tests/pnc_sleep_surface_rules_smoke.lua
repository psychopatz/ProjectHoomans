local T = require "tests/support/test"

T.addPackagePaths()

local Rules = require "PsychopatzCore/World/PsychopatzSquareRules"

local function properties(values)
    return {
        get = function(_, key) return values[key] end,
    }
end

local function object(options)
    options = options or {}
    local spriteProperties = properties(options.spriteProperties or {})
    local sprite = {
        getName = function() return options.spriteName or "" end,
        getProperties = function() return spriteProperties end,
        tilesetName = options.tilesetName,
    }
    if options.grid then
        local grid = options.grid
        sprite.getSpriteGrid = function() return {
            getWidth = function() return grid.width end,
            getHeight = function() return grid.height end,
        } end
    end
    return {
        getName = function() return options.name end,
        getSprite = function() return sprite end,
        getProperties = function() return properties(options.properties or {}) end,
    }
end

local bed = object({
    name = "Bedroom Bed",
    properties = { CustomName = "Bed", BedType = "AverageBed" },
    spriteName = "furniture_bedding_01_0",
})
T.equal(Rules.ClassifySleepSurface(bed), "bed",
    "real beds remain valid sleep surfaces")

local tent = object({
    name = "Tent",
    properties = { CustomName = "Tent", BedType = "BadBed" },
    spriteName = "camping_01_0",
})
T.equal(Rules.ClassifySleepSurface(tent), "bed",
    "tents retain the native bad-bed sleep classification")

local sleepingBag = object({
    name = "Sleeping Bag",
    properties = { CustomName = "Sleeping Bag", BedType = "BadBed" },
    spriteName = "camping_02_0",
})
T.equal(Rules.ClassifySleepSurface(sleepingBag), "bed",
    "sleeping bags retain the native bad-bed sleep classification")

local bedsideTable = object({
    name = "Bedside Table",
    properties = { CustomName = "Bedside Table" },
    spriteName = "furniture_storage_01_0",
})
T.falsy(Rules.IsActualBed(bedsideTable),
    "bedside furniture is not treated as a bed")
T.falsy(Rules.ClassifySleepSurface(bedsideTable),
    "bedside furniture has no sleep classification")

local diningChair = object({
    name = "Dining Chair",
    properties = {
        CustomName = "Dining Chair", BedType = "BadChair",
        FurnitureType = "Seating",
    },
    spriteName = "furniture_seating_01_0",
    tilesetName = "furniture_seating",
})
T.falsy(Rules.IsSleepSurface(diningChair),
    "ordinary dining chairs are not sleep surfaces")

local stool = object({
    name = "Bar Stool",
    properties = { CustomName = "Bar Stool", FurnitureType = "Seating" },
    spriteName = "furniture_seating_01_20",
    tilesetName = "furniture_seating",
})
T.falsy(Rules.IsSleepSurface(stool),
    "stools are not sleep surfaces")

local mislabeledChair = object({
    name = "Dining Chair",
    properties = {
        CustomName = "Bed", BedType = "GoodBed",
        FurnitureType = "Seating",
    },
    spriteName = "furniture_seating_01_0",
    tilesetName = "furniture_seating",
})
T.falsy(Rules.IsActualBed(mislabeledChair),
    "generic seating remains rejected despite bed metadata")

local sofa = object({
    name = "Sofa",
    properties = { CustomName = "Sofa", FurnitureType = "Seating" },
    spriteName = "furniture_seating_01_0",
    tilesetName = "furniture_seating",
    grid = { width = 2, height = 1 },
})
T.equal(Rules.ClassifySleepSurface(sofa), "sofa",
    "named multi-tile sofas are classified separately")

local genericLargeSeat = object({
    name = "Large Bench",
    properties = { FurnitureType = "Seating" },
    spriteName = "furniture_seating_01_0",
    tilesetName = "furniture_seating",
    grid = { width = 2, height = 1 },
})
T.falsy(Rules.ClassifySleepSurface(genericLargeSeat),
    "multi-tile benches remain excluded from sofa sleep")

T.finish("pnc_sleep_surface_rules_smoke")
