local Definitions = PNC.FacilityDefinitions
    or require "PNC/Core/Settlement/PNC_FacilityDefinitions/PNC_FacilityDefinitions_Core"

local definition = {
    id = "bedroom",
    category = "housing",
    displayNameKey = "UI_PNC_Facility_Bedroom",
    descriptionKey = "UI_PNC_Facility_BedroomDescription",
    iconPath = "media/ui/Facilities/BuildingMenu/livingRoom.png",
    -- Sleep selection is deterministic across multiple housing facilities.
    -- A future shelter can opt into sleep with a lower priority.
    sleepPriority = 100,
    buildCosts = {{ fullType = "Base.Money", amount = 1 }},
    buildWork = 80,
    reconstructWork = 50,
    deconstructWork = 50,
    allowMultipleRegions = true,
    -- The construction footprint is the room zone. The layout overlay uses
    -- this opt-in for the reusable zone-backed facility renderer.
    zoneOverlay = true,
    zoneColor = "bedroom",
    -- Beds are discovered from the construction region after the room is
    -- built. The old role remains as a hidden compatibility limit so saved
    -- anchor records can still load and be retired safely later.
    levels = {
        [1] = {
            requiredHQLevel = 1,
            capabilities = { "sleep", "rest" },
            resourceBindings = {
                sleep = {
                    detectorId = "bed", role = "sleep.bed",
                    resourceKind = "sleep_surface",
                    virtual = { key = "floor", resourceKind = "floor_sleep",
                        exclusive = false, sceneId = "facility.sleep.floor",
                        sleepSurface = "floor" },
                },
            },
            componentLimits = {
                ["sleep.bed"] = { kind = "anchor", minCount = 0, maxCount = 4,
                    fixedTileCount = 2, usesWorldObjectFootprint = true,
                    legacy = true },
            },
            activityLimits = { sleep = { maxConcurrent = 4 } },
        },
        [2] = {
            requiredHQLevel = 2,
            capabilities = { "sleep", "rest" },
            resourceBindings = {
                sleep = {
                    detectorId = "bed", role = "sleep.bed",
                    resourceKind = "sleep_surface",
                    virtual = { key = "floor", resourceKind = "floor_sleep",
                        exclusive = false, sceneId = "facility.sleep.floor",
                        sleepSurface = "floor" },
                },
            },
            componentLimits = {
                ["sleep.bed"] = { kind = "anchor", minCount = 0, maxCount = 8,
                    fixedTileCount = 2, usesWorldObjectFootprint = true,
                    legacy = true },
            },
            activityLimits = { sleep = { maxConcurrent = 8 } },
        },
        [3] = {
            requiredHQLevel = 3,
            capabilities = { "sleep", "rest" },
            resourceBindings = {
                sleep = {
                    detectorId = "bed", role = "sleep.bed",
                    resourceKind = "sleep_surface",
                    virtual = { key = "floor", resourceKind = "floor_sleep",
                        exclusive = false, sceneId = "facility.sleep.floor",
                        sleepSurface = "floor" },
                },
            },
            componentLimits = {
                ["sleep.bed"] = { kind = "anchor", minCount = 0, maxCount = 14,
                    fixedTileCount = 2, usesWorldObjectFootprint = true,
                    legacy = true },
            },
            activityLimits = { sleep = { maxConcurrent = 14 } },
        },
    },
}

Definitions.Register(definition)
if Definitions.RegisterAlias then
    Definitions.RegisterAlias("barracks", "bedroom")
end

return Definitions
