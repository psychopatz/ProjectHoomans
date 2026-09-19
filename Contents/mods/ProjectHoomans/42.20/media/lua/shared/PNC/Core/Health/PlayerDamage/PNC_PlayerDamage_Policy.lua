-- Pure player-hit eligibility and reported-damage scaling policy.

PNC = PNC or {}
PNC.PlayerDamage = PNC.PlayerDamage or {}

local PlayerDamage = PNC.PlayerDamage
local Const = PNC.Const
local Types = PNC.Types

function PlayerDamage.CanDamageRecord(record, attacker)
    local tacticalClass
    if not record or record.alive == false then
        return false
    end
    if Types and Types.ResolveTacticalClass then
        tacticalClass = Types.ResolveTacticalClass(record)
    elseif Types and Types.NormalizeTacticalClass then
        tacticalClass = Types.NormalizeTacticalClass(record and record.tacticalClass)
    else
        tacticalClass = tostring(record and record.tacticalClass or "colonist")
    end
    if tacticalClass ~= (Const.TACTICAL_CLASS_COLONIST or "colonist") then
        return true
    end
    local organizationID = PNC.Factions
        and PNC.Factions.GetFactionID
        and PNC.Factions.GetFactionID(record)
        or nil
    local organization = organizationID
        and PNC.Factions
        and PNC.Factions.Get
        and PNC.Factions.Get(organizationID)
        or nil
    if not attacker or not organization
        or not organization.ownerPlayerKey
    then
        return false
    end
    local attackerFaction =
        PNC.Factions.GetPlayerDiplomacyFaction
        and PNC.Factions
            .GetPlayerDiplomacyFaction(attacker)
        or nil
    if not attackerFaction
        and PNC.Factions.EnsurePlayerDiplomacyFaction
    then
        local at = getGameTime and getGameTime()
            and getGameTime().getWorldAgeHours
            and getGameTime():getWorldAgeHours() or 0
        local ok
        ok, _, attackerFaction =
            PNC.Factions.EnsurePlayerDiplomacyFaction(
                attacker,
                { worldAgeHours = at }
            )
        if not ok then attackerFaction = nil end
    end
    return attackerFaction == nil
        or attackerFaction.id ~= organizationID
end

function PlayerDamage.IsFriendlyOwner(record, attacker)
    local onlineID
    local username
    if not record or not attacker then return false end
    onlineID = attacker.getOnlineID and tonumber(attacker:getOnlineID()) or nil
    username = attacker.getUsername
        and tostring(attacker:getUsername() or "") or ""
    if onlineID ~= nil and tonumber(record.ownerOnlineID) ~= nil
        and onlineID == tonumber(record.ownerOnlineID)
    then
        return true
    end
    return username ~= ""
        and tostring(record.ownerUsername or "") == username
end

function PlayerDamage.ScaleDamage(reportedDamage, weapon)
    local raw = tonumber(reportedDamage) or 0
    local weaponMaximum = weapon and weapon.getMaxDamage
        and tonumber(weapon:getMaxDamage()) or 1
    local weaponCap
    if raw <= 0 then
        return 0
    end
    weaponMaximum = math.max(0.25, weaponMaximum or 1)
    weaponCap = math.max(5, weaponMaximum * 20)
    return math.min(
        tonumber(Const.PLAYER_HIT_DAMAGE_MAX) or 50,
        weaponCap,
        math.max(1, raw * (tonumber(Const.PLAYER_HIT_DAMAGE_SCALE) or 10))
    )
end
