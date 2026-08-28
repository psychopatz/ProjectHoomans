local Scene = PNC.ConversationScene
local Internal = Scene.Internal

local function recordTargetsConversation(candidate, record, player, zombie)
    local runtime = candidate and candidate.runtime or {}
    local live
    if Internal.SameTarget(runtime.target, player, zombie, record) then
        return true
    end
    live = candidate and PNC.Registry
        and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(candidate.id) or nil
    return Internal.EngineTargetsConversation(live, player, zombie)
end

local function zombieIsConversationEnemy(candidate, record, relationships)
    local candidateRecord = PNC.Registry
        and PNC.Registry.FindRecordByZombie
        and PNC.Registry.FindRecordByZombie(candidate) or nil
    if not candidateRecord then return true end
    return candidateRecord ~= record
        and relationships
        and relationships.AreNPCsEnemies
        and relationships.AreNPCsEnemies(record, candidateRecord)
        or false
end

local function runtimeHasThreat(record, player, ignoreTalkingNPC)
    local runtime = record and record.runtime or {}
    local health = record and record.health or {}
    local current = Internal.Now()
    local talkingTarget = Internal.TargetsPlayer(runtime.target, player)
    local hostileTalkingTarget = ignoreTalkingNPC == true
        and talkingTarget
    local passiveTalkingTarget = talkingTarget
        and runtime.attackAction == nil
        and current >= (tonumber(runtime.inCombatUntil) or 0)
    local ignoredTalkingTarget = hostileTalkingTarget or passiveTalkingTarget
    return (runtime.target ~= nil and not ignoredTalkingTarget)
        or (runtime.attackAction ~= nil and not hostileTalkingTarget)
        or (current < (tonumber(runtime.inCombatUntil) or 0)
            and not hostileTalkingTarget)
        or current < (tonumber(health.recentDamageUntil) or 0)
end

local function hasZombieThreat(
    spatial, relationships, record, zombie, player, radius
)
    local candidates
    local candidate
    local index
    if not spatial or not spatial.QueryZombies or not player then
        return false
    end
    candidates = spatial.QueryZombies(
        player:getX(), player:getY(), radius
    )
    for index = 1, #candidates do
        candidate = candidates[index]
        if candidate ~= zombie
            and Internal.IsAlive(candidate)
            and (
                Internal.DistanceSq(candidate, player) <= radius * radius
                or Internal.DistanceSq(candidate, zombie)
                    <= radius * radius
            )
            and zombieIsConversationEnemy(candidate, record, relationships)
            and Internal.EngineTargetsConversation(
                candidate, player, zombie
            )
        then
            return true
        end
    end
    return false
end

local function hasNPCThreat(
    spatial, relationships, record, zombie, player, radius
)
    local candidates
    local candidate
    local index
    if not spatial or not spatial.QueryNPCs or not record then
        return false
    end
    candidates = spatial.QueryNPCs(
        tonumber(record.x) or zombie and zombie:getX() or 0,
        tonumber(record.y) or zombie and zombie:getY() or 0,
        radius
    )
    for index = 1, #candidates do
        candidate = candidates[index]
        if candidate ~= record
            and candidate.alive ~= false
            and relationships
            and relationships.AreNPCsEnemies
            and relationships.AreNPCsEnemies(record, candidate)
            and recordTargetsConversation(
                candidate, record, player, zombie
            )
        then
            return true
        end
    end
    return false
end

function Scene.HasThreat(record, zombie, player, radius, options)
    local spatial
    local relationships
    options = type(options) == "table" and options or {}
    if runtimeHasThreat(record, player, options.ignoreTalkingNPC) then
        return true
    end
    radius = tonumber(radius) or Scene.DANGER_RADIUS
    spatial = PNC.SpatialIndex
    relationships = PNC.Relationships
    return hasZombieThreat(
        spatial, relationships, record, zombie, player, radius
    ) or hasNPCThreat(
        spatial, relationships, record, zombie, player, radius
    )
end
