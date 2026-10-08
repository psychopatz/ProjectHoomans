-- Authoritative Bandits -> Hoomans damage ingress.
--
-- A multiplayer client may observe the Bandits hit loop, but it never gets to
-- mutate a managed Hoomans body. The server resolves both stable identities,
-- rechecks distance/ownership/relationship, and then commits the wound.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

local Router = PNC.ServerCommandRouter
local Const = PNC.Const
local Bridge = PNC.Compatibility
    and PNC.Compatibility.Bandits
    and PNC.Compatibility.Bandits.IncomingBridge

local function boundedNumber(value, minimum, maximum)
    value = tonumber(value)
    if not value then return nil end
    return math.max(minimum, math.min(maximum, value))
end

local function boundedString(value, maximum)
    if value == nil then return nil end
    value = tostring(value)
    if value == "" or #value > maximum then return nil end
    return value
end

local function distanceSq(x1, y1, x2, y2)
    local dx = (tonumber(x1) or 0) - (tonumber(x2) or 0)
    local dy = (tonumber(y1) or 0) - (tonumber(y2) or 0)
    return (dx * dx) + (dy * dy)
end

local function coordinate(body, methodName)
    if not body or type(body[methodName]) ~= "function" then return nil end
    local ok, value = pcall(body[methodName], body)
    return ok and tonumber(value) or nil
end

if not Router or type(Router.Register) ~= "function" or not Bridge then
    return
end

Router.Register(Const.CMD_BANDITS_INCOMING_DAMAGE, function(player, args)
    local target
    local attacker
    local targetX
    local targetY
    local targetZ
    local attackerX
    local attackerY
    local attackerZ
    local attackerID
    local targetID
    local amount
    local metadata
    local internal = PNC.Compatibility.Bandits.Internal

    args = type(args) == "table" and args or {}
    targetID = boundedString(args.npcID, 128)
    attackerID = boundedString(args.attackerID, 128)
    amount = boundedNumber(args.amount, 0.01, 100)
    if not targetID or not attackerID or not amount then return end

    target = PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(targetID) or nil
    if not target or type(target.isAlive) ~= "function"
        or not target:isAlive()
    then
        return
    end
    if not PNC.Compatibility.ActorOwnership
        or not PNC.Compatibility.ActorOwnership.IsHoomansOwned
        or not PNC.Compatibility.ActorOwnership.IsHoomansOwned(target)
    then
        return
    end

    if not internal or type(internal.GetBody) ~= "function" then return end
    attacker = internal.GetBody(attackerID)
    if not attacker then return end
    if args.attackerGeneration ~= nil
        and type(attacker.getPersistentOutfitID) == "function"
    then
        local generation = attacker:getPersistentOutfitID()
        if tostring(generation or "") ~= tostring(args.attackerGeneration) then
            return
        end
    end

    targetX = coordinate(target, "getX")
    targetY = coordinate(target, "getY")
    targetZ = coordinate(target, "getZ")
    attackerX = coordinate(attacker, "getX")
    attackerY = coordinate(attacker, "getY")
    attackerZ = coordinate(attacker, "getZ")
    if targetX == nil or targetY == nil
        or attackerX == nil or attackerY == nil
    then
        return
    end
    if distanceSq(targetX, targetY, attackerX, attackerY) > 64 then
        return
    end
    if targetZ ~= nil and attackerZ ~= nil
        and math.abs(targetZ - attackerZ) > 2
    then
        return
    end
    if player and player.getX and player.getY
        and distanceSq(targetX, targetY, player:getX(), player:getY()) > 4096
    then
        return
    end

    metadata = {
        attackType = boundedString(args.attackType, 32),
        attackKind = boundedString(args.attackKind, 64),
        damageClass = boundedString(args.damageClass, 32),
        woundType = boundedString(args.woundType, 32),
        type = boundedString(args.type, 96)
            or "bandits_combat_damage",
        weaponFullType = boundedString(args.weaponFullType, 128),
        attackerID = attackerID,
        attackerGeneration = args.attackerGeneration,
        attackerX = attackerX,
        attackerY = attackerY,
        attackerZ = attackerZ,
    }
    Bridge.ApplyAuthoritativeHit(
        attacker, nil, target, amount, metadata
    )
end)
