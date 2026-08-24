if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Combat = PNC.AbstractCombatResolver
local Config = PNC.DirectorConfig
local Store = PNC.AbstractWorldStore
local Profiles = PNC.AbstractCombatProfile
local Behavior = PNC.AbstractBehaviorProfile
local Casualties = PNC.AbstractCasualtyResolver
local Retreat = PNC.AbstractRetreatResolver
local Groups = PNC.AbstractGroups
local H = Combat.Internal

function H.SpendAmmo(group, profile, seed, salt)
    local available = math.max(0, tonumber(group.resources.ammo) or 0)
    local used = math.min(available, math.ceil((profile.rangedPower or 0)
        * Config.CombatResolution.AMMO_EXPENDITURE_SCALE
        * (0.8 + H.Unit(seed, salt) * 0.4)))
    if used > 0 then
        group.resources.ammo = available - used
        Groups.MarkCombatProfileDirty(group, "abstract_ammo_expenditure")
    end
    return used
end

function H.SpendMedical(group, applied)
    local requested = (applied.counts.SERIOUS or 0) + (applied.counts.CRITICAL or 0)
    local available = math.max(0, tonumber(group.resources.medical) or 0)
    local used = math.min(available, requested)
    group.resources.medical = available - used
    return used
end

function H.AccumulateCounts(target, source)
    for _, severity in ipairs({ "MINOR", "SERIOUS", "CRITICAL", "DEAD" }) do
        target[severity] = (target[severity] or 0) + (source[severity] or 0)
    end
end

return Combat

