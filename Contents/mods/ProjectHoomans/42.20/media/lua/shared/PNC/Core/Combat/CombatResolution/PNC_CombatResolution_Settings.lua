local Resolution = PNC.CombatResolution
local function enabled(accessor, fallback)
    local settings = PNC.Sandbox
    if settings and type(settings[accessor]) == "function" then
        return settings[accessor]() == true
    end
    return fallback == true
end

function Resolution.IsWeaponDamageEnabled()
    return enabled("NPCWeaponDamageEnabled", true)
end

function Resolution.IsAmmoConsumptionEnabled()
    return enabled("NPCAmmoConsumptionEnabled", false)
end

function Resolution.IsWeaponConditionEnabled()
    return enabled("NPCWeaponConditionLossEnabled", false)
end

function Resolution.ArePlayerWoundsEnabled()
    return enabled("NPCPlayerWoundsEnabled", true)
end

return Resolution
