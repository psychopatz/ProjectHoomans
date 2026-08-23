local Definitions = PNC.FacilityDefinitions
    or require "PNC/Core/Settlement/PNC_FacilityDefinitions/PNC_FacilityDefinitions_Core"

Definitions.Register({
    id = "research_facility",
    category = "technology",
    displayNameKey = "UI_PNC_Facility_Research",
    descriptionKey = "UI_PNC_Facility_ResearchDescription",
    iconPath = "media/ui/Facilities/BuildingMenu/researchCenter.png",
    buildCosts = {{ fullType = "Base.Money", amount = 1 }},
    buildWork = 120,
    reconstructWork = 75,
    deconstructWork = 70,
    allowMultipleRegions = false,
    levels = {
        [1] = {
            requiredHQLevel = 1,
            capabilities = { "work.research", "work.blueprint",
                "work.reverse" },
            componentLimits = {
                ["work.research"] = { kind = "anchor", minCount = 1,
                    maxCount = 1 },
                ["work.blueprint"] = { kind = "anchor", minCount = 1,
                    maxCount = 1 },
                ["work.reverse"] = { kind = "anchor", minCount = 1,
                    maxCount = 1 },
            },
            activityLimits = {
                ["work.research"] = { maxConcurrent = 1 },
                ["work.blueprint"] = { maxConcurrent = 1 },
                ["work.reverse"] = { maxConcurrent = 1 },
            },
            workstations = {
                research = { operation = "RESEARCH", capacity = 1,
                    role = "work.research", interactionAnchor = "research" },
                architect = { operation = "RESEARCH", capacity = 1,
                    role = "work.blueprint", interactionAnchor = "architect" },
                laboratory = { operation = "RESEARCH", capacity = 1,
                    role = "work.reverse", interactionAnchor = "laboratory" },
            },
        },
    },
})

Definitions.Register({
    id = "workshop",
    category = "production",
    displayNameKey = "UI_PNC_Facility_Workshop",
    descriptionKey = "UI_PNC_Facility_WorkshopDescription",
    iconPath = "media/ui/Facilities/BuildingMenu/workshop.png",
    buildCosts = {{ fullType = "Base.Money", amount = 1 }},
    buildWork = 140,
    reconstructWork = 90,
    deconstructWork = 80,
    requiredTechnology = "facility:workshop",
    allowMultipleRegions = false,
    levels = {
        [1] = {
            requiredHQLevel = 1,
            capabilities = { "work.craft", "work.disassemble" },
            componentLimits = {
                ["work.craft"] = { kind = "anchor", minCount = 1,
                    maxCount = 1 },
                ["work.disassemble"] = { kind = "anchor", minCount = 1,
                    maxCount = 1 },
            },
            activityLimits = {
                ["work.craft"] = { maxConcurrent = 1 },
                ["work.disassemble"] = { maxConcurrent = 1 },
            },
            workstations = {
                craft = { operation = "CRAFT", capacity = 1,
                    role = "work.craft", interactionAnchor = "craft" },
                disassemble = { operation = "DISASSEMBLE", capacity = 1,
                    role = "work.disassemble", interactionAnchor = "disassemble" },
            },
        },
    },
})

return Definitions
