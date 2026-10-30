-- Cold saved combat intent; no combat executor or engine bootstrap.
local Repository = {}

function Repository.NormalizeHostility(rawHostility, faction)
    if PNC.Types and PNC.Types.NormalizeHostility then
        return PNC.Types.NormalizeHostility(faction, rawHostility)
    end
    local source = type(rawHostility) == "table" and rawHostility or {}
    local hostile = tostring(faction or "") == "hostile"
    return { mode = tostring(source.mode or (hostile and "hostile_any_player" or "defend_owner")),
        attackPlayers = source.attackPlayers == nil and hostile or source.attackPlayers == true,
        attackNPCs = source.attackNPCs == nil and true or source.attackNPCs == true,
        attackZombies = source.attackZombies == nil and true or source.attackZombies == true }
end

function Repository.NormalizeAttackType(attackType, weaponMode)
    return PNC.Types and PNC.Types.NormalizeAttackType
        and PNC.Types.NormalizeAttackType(attackType, weaponMode)
        or tostring(attackType or weaponMode or "melee")
end

return Repository
