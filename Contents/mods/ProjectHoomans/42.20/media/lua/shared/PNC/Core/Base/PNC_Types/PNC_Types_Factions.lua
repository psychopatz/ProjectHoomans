local Types = PNC.Types

function Types.NormalizeAttackType(value, weaponMode)
    local Const = PNC.Const
    local auto = Const.ATTACK_TYPE_AUTO or "auto"
    local melee = Const.ATTACK_TYPE_MELEE or "melee"
    local ranged = Const.ATTACK_TYPE_RANGED or "ranged"
    local none = Const.ATTACK_TYPE_NONE or "none"
    value = string.lower(tostring(value or ""))
    if value == auto or value == melee or value == ranged or value == none then
        return value
    end
    return auto
end

function Types.NormalizeFaction(value)
    local faction = string.lower(tostring(value or "colonist"))
    if faction == "hostile" or faction == "neutral"
        or faction == "colonist"
    then
        return faction
    end
    if faction == "enemy" or faction == "bandit" then return "hostile" end
    if faction == "companion" or faction == "friendly" or faction == "ally"
        or faction == "survivor"
    then
        return "colonist"
    end
    return "colonist"
end

function Types.IsColonist(value)
    local faction = type(value) == "table" and value.faction or value
    return Types.NormalizeFaction(faction) == "colonist"
end

function Types.DefaultHostility(faction)
    faction = Types.NormalizeFaction(faction)
    if faction == "hostile" then
        return { mode = "hostile_any_player", attackPlayers = true,
            attackNPCs = true, attackZombies = true }
    end
    if faction == "neutral" then
        return { mode = "neutral", attackPlayers = false,
            attackNPCs = true, attackZombies = false }
    end
    return { mode = "defend_owner", attackPlayers = false,
        attackNPCs = true, attackZombies = true }
end

function Types.NormalizeHostility(faction, value)
    local source = type(value) == "table" and value or {}
    local defaults = Types.DefaultHostility(faction)
    local normalized = {
        mode = tostring(source.mode or defaults.mode),
        attackPlayers = source.attackPlayers == nil
            and defaults.attackPlayers or source.attackPlayers == true,
        attackNPCs = source.attackNPCs == nil
            and defaults.attackNPCs or source.attackNPCs == true,
        attackZombies = source.attackZombies == nil
            and defaults.attackZombies or source.attackZombies == true,
    }
    if Types.NormalizeFaction(faction) == "neutral" then
        normalized.attackNPCs = true
    end
    return normalized
end

return Types
