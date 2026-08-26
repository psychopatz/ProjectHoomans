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

function Types.NormalizeTacticalClass(value)
    local tacticalClass = string.lower(tostring(value or "colonist"))
    if tacticalClass == "hostile" or tacticalClass == "neutral"
        or tacticalClass == "colonist"
    then
        return tacticalClass
    end
    if tacticalClass == "enemy" or tacticalClass == "bandit" then
        return "hostile"
    end
    if tacticalClass == "companion" or tacticalClass == "friendly"
        or tacticalClass == "ally" or tacticalClass == "survivor"
    then
        return "colonist"
    end
    return "neutral"
end

-- Read both the canonical runtime field and the legacy input field.  This is
-- intentionally a reader boundary; canonical records only store
-- `tacticalClass`.
function Types.ResolveTacticalClass(value)
    if type(value) == "table" then
        return Types.NormalizeTacticalClass(
            value.tacticalClass ~= nil and value.tacticalClass
                or value.faction
        )
    end
    return Types.NormalizeTacticalClass(value)
end

function Types.IsColonist(value)
    return Types.ResolveTacticalClass(value) == "colonist"
end

function Types.DefaultHostility(tacticalClass)
    tacticalClass = Types.NormalizeTacticalClass(tacticalClass)
    if tacticalClass == "hostile" then
        return { mode = "hostile_any_player", attackPlayers = true,
            attackNPCs = true, attackZombies = true }
    end
    if tacticalClass == "neutral" then
        return { mode = "neutral", attackPlayers = false,
            attackNPCs = true, attackZombies = false }
    end
    return { mode = "defend_owner", attackPlayers = false,
        attackNPCs = true, attackZombies = true }
end

function Types.NormalizeHostility(tacticalClass, value)
    local source = type(value) == "table" and value or {}
    local defaults = Types.DefaultHostility(tacticalClass)
    local normalized = {
        mode = tostring(source.mode or defaults.mode),
        attackPlayers = source.attackPlayers == nil
            and defaults.attackPlayers or source.attackPlayers == true,
        attackNPCs = source.attackNPCs == nil
            and defaults.attackNPCs or source.attackNPCs == true,
        attackZombies = source.attackZombies == nil
            and defaults.attackZombies or source.attackZombies == true,
    }
    if Types.NormalizeTacticalClass(tacticalClass) == "neutral" then
        normalized.attackNPCs = true
    end
    return normalized
end

return Types
