-- Shared context and identity helpers for the Bandits inbound bridge.

PNC = PNC or {}
PNC.Compatibility = PNC.Compatibility or {}
PNC.Compatibility.Bandits = PNC.Compatibility.Bandits or {}
local Bridge = PNC.Compatibility.Bandits.IncomingBridge
    or require "PNC/Core/Compatibility/Mods/Bandits/PNC_Bandits_IncomingBridge"
local Context = Bridge.IncomingContext or {}
Bridge.IncomingContext = Context
local DamageContext = PNC.Compatibility.DamageContext

function Context.SafeMethod(object, methodName, ...)
    local method
    local ok
    local value
    if not object then return nil end
    method = object[methodName]
    if type(method) ~= "function" then return nil end
    ok, value = pcall(method, object, ...)
    return ok and value or nil
end

function Context.IsHoomansBody(body)
    local ownership = PNC.Compatibility.ActorOwnership
    if not ownership or type(ownership.IsHoomansOwned) ~= "function" then
        return false
    end
    local ok, owned = pcall(ownership.IsHoomansOwned, body)
    return ok and owned == true
end

function Context.IsAlive(body)
    local value = Context.SafeMethod(body, "isAlive")
    if value == nil then
        value = not (Context.SafeMethod(body, "isDead") == true)
    end
    return value == true
end

function Context.HasAuthority()
    local core = PNC.Core
    if core and type(core.IsAuthority) == "function" then
        local ok, allowed = pcall(core.IsAuthority)
        return ok and allowed == true
    end
    return type(isServer) == "function" and isServer() == true
end

function Context.BodyRecord(body)
    local registry = PNC.Registry
    local data
    local id
    if not body or type(body.getModData) ~= "function" then return nil end
    local ok, value = pcall(body.getModData, body)
    if not ok or type(value) ~= "table" then return nil end
    data = value
    id = data.PNC_UUID
    if not id or not registry or type(registry.Get) ~= "function" then
        return nil
    end
    local recordOk, record = pcall(registry.Get, id)
    return recordOk and type(record) == "table" and record or nil
end

function Context.BodyID(body)
    if not body or type(body.getModData) ~= "function" then return nil end
    local ok, data = pcall(body.getModData, body)
    if not ok or type(data) ~= "table" or not data.PNC_UUID then
        return nil
    end
    return tostring(data.PNC_UUID)
end

function Context.AttackerID(attacker)
    local internal = PNC.Compatibility.Bandits.Internal
    if internal and type(internal.ActorID) == "function" then
        local ok, value = pcall(internal.ActorID, attacker)
        if ok and value ~= nil then return tostring(value) end
    end
    if BanditUtils and type(BanditUtils.GetCharacterID) == "function" then
        local ok, value = pcall(BanditUtils.GetCharacterID, attacker)
        if ok and value ~= nil then return tostring(value) end
    end
    return nil
end

function Context.AttackerGeneration(attacker)
    local value = Context.SafeMethod(attacker, "getPersistentOutfitID")
    return value ~= nil and tostring(value) or nil
end

function Context.Coordinate(body, methodName)
    local value = Context.SafeMethod(body, methodName)
    return value ~= nil and tonumber(value) or nil
end

function Context.CanAttack(shooter, victim)
    local relationships = PNC.Compatibility.Bandits.Relationships
    local target = Context.BodyRecord(victim)
    local attacker = { worldObject = shooter, body = shooter }
    local ok
    local allowed
    local reason

    if relationships and type(relationships.CanBanditAttackHooman) == "function" then
        ok, allowed, reason = pcall(
            relationships.CanBanditAttackHooman,
            { attacker = attacker, target = target }
        )
        if ok then return allowed == true, reason end
        return false, "bandit_relationship_error"
    end
    if BanditHoomansCompatibility
        and type(BanditHoomansCompatibility.CanBanditAttackHooman) == "function"
    then
        ok, allowed, reason = pcall(
            BanditHoomansCompatibility.CanBanditAttackHooman,
            shooter,
            victim
        )
        if ok then return allowed == true, reason end
    end
    return false, "bandit_relationship_unavailable"
end

function Context.IsRanged(item, fullType, attackType, attackKind, damageClass)
    if DamageContext and type(DamageContext.IsRanged) == "function" then
        return DamageContext.IsRanged(
            item, fullType, attackType, attackKind, damageClass
        ) == true
    end
    return tostring(attackType or "") == "ranged"
end

function Context.FullType(item, fallback)
    if fallback then return tostring(fallback) end
    if DamageContext and type(DamageContext.WeaponFullType) == "function" then
        return DamageContext.WeaponFullType(item)
    end
    local value = Context.SafeMethod(item, "getFullType")
    return value and tostring(value) or nil
end

function Context.MaxDamage(item)
    return tonumber(Context.SafeMethod(item, "getMaxDamage")) or 0
end

function Context.WeaponContext(shooter, item, victim, amount, metadata)
    local data = type(metadata) == "table" and metadata or {}
    local weaponFullType = Context.FullType(item, data.weaponFullType)
    local ranged = Context.IsRanged(
        item,
        weaponFullType,
        data.attackType,
        data.attackKind,
        data.damageClass
    )
    return {
        target = victim,
        victim = victim,
        attacker = shooter,
        amount = amount,
        type = data.type or "bandits_combat_damage",
        woundType = data.woundType
            or (ranged and "bullet" or "laceration"),
        attackType = data.attackType
            or (ranged and "ranged" or "melee"),
        attackKind = data.attackKind
            or (ranged and "bandits_firearm" or "bandits_melee"),
        damageClass = data.damageClass
            or (ranged and "firearm" or "melee"),
        weaponItem = item,
        weaponFullType = weaponFullType,
        attackerKind = data.attackerKind or "foreign_npc",
        attackerProvider = "Bandits",
        attackerID = data.attackerID or Context.AttackerID(shooter),
        attackerGeneration = data.attackerGeneration
            or Context.AttackerGeneration(shooter),
        attackerX = data.attackerX or Context.Coordinate(shooter, "getX"),
        attackerY = data.attackerY or Context.Coordinate(shooter, "getY"),
        attackerZ = data.attackerZ or Context.Coordinate(shooter, "getZ"),
    }
end

function Context.RequestPlayer()
    if type(getPlayer) == "function" then
        local ok, player = pcall(getPlayer)
        if ok and player then return player end
    end
    if type(getSpecificPlayer) == "function" then
        local ok, player = pcall(getSpecificPlayer, 0)
        if ok and player then return player end
    end
    return nil
end

return Context
