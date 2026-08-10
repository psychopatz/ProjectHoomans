local Resolution = PNC.CombatResolution
local Settings = PNC.Sandbox

local function sandbox()
    return SandboxVars and SandboxVars.ProjectHoomans or nil
end

local function enabled(key, fallback)
    if Settings and Settings.GetBoolean then
        return Settings.GetBoolean(key, fallback)
    end
    local vars = sandbox()
    if vars and vars[key] ~= nil then
        return vars[key] == true
    end
    return fallback == true
end

function Resolution.IsWeaponDamageEnabled()
    return enabled("EnableWeaponDamage", true)
end

function Resolution.IsAmmoConsumptionEnabled()
    return enabled("NPCAmmoConsumption", false)
end

function Resolution.IsWeaponConditionEnabled()
    return enabled("NPCWeaponConditionLoss", false)
end

function Resolution.ArePlayerWoundsEnabled()
    return enabled("NPCPlayerWounds", true)
end

return Resolution
