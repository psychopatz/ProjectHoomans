-- Central accessors for Project Hoomans sandbox rules.

PNC = PNC or {}
PNC.Sandbox = PNC.Sandbox or {}

local Settings = PNC.Sandbox
local Core = PNC.Core

local function projectVars()
    return SandboxVars and SandboxVars.ProjectHoomans or nil
end

function Settings.GetBoolean(key, fallback)
    local vars = projectVars()
    if vars and vars[key] ~= nil then
        return vars[key] == true
    end
    return fallback == true
end

function Settings.GetNumber(key, fallback, minimum, maximum)
    local vars = projectVars()
    local value = tonumber(vars and vars[key]) or tonumber(fallback) or 0
    if minimum ~= nil then value = math.max(tonumber(minimum) or value, value) end
    if maximum ~= nil then value = math.min(tonumber(maximum) or value, value) end
    return value
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

function Settings.NPCZombieInfectionEnabled()
    return Settings.GetBoolean("NPCZombieInfection", false)
end

function Settings.NPCInfectionMortalityHours()
    return Settings.GetNumber("NPCInfectionMortalityHours", 48, 1, 168)
end

function Settings.NPCReanimationHours()
    return Settings.GetNumber("NPCReanimationHours", 1, 0.05, 24)
end

function Settings.ZombiesTargetDownedNPC()
    return Settings.GetBoolean("ZombiesTargetDownedNPC", false)
end

function Settings.CanZombieTargetRecord(record, now)
    local health = record and record.health or nil
    local protectionUntil = tonumber(health and health.reviveProtectionUntil) or 0
    if protectionUntil > 0 then
        now = tonumber(now) or Core.Now()
        if now < protectionUntil then
            return false
        end
    end
    return not health
        or health.state ~= "incapacitated"
        or Settings.ZombiesTargetDownedNPC()
end
