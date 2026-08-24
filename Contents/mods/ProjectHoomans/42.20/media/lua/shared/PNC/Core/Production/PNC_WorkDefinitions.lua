PNC = PNC or {}
PNC.WorkDefinitions = PNC.WorkDefinitions or {}

local Definitions = PNC.WorkDefinitions
Definitions.OPERATION = {
    RESEARCH = "RESEARCH", CRAFT = "CRAFT", DISASSEMBLE = "DISASSEMBLE",
    CONSTRUCT = "CONSTRUCT", RECONSTRUCT = "RECONSTRUCT",
    DECONSTRUCT = "DECONSTRUCT",
    BUILD_OBJECT = "BUILD_OBJECT", READ_BOOK = "READ_BOOK",
}
Definitions.STATUS = {
    QUEUED = "QUEUED", WAITING_FOR_WORKER = "WAITING_FOR_WORKER",
    CLAIMED = "CLAIMED", TRAVEL_TO_STOCKPILE = "TRAVEL_TO_STOCKPILE",
    TRAVEL_TO_STATION = "TRAVEL_TO_STATION",
    WORKING = "WORKING", WAITING_RESOURCE = "WAITING_RESOURCE",
    PAUSED = "PAUSED", BLOCKED = "BLOCKED", CANCELLING = "CANCELLING",
    CANCELLED = "CANCELLED", COMPLETED = "COMPLETED",
    FAILED = "FAILED",
}
Definitions.BALANCE = {
    baseRatePerSecond = 1,
    minSkillFactor = 1,
    skillBonusPerLevel = 0.08,
    maxElapsedSeconds = 10,
    schedulerCadenceMs = 1000,
    maxOrdersPerPass = 16,
    salvageBaseFraction = 0.35,
    salvageSkillFractionPerLevel = 0.025,
    salvageMaximumFraction = 0.65,
}
Definitions.JOB_BY_OPERATION = {
    RESEARCH = "Researcher",
    READ_BOOK = "Researcher",
    CRAFT = "WorkshopWorker",
    DISASSEMBLE = "WorkshopWorker",
    CONSTRUCT = "Constructor",
    RECONSTRUCT = "Constructor",
    DECONSTRUCT = "Constructor",
    BUILD_OBJECT = "Constructor",
}
Definitions.CAPABILITY_BY_OPERATION = {
    RESEARCH = "work.research",
    CRAFT = "work.craft",
    -- Salvaging remains its own work type/operation, but it uses the same
    -- physical crafting station as CRAFT.  Keeping this mapping here makes
    -- the shared station explicit for both assignment and presentation.
    DISASSEMBLE = "work.craft",
    READ_BOOK = "work.research",
}
Definitions.STATIONS = {
    workshop = {
        id = "workshop",
        facilityId = "workshop",
        capability = "work.craft",
        role = "work.craft",
        legacyRoles = { "work.disassemble" },
        labelKey = "UI_PNC_Workshop_CraftingStation",
    },
}
Definitions.STATION_BY_OPERATION = {
    CRAFT = "workshop",
    DISASSEMBLE = "workshop",
}

function Definitions.GetStation(operation)
    local id = Definitions.STATION_BY_OPERATION[tostring(operation or "")]
    return id and Definitions.STATIONS[id] or nil
end

Definitions.COLONY_JOBS = { "Constructor", "Researcher", "WorkshopWorker", "Farmer" }

function Definitions.WorkRate(worker, requirements, facilityEfficiency, condition)
    local highestBonus = 0
    for index = 1, #(requirements or {}) do
        local requirement = requirements[index]
        local level = PNC.Skills and PNC.Skills.GetLevel
            and PNC.Skills.GetLevel(worker, requirement.skillId) or 0
        if level < (tonumber(requirement.level) or 0) then
            return 0, "SKILL_TOO_LOW"
        end
        highestBonus = math.max(highestBonus,
            level - (tonumber(requirement.level) or 0))
    end
    local skillFactor = Definitions.BALANCE.minSkillFactor
        + highestBonus * Definitions.BALANCE.skillBonusPerLevel
    return Definitions.BALANCE.baseRatePerSecond * skillFactor
        * math.max(0, tonumber(facilityEfficiency) or 1)
        * math.max(0, tonumber(condition) or 1)
end

function Definitions.SalvageFraction(worker, requirements)
    local highest = 0
    for index = 1, #(requirements or {}) do
        local requirement = requirements[index]
        highest = math.max(highest, PNC.Skills and PNC.Skills.GetLevel
            and PNC.Skills.GetLevel(worker, requirement.skillId) or 0)
    end
    return math.min(Definitions.BALANCE.salvageMaximumFraction,
        Definitions.BALANCE.salvageBaseFraction
            + highest * Definitions.BALANCE.salvageSkillFractionPerLevel)
end

return Definitions
