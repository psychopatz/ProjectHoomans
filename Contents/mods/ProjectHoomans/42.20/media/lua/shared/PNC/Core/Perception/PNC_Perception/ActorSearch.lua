PNC = PNC or {}
PNC.Perception = PNC.Perception or {}
PNC.Perception.Internal = PNC.Perception.Internal or {}

local Perception = PNC.Perception
local Internal = Perception.Internal
local Core = PNC.Core
local Const = PNC.Const
local Spatial = PNC.SpatialIndex
local Registry = PNC.Registry

function Perception.FindNearestEnemyPlayer(record, radius)
    radius = tonumber(radius) or Const.ZOMBIE_TARGET_RADIUS
    local players = Spatial.QueryPlayers(record.x, record.y, radius)
    local best = nil
    local i
    local player
    local distSq
    local visible
    local visibilityKind
    local candidate

    for i = 1, #players do
        player = players[i]
        visible = false
        visibilityKind = nil
        if player then
            visible, visibilityKind = Perception.CanSeeWorldObject(record, player)
        end
        local factionEnemy = not PNC.Factions
            or not PNC.Factions.CanNPCTargetPlayer
            or PNC.Factions.CanNPCTargetPlayer(
                record,
                player
            )
        if player and player:isAlive()
            and factionEnemy
            and math.abs(player:getZ() - record.z) < 1
            and visible
        then
            distSq = Core.DistanceSq(record.x, record.y, player:getX(), player:getY())
            if distSq <= (radius * radius) then
                candidate = {
                    kind = "player",
                    player = player,
                    onlineID = player:getOnlineID(),
                    username = player:getUsername(),
                    x = player:getX(),
                    y = player:getY(),
                    z = player:getZ(),
                    distSq = distSq,
                    visible = true,
                    visibilityKind = visibilityKind,
                    lastSeenAt = Core.Now(),
                }
                candidate.threatening = Perception.IsTargetThreatening(record, candidate)
                best = Internal.PickNearest(best, candidate)
            end
        end
    end
    return best
end

function Perception.FindNearestEnemyNPC(record, radius)
    radius = tonumber(radius) or Const.ZOMBIE_TARGET_RADIUS
    local npcs = Spatial.QueryNPCs(record.x, record.y, radius)
    local best = nil
    local i
    local target
    local targetZombie
    local distSq
    local visible
    local visibilityKind
    local candidate

    for i = 1, #npcs do
        target = npcs[i]
        targetZombie = target and Registry and Registry.GetLiveZombie and Registry.GetLiveZombie(target.id) or nil
        visible = false
        visibilityKind = nil
        if targetZombie then
            visible, visibilityKind = Perception.CanSeeWorldObject(record, targetZombie)
        end
        if target and target.alive ~= false and targetZombie and Internal.IsRecordEnemy(record, target) and math.abs(target.z - record.z) < 1
            and visible
        then
            distSq = Core.DistanceSq(record.x, record.y, target.x, target.y)
            if distSq <= (radius * radius) then
                candidate = {
                    kind = "npc",
                    id = target.id,
                    x = target.x,
                    y = target.y,
                    z = target.z,
                    distSq = distSq,
                    visible = true,
                    visibilityKind = visibilityKind,
                    lastSeenAt = Core.Now(),
                }
                candidate.threatening = Perception.IsTargetThreatening(record, candidate)
                best = Internal.PickNearest(best, candidate)
            end
        end
    end
    return best
end
