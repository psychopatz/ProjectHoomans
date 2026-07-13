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
