-- Authoritative Necroa -> Hoomans damage ingress.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

local Router = PNC.ServerCommandRouter
local Const = PNC.Const

local function boundedNumber(value, minimum, maximum)
    value = tonumber(value)
    if not value then return nil end
    return math.max(minimum, math.min(maximum, value))
end

local function distanceSq(x1, y1, x2, y2)
    local dx = (tonumber(x1) or 0) - (tonumber(x2) or 0)
    local dy = (tonumber(y1) or 0) - (tonumber(y2) or 0)
    return (dx * dx) + (dy * dy)
end

Router.Register(Const.CMD_NECROA_INCOMING_DAMAGE, function(player, args)
    local id
    local amount
    local x
    local y
    local z
    local target
    local targetX
    local targetY
    local targetZ
    local incoming

    args = type(args) == "table" and args or {}
    id = tostring(args.npcID or "")
    if id == "" or string.len(id) > 128 then return end

    amount = boundedNumber(args.amount, 0.01, 40)
    x = boundedNumber(args.attackerX, -100000, 100000)
    y = boundedNumber(args.attackerY, -100000, 100000)
    z = boundedNumber(args.attackerZ, -100, 100)
    if not amount or x == nil or y == nil then return end

    target = PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(id) or nil
    if not target or not target.isAlive or not target:isAlive() then return end
    if not PNC.Compatibility.ActorOwnership.IsHoomansOwned(target) then
        return
    end

    targetX = target.getX and target:getX() or nil
    targetY = target.getY and target:getY() or nil
    targetZ = target.getZ and target:getZ() or nil
    if targetX == nil or targetY == nil then return end
    if z ~= nil and targetZ ~= nil and math.abs(z - targetZ) > 2 then
        return
    end
    if distanceSq(x, y, targetX, targetY) > 64 then return end

    if player and player.getX and player.getY
        and distanceSq(x, y, player:getX(), player:getY()) > 4096
    then
        return
    end

    incoming = PNC.Compatibility.IncomingDamage
    if not incoming or type(incoming.Apply) ~= "function" then return end
    incoming.Apply({
        target = target,
        amount = amount,
        type = tostring(args.type or "necroa_damage"),
        woundType = tostring(args.woundType or "burn"),
        attackerKind = "foreign_npc",
        attackerProvider = "Necroa",
        attackerX = x,
        attackerY = y,
        attackerZ = z,
    })
end)
