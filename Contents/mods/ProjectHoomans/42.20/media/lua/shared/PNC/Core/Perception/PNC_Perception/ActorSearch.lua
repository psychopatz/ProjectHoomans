PNC = PNC or {}
PNC.Perception = PNC.Perception or {}
PNC.Perception.Internal = PNC.Perception.Internal or {}

local Perception = PNC.Perception
local Internal = Perception.Internal
local Core = PNC.Core
local Const = PNC.Const
local Spatial = PNC.SpatialIndex
local Registry = PNC.Registry
local Relationships = PNC.Relationships

local function recordVisibleNPC(observer, target, candidate)
    local semantics = PNC.Semantics
    local evidence = semantics and semantics.CognitionEvidence or nil
    if evidence and type(evidence.RecordVisibleNPC) == "function" then
        evidence.RecordVisibleNPC(observer, target, candidate)
    end
end

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
        if target and target.alive ~= false and targetZombie
            and math.abs(target.z - record.z) < 1 and visible
        then
            distSq = Core.DistanceSq(record.x, record.y, target.x, target.y)
            if distSq <= (radius * radius) then
                recordVisibleNPC(record, target, {
                    distanceSq = distSq,
                    visibilityKind = visibilityKind,
                    source = "perception",
                })
                if Internal.IsRecordEnemy(record, target) then
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
                    candidate.threatening = Perception.IsTargetThreatening(
                        record, candidate)
                    best = Internal.PickNearest(best, candidate)
                end
            end
        end
    end
    return best
end

-- Direct NPC aggression is a self-defense signal, not ordinary NPC hunting.
-- Keep it independent of attackNPCs so passive survivors still respond to an
-- enemy that is already targeting them.
function Perception.FindImmediateNPCThreat(record, radius)
    local npcs
    local best = nil
    local limit
    local limitSq
    local i
    local target
    local targetBody
    local visible
    local visibilityKind
    local x
    local y
    local z
    local distSq
    local candidate

    if not record or not Spatial or not Spatial.QueryNPCs then
        return nil
    end
    limit = tonumber(radius)
        or math.max(
            tonumber(Const.TARGET_IMMEDIATE_THREAT_RADIUS) or 6,
            tonumber(Const.RANGED_RANGE) or 6
        )
    limit = math.max(1, limit)
    limitSq = limit * limit
    npcs = Spatial.QueryNPCs(record.x, record.y, limit)

    for i = 1, #(npcs or {}) do
        target = npcs[i]
        targetBody = target
            and Registry
            and Registry.GetLiveZombie
            and Registry.GetLiveZombie(target.id)
            or nil
        if target and tostring(target.id or "") ~= tostring(record.id or "")
            and target.alive ~= false
            and targetBody
        then
            x = targetBody:getX()
            y = targetBody:getY()
            z = targetBody:getZ()
            distSq = Core.DistanceSq(record.x, record.y, x, y)
            visible, visibilityKind = Perception.CanSeeWorldObject(
                record,
                targetBody
            )
            if distSq <= limitSq
                and math.abs(z - record.z) < 1
                and visible
            then
                recordVisibleNPC(record, target, {
                    distanceSq = distSq,
                    visibilityKind = visibilityKind,
                    source = "immediate_threat_perception",
                })
                if Relationships
                    and Relationships.AreNPCsEnemies
                    and Relationships.AreNPCsEnemies(
                        record,
                        target,
                        { ignoreAttackNPCPolicy = true }
                    )
                then
                    candidate = {
                        kind = "npc",
                        id = target.id,
                        x = x,
                        y = y,
                        z = z,
                        distSq = distSq,
                        visible = true,
                        visibilityKind = visibilityKind
                            or "immediate_npc_threat",
                        lastSeenAt = Core.Now(),
                    }
                    candidate.threatening = Perception.IsTargetThreatening
                        and Perception.IsTargetThreatening(record, candidate)
                        or false
                    if candidate.threatening == true then
                        candidate.immediateSelfDefense = true
                        best = Internal.PickNearest(best, candidate)
                    end
                end
            end
        end
    end
    return best
end
