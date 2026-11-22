-- Health, zombie damage, clothing defense, and Knox transmission sandbox accessors.
local Settings = PNC.Sandbox
if not Settings then return {} end

local function projectVars()
    return SandboxVars and SandboxVars.ProjectHoomans or nil
end

local function loreVars()
    return SandboxVars and SandboxVars.ZombieLore or nil
end

local function readLoreEnum(loreField, optionName, fallback)
    local vars = loreVars()
    local mode = vars and tonumber(vars[loreField]) or nil
    if mode == nil and type(getSandboxOptions) == "function" then
        local opts = getSandboxOptions()
        local lore = opts and (opts.getLore and opts:getLore() or opts.lore) or nil
        local optObj = lore and lore[loreField] or nil
        if optObj and optObj.getValue then
            mode = tonumber(optObj:getValue())
        elseif opts and type(opts.getOptionByName) == "function" then
            local opt = opts:getOptionByName(optionName)
            if opt and type(opt.getValue) == "function" then
                mode = tonumber(opt:getValue())
            end
        end
    end
    return math.floor(tonumber(mode) or fallback)
end

function Settings.NPCZombieWoundChance()
    return Settings.GetNumber("NPCZombieWoundChance", 45, 0, 100)
end

function Settings.NPCZombieBiteChance()
    return Settings.GetNumber("NPCZombieBiteChance", 20, 0, 100)
end

function Settings.NPCZombieLacerationChance()
    return Settings.GetNumber("NPCZombieLacerationChance", 30, 0, 100)
end

function Settings.NPCZombieDamageModelEnabled()
    return Settings.GetBoolean("NPCZombieDamageModel", true)
end

function Settings.NPCZombieDamageStaminaStartRatio()
    return Settings.GetNumber("NPCZombieDamageStaminaStartRatio", 0.30, 0, 1)
end

function Settings.NPCZombieDamageBaseChance()
    return Settings.GetNumber("NPCZombieDamageBaseChance", 0, 0, 100)
end

function Settings.NPCZombieDamageHitRadius()
    return Settings.GetNumber("NPCZombieDamageHitRadius", 2.2, 0.1, 6)
end

function Settings.NPCZombieDamageCrowdChancePerExtra()
    return Settings.GetNumber("NPCZombieDamageCrowdChancePerExtra", 5, 0, 100)
end

function Settings.NPCZombieDamageCrowdEscalation()
    return Settings.GetNumber("NPCZombieDamageCrowdEscalation", 2, 0, 100)
end

function Settings.NPCZombieDamageCrowdChanceCap()
    return Settings.GetNumber("NPCZombieDamageCrowdChanceCap", 100, 0, 100)
end

function Settings.NPCZombieDamageMinimumSkillMitigation()
    return Settings.GetNumber("NPCZombieDamageMinimumSkillMitigation", 15, 0, 100)
end

function Settings.NPCZombieDamageFitnessMitigationScale()
    return Settings.GetNumber("NPCZombieDamageFitnessMitigationScale", 45, 0, 100)
end

function Settings.NPCZombieDamageMaximumSkillMitigation()
    return Settings.GetNumber("NPCZombieDamageMaximumSkillMitigation", 60, 0, 100)
end

function Settings.NPCZombieClothingConditionExponent()
    return Settings.GetNumber("NPCZombieClothingConditionExponent", 1.15, 0.1, 3)
end

function Settings.NPCZombieClothingBlockMultiplier()
    return Settings.GetNumber("NPCZombieClothingBlockMultiplier", 1, 0, 2)
end

function Settings.NPCZombieClothingDowngradeLaceration()
    return Settings.GetNumber("NPCZombieClothingDowngradeLaceration", 25, 0, 100)
end

function Settings.NPCZombieClothingDowngradeScratch()
    return Settings.GetNumber("NPCZombieClothingDowngradeScratch", 60, 0, 100)
end

function Settings.NPCZombieClothingSafeDurabilityLoss()
    return Settings.GetNumber("NPCZombieClothingSafeDurabilityLoss", 1, 0, 100)
end

function Settings.NPCZombieClothingPenetratingDurabilityLoss()
    return Settings.GetNumber("NPCZombieClothingPenetratingDurabilityLoss", 2, 0, 100)
end

function Settings.NPCZombieInfectionChance()
    local vars = projectVars()
    if vars and vars.NPCZombieInfectionChance ~= nil then
        return Settings.GetNumber("NPCZombieInfectionChance", 100, 0, 100)
    end
    if vars and vars.NPCZombieInfection ~= nil then
        return vars.NPCZombieInfection == true and 100 or 0
    end
    return 100
end

function Settings.NPCZombieInfectionEnabled()
    return Settings.NPCZombieInfectionChance() > 0
end

-- Build 42 ZombieLore.Transmission: 1=Blood+Saliva, 2=Saliva Only, 3=Everyone's Infected, 4=None
function Settings.ZombieTransmissionMode()
    return readLoreEnum("Transmission", "ZombieLore.Transmission", 1)
end

-- Build 42 ZombieLore.Mortality: 1..6=lethal timings, 7=Never (non-lethal fake infection)
function Settings.ZombieMortalityMode()
    return readLoreEnum("Mortality", "ZombieLore.Mortality", 5)
end

function Settings.IsEveryoneInfectedMode()
    return Settings.ZombieTransmissionMode() == 3
end

function Settings.IsZombieSalivaTransmissible()
    if not Settings.NPCZombieInfectionEnabled() then return false end
    local vars = projectVars()
    if vars and vars.SalivaTransmission == false then return false end
    return Settings.ZombieTransmissionMode() ~= 4
end

-- Exact BodyPart.java:685-837 rules:
-- Mode 1 (Blood+Saliva) or 3 (Everyone's Infected): bite 100%, laceration 25%, scratch 7%.
-- Mode 2 (Saliva Only): bite 100%, laceration 0%, scratch 0%.
-- Mode 4 (None): 0% for all wounds.
local VANILLA_ZOMBIE_KNOX_BASE = { bite = 100, laceration = 25, scratch = 7 }

function Settings.CanZombieWoundTransmitKnox(woundType)
    if not Settings.NPCZombieInfectionEnabled() then return false end
    local wType = tostring(woundType or "")
    local mode = Settings.ZombieTransmissionMode()
    if mode == 4 then return false end
    local vars = projectVars()
    if wType == "bite" then
        return not (vars and vars.SalivaTransmission == false)
    end
    if mode == 2 then return false end
    if mode == 1 or mode == 3 then
        return wType == "laceration" or wType == "scratch"
    end
    return false
end

function Settings.GetZombieWoundKnoxChance(woundType)
    local wType = tostring(woundType or "")
    if not Settings.CanZombieWoundTransmitKnox(wType) then return 0 end
    local base = VANILLA_ZOMBIE_KNOX_BASE[wType] or 0
    if base <= 0 then return 0 end
    return math.max(0, math.min(100, base * (Settings.NPCZombieInfectionChance() / 100)))
end

function Settings.NPCInfectionMortalityHours()
    return Settings.GetNumber("NPCInfectionMortalityHours", 48, 1, 168)
end

function Settings.NPCReanimationSeconds()
    return Settings.GetNumber("NPCReanimationSeconds", 3, 1, 60)
end

return Settings
