PNC = PNC or {}
local Wounds = PNC.NPCWounds
local Internal = Wounds.Internal
local Core = PNC.Core

function Internal.ResolveCombatWoundType(damageEvent)
    local rawRequested = tostring(damageEvent and damageEvent.woundType or "")
    local requested = Wounds.NormalizeWoundType
        and Wounds.NormalizeWoundType(rawRequested)
        or string.lower(rawRequested)
    local isRanged = damageEvent and tostring(damageEvent.attackType or "") == "ranged"
    if requested ~= "" and Internal.WoundStats[requested] then
        if isRanged and (requested == "scratch" or requested == "laceration") then return "bullet" end
        return requested
    end
    local resolver = PNC.CombatResolution and PNC.CombatResolution.ResolveWoundType
    if type(resolver) == "function" then
        local resolved = resolver(
            damageEvent and damageEvent.attackType,
            damageEvent and damageEvent.weaponItem,
            rawRequested,
            damageEvent and damageEvent.attackKind,
            damageEvent and damageEvent.weaponFullType
        )
        return (Wounds.NormalizeWoundType and Wounds.NormalizeWoundType(resolved)) or resolved
    end
    return isRanged and "bullet" or "scratch"
end

function Internal.NotifyWoundCallout(record, partId, wound, damage, now, extra)
    if type(record) ~= "table" or record.alive == false then return false end
    local health = record.health
    if type(health) == "table" and (health.state == "dead" or health.state == "incapacitated") then
        return false
    end
    local callouts = PNC.Semantics and PNC.Semantics.CombatTargetCallouts or nil
    if not callouts or type(callouts.OnNPCWoundReceived) ~= "function" then return false end
    return callouts.OnNPCWoundReceived(record, {
        partId = partId or (wound and wound.partId),
        woundType = wound and wound.type or (extra and extra.woundType),
        severity = wound and wound.severity,
        damage = tonumber(damage) or (extra and extra.damage) or 0,
        bleedingRate = wound and wound.bleedingRate or 0,
        bandaged = wound and wound.bandaged == true or false,
        stitched = wound and wound.stitched == true or false,
        splinted = wound and wound.splinted == true or false,
        zombieWound = wound and wound.zombieWound == true or false,
        attackerKind = extra and extra.attackerKind or nil,
        attackerID = extra and extra.attackerID or nil,
        attackType = extra and extra.attackType or nil,
    }, now or Core.Now())
end

return Wounds
