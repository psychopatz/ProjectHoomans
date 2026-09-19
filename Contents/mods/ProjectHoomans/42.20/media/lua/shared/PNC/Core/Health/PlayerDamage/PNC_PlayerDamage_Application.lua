-- Authoritative application of an already-admitted player hit.

PNC = PNC or {}
PNC.PlayerDamage = PNC.PlayerDamage or {}
PNC.PlayerDamage.Internal = PNC.PlayerDamage.Internal or {}

local PlayerDamage = PNC.PlayerDamage
local Internal = PlayerDamage.Internal
local Runtime = Internal.Runtime
local Core = PNC.Core
local Health = PNC.Health
local Network = PNC.Network

function PlayerDamage.Apply(record, zombie, attacker, weapon,
    reportedDamage, source)
    local amount
    local applied
    local usedCombatService = false
    if not record or not zombie then
        return false, "missing_target"
    end
    if not Core or type(Core.IsAuthority) ~= "function"
        or not Core.IsAuthority()
    then
        return false, "not_authority"
    end
    if not PlayerDamage.CanDamageRecord(record, attacker) then
        Runtime.RestoreEngineBuffer(zombie, record)
        if PlayerDamage.IsFriendlyOwner(record, attacker)
            and PNC.LiveBodyControl
            and PNC.LiveBodyControl.RecoverGroundedBody
        then
            PNC.LiveBodyControl.RecoverGroundedBody(
                record,
                zombie,
                "friendly_owner_hit"
            )
        end
        return false, "colonist_protected"
    end
    amount = PlayerDamage.ScaleDamage(reportedDamage, weapon)
    if amount <= 0 then
        Runtime.RestoreEngineBuffer(zombie, record)
        return false, "invalid_damage"
    end
    if PNC.CombatResolution and PNC.CombatResolution.ApplyTargetDamage then
        usedCombatService = true
        applied = PNC.CombatResolution.ApplyTargetDamage(nil, attacker, {
            kind = "npc",
            id = record.id,
        }, {
            damage = amount,
            attackType = Runtime.IsRangedWeapon(weapon)
                and "ranged" or "melee",
            attackKind = tostring(source or "player_weapon"),
            attackerKind = "player",
            attackerOnlineID = attacker and attacker.getOnlineID
                and attacker:getOnlineID() or nil,
            attackerUsername = attacker and attacker.getUsername
                and attacker:getUsername() or nil,
            weaponItem = weapon,
            weaponFullType = Runtime.GetFullType(weapon),
            x = attacker and attacker.getX and attacker:getX() or nil,
            y = attacker and attacker.getY and attacker:getY() or nil,
            z = attacker and attacker.getZ and attacker:getZ() or nil,
        })
    else
        applied = Health.ApplyDamage(record, zombie, {
            amount = amount,
            type = tostring(source or "player_weapon"),
            attackerKind = "player",
            attackerOnlineID = attacker and attacker.getOnlineID
                and attacker:getOnlineID() or nil,
            attackerUsername = attacker and attacker.getUsername
                and attacker:getUsername() or nil,
            weaponFullType = Runtime.GetFullType(weapon),
        }) == true
    end
    Runtime.RestoreEngineBuffer(zombie, record)
    if applied
        and PNC.Factions
        and PNC.Factions.OnPlayerAggression
    then
        local at = getGameTime and getGameTime()
            and getGameTime().getWorldAgeHours
            and getGameTime():getWorldAgeHours() or 0
        PNC.Factions.OnPlayerAggression(
            attacker,
            record,
            at,
            {
                killed = record.alive == false,
                severe = (tonumber(amount) or 0)
                    >= (
                        PNC.FactionBalance
                        and PNC.FactionBalance.Get(
                            "severeAttackDamageThreshold"
                        ) or 25
                    ),
                damage = tonumber(amount) or 0,
                callback = "player_weapon_hit",
            }
        )
    end
    if applied
        and PNC.SocialEventHooksInternal
        and PNC.SocialEventHooksInternal.RecordPlayerDamagedNPC
    then
        pcall(
            PNC.SocialEventHooksInternal.RecordPlayerDamagedNPC,
            attacker,
            record,
            {
                amount = amount,
                damage = amount,
                attackType = Runtime.IsRangedWeapon(weapon)
                    and "ranged" or "melee",
                attackKind = tostring(source or "player_weapon"),
                source = source,
            }
        )
    end
    if applied and not usedCombatService and Network and Network.BroadcastRecord then
        Network.BroadcastRecord(record, "player_damage")
    end
    return applied, applied and "damaged" or "damage_rejected"
end
