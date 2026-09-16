-- Generic inbound damage bridge for managed Hoomans actors.
--
-- Foreign mods call this capability with their own attacker object and stable
-- provider identity. The Hoomans wound/health model remains authoritative;
-- the foreign mod never calls IsoZombie:Hit on a managed body.

PNC = PNC or {}
PNC.Compatibility = PNC.Compatibility or {}
PNC.Compatibility.IncomingDamage =
    PNC.Compatibility.IncomingDamage or {}

local IncomingDamage = PNC.Compatibility.IncomingDamage

local function targetRecord(target, context)
    local modData
    local id
    if context and context.record then return context.record end
    if not target or not target.getModData then return nil end
    modData = target:getModData()
    id = modData and modData.PNC_UUID or nil
    if not id then return nil end
    return PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(id) or nil
end

local function attackerCoordinate(attacker, method, fallback)
    if attacker and attacker[method] then
        local ok, value = pcall(attacker[method], attacker)
        if ok and value ~= nil then return value end
    end
    return fallback
end

function IncomingDamage.Apply(context)
    local target
    local record
    local amount
    local attacker
    local wounds
    local applied
    local result
    local ok
    context = type(context) == "table" and context or {}
    target = context.target or context.victim
    if not target then return false, "incoming_target_missing" end
    if PNC.Compatibility.ActorOwnership
        and PNC.Compatibility.ActorOwnership.IsHoomansOwned
        and not PNC.Compatibility.ActorOwnership.IsHoomansOwned(target)
    then
        return false, "incoming_target_not_hoomans_owned"
    end
    record = targetRecord(target, context)
    if not record or record.alive == false then
        return false, "incoming_record_unavailable"
    end
    if target.isDead and target:isDead() then
        return false, "incoming_target_dead"
    end
    amount = tonumber(context.amount or context.damage) or 0
    if amount <= 0 then return false, "incoming_damage_invalid" end
    wounds = PNC.NPCWounds
    if not wounds or type(wounds.ApplyCombatDamage) ~= "function" then
        return false, "incoming_damage_pipeline_unavailable"
    end
    attacker = context.attacker or context.attackerBody
    ok, applied, result = pcall(
        wounds.ApplyCombatDamage,
        record,
        target,
        {
            amount = amount,
            partId = context.partId,
            woundType = context.woundType or "laceration",
            type = context.type or "foreign_combat_damage",
            attackerKind = context.attackerKind or "foreign_npc",
            attackerProvider = context.attackerProvider or context.provider,
            attackerID = context.attackerID,
            attackerOnlineID = context.attackerOnlineID,
            attackerUsername = context.attackerUsername,
            weaponFullType = context.weaponFullType,
            x = attackerCoordinate(attacker, "getX", context.attackerX or record.x),
            y = attackerCoordinate(attacker, "getY", context.attackerY or record.y),
            z = attackerCoordinate(attacker, "getZ", context.attackerZ or record.z),
        }
    )
    if not ok then return false, "incoming_damage_pipeline_error" end
    if applied ~= true then
        return false, result and result.outcome or "incoming_damage_rejected"
    end
    return true, result
end

return IncomingDamage
