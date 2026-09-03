PNC = PNC or {}
PNC.WorkDefinitions = PNC.WorkDefinitions or {}

local Definitions = PNC.WorkDefinitions

Definitions.COLONY_JOBS = {
    "Constructor", "Researcher", "WorkshopWorker", "Farmer",
    "Fishing", "Lumber", "Provisioner", "CorpseHaul", "MedicalCare",
}

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
