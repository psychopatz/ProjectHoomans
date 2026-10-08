-- Bandits inbound damage and multiplayer authority boundary.

PNC = PNC or {}
PNC.Compatibility = PNC.Compatibility or {}
PNC.Compatibility.Bandits = PNC.Compatibility.Bandits or {}
local Bridge = PNC.Compatibility.Bandits.IncomingBridge
    or require "PNC/Core/Compatibility/Mods/Bandits/PNC_Bandits_IncomingBridge"
local Context = Bridge.IncomingContext
    or require "PNC/Core/Compatibility/Mods/Bandits/PNC_Bandits_IncomingContext"

local function requestDamage(shooter, item, victim, amount, metadata)
    local const = PNC.Const or {}
    local player = Context.RequestPlayer()
    local id = Context.BodyID(victim)
    local attacker = Context.AttackerID(shooter)
    local weaponFullType = Context.FullType(
        item,
        metadata and metadata.weaponFullType
    )
    local hit = Context.WeaponContext(
        shooter, item, victim, amount, metadata
    )
    if type(isClient) ~= "function" or not isClient()
        or type(sendClientCommand) ~= "function"
        or not player or not id or not attacker
    then
        return false, "bandits_damage_authority_unavailable"
    end
    sendClientCommand(
        player,
        const.MODULE or "PNC",
        const.CMD_BANDITS_INCOMING_DAMAGE or "BanditsIncomingDamage",
        {
            npcID = id,
            attackerID = attacker,
            amount = math.min(100, math.max(0, tonumber(amount) or 0)),
            attackType = hit.attackType,
            attackKind = hit.attackKind,
            damageClass = hit.damageClass,
            woundType = hit.woundType,
            type = hit.type,
            weaponFullType = weaponFullType,
            attackerGeneration = hit.attackerGeneration,
            attackerX = hit.attackerX,
            attackerY = hit.attackerY,
            attackerZ = hit.attackerZ,
        }
    )
    Bridge.metrics.requests = (tonumber(Bridge.metrics.requests) or 0) + 1
    return true, "bandits_damage_request_sent"
end

function Bridge.ApplyAuthoritativeHit(shooter, item, victim, amount, metadata)
    local incoming = PNC.Compatibility.IncomingDamage
    local allowed
    local reason
    local hit
    local ok
    local applied
    local result

    if not Context.IsHoomansBody(victim) then
        return false, "bandits_target_not_hoomans_owned"
    end
    if not Context.HasAuthority() then
        return false, "bandits_damage_not_authority"
    end
    if not Context.IsAlive(victim) then return false, "bandits_target_dead" end
    allowed, reason = Context.CanAttack(shooter, victim)
    if not allowed then
        return false, reason or "bandits_target_not_allowed"
    end
    amount = tonumber(amount) or 0
    if amount <= 0 then return false, "bandits_damage_invalid" end
    if not incoming or type(incoming.Apply) ~= "function" then
        return false, "incoming_damage_pipeline_unavailable"
    end
    hit = Context.WeaponContext(shooter, item, victim, amount, metadata)
    ok, applied, result = pcall(incoming.Apply, hit)
    if not ok then
        Bridge.metrics.rejected = (tonumber(Bridge.metrics.rejected) or 0) + 1
        return false, "bandits_incoming_pipeline_error"
    end
    if applied ~= true then
        Bridge.metrics.rejected = (tonumber(Bridge.metrics.rejected) or 0) + 1
        return false, result or "bandits_damage_rejected"
    end
    if victim.setAttackedBy and shooter then
        pcall(victim.setAttackedBy, victim, shooter)
    end
    if PNC.Compatibility.Bandits.Flavor
        and type(PNC.Compatibility.Bandits.Flavor.Say) == "function"
    then
        pcall(PNC.Compatibility.Bandits.Flavor.Say,
            shooter, "HOOMANS_ATTACK")
        if victim.isDead and victim:isDead() then
            pcall(PNC.Compatibility.Bandits.Flavor.Say,
                shooter, "HOOMANS_DOWN", true)
        end
    end
    if BanditHoomansCompatibility
        and type(BanditHoomansCompatibility.RecordBanditAttack) == "function"
    then
        pcall(
            BanditHoomansCompatibility.RecordBanditAttack,
            victim, shooter, amount, item
        )
    end
    Bridge.metrics.routed = (tonumber(Bridge.metrics.routed) or 0) + 1
    return true, result or "bandits_damage_applied"
end

function Bridge.ApplyHit(shooter, item, victim, metadata)
    local data = type(metadata) == "table" and metadata or {}
    local full = Context.FullType(item, data.weaponFullType)
    local ranged = Context.IsRanged(
        item, full, data.attackType, data.attackKind, data.damageClass
    )
    local amount = tonumber(data.amount)
    local allowed
    local reason
    if not Context.IsHoomansBody(victim) then
        return false, "bandits_target_not_hoomans_owned"
    end
    allowed, reason = Context.CanAttack(shooter, victim)
    if not allowed then
        -- A client may not have Bandits' brain cache yet. Let the bounded
        -- request reach the server in that one indeterminate case; the
        -- authoritative path always rechecks the relationship.
        if Context.HasAuthority() or reason ~= "bandit_brain_unavailable" then
            Bridge.metrics.rejected = (tonumber(Bridge.metrics.rejected) or 0) + 1
            return false, reason or "bandits_target_not_allowed"
        end
    end
    if not amount or amount <= 0 then
        amount = Context.MaxDamage(item) * 2
    end
    if amount <= 0 then return false, "bandits_damage_invalid" end
    local hit = {
        amount = amount,
        attackType = data.attackType
            or (ranged and "ranged" or "melee"),
        attackKind = data.attackKind
            or (ranged and "bandits_firearm" or "bandits_melee"),
        damageClass = data.damageClass
            or (ranged and "firearm" or "melee"),
        woundType = data.woundType
            or (ranged and "bullet" or "laceration"),
        type = data.type or "bandits_combat_damage",
        weaponFullType = full,
    }
    if not Context.HasAuthority() then
        return requestDamage(shooter, item, victim, amount, hit)
    end
    return Bridge.ApplyAuthoritativeHit(
        shooter, item, victim, amount, hit
    )
end

return Bridge
