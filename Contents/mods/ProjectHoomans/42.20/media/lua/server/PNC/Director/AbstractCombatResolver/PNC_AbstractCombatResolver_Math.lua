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

function H.Unit(seed, salt) return PNC.AbstractScavengeResolver.Unit(seed, salt) end
function H.Alive(group) return #(group.memberIds or {}) end

function H.Environment(location)
    return Config.CombatResolution.ENVIRONMENT[location.type]
        or Config.CombatResolution.ENVIRONMENT.POI
end

function H.Values(profile, morale, env, seed, side, round)
    local variance = 1 + (H.Unit(seed, side .. ":" .. round) * 2 - 1)
        * Config.CombatResolution.VARIANCE
    local offense = ((profile.overallPower or 0) * 0.78
        + (profile.rangedPower or 0) * 4 * env.ranged) * (0.55 + morale * 0.45) * variance
    local defense = ((profile.defense or 0) * 5 + (profile.manpower or 0) * 4
        + (profile.condition or 0) * 8 + 5) * env.defense
    return { offense = offense, defense = defense,
        mobility = (profile.mobility or 0) * env.mobility,
        morale = morale, variance = variance }
end

function H.SeverityCounts(pressure, maximum, seed, salt)
    local count = math.min(maximum, math.max(0, math.floor(pressure
        + H.Unit(seed, salt .. ":count"))))
    local output = { MINOR = 0, SERIOUS = 0, CRITICAL = 0, DEAD = 0 }
    for index = 1, count do
        local roll = H.Unit(seed, salt .. ":severity:" .. index)
        if pressure >= 1.7 and roll < math.min(0.16, pressure * 0.055) then
            output.DEAD = output.DEAD + 1
        elseif roll < 0.22 + math.min(0.18, pressure * 0.06) then
            output.CRITICAL = output.CRITICAL + 1
        elseif roll < 0.62 then output.SERIOUS = output.SERIOUS + 1
        else output.MINOR = output.MINOR + 1 end
    end
    return output, count
end

return Combat

