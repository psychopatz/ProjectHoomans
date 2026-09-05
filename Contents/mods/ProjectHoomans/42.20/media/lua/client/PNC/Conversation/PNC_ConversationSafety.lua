-- Build 42.20 engine-facing conversation safety checks.
PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local Safety = PNC.Conversation.Safety or {}
PNC.Conversation.Safety = Safety

local function settingsValue(key, fallback)
    local settings = PsychopatzCore
        and PsychopatzCore.Conversation
        and PsychopatzCore.Conversation.Settings
        or nil
    return settings and settings.Get and settings.Get(key, fallback)
        or fallback
end

local function distanceSq(first, second)
    if not first or not second
        or not first.getX or not second.getX
    then
        return math.huge
    end
    if first.getZ and second.getZ
        and math.abs(first:getZ() - second:getZ()) >= 1
    then
        return math.huge
    end
    local dx = first:getX() - second:getX()
    local dy = first:getY() - second:getY()
    return dx * dx + dy * dy
end

local function alive(value)
    return value ~= nil
        and (not value.isDead or value:isDead() ~= true)
end

local function isNetworkClient()
    return isClient and isClient() == true
end

local function snapshotFor(spec)
    local context = spec and spec.context or {}
    local entry = context.entry or {}
    local snapshots = PNC.Network
        and PNC.Network.ClientState
        and PNC.Network.ClientState.snapshots
        or nil
    local npcID = tostring(spec and spec.npcID or entry.id or "")
    local current = snapshots and snapshots[npcID] or nil
    if type(current) == "table" then return current end
    return entry.snapshot
        or entry.source and entry.source.snapshot
end

local function snapshotHasPosition(snapshot)
    return type(snapshot) == "table"
        and snapshot.alive ~= false
        and tonumber(snapshot.x) ~= nil
        and tonumber(snapshot.y) ~= nil
        and tonumber(snapshot.z) ~= nil
end

local function allowsSnapshotConversation(spec, zombie)
    local context = spec and spec.context or {}
    return isNetworkClient()
        and context.nameplateConversation == true
        and not alive(zombie)
        and snapshotHasPosition(snapshotFor(spec))
end

local function snapshotDistanceSq(player, snapshot)
    if not player or not snapshot or not player.getX or not player.getY
        or not player.getZ
    then
        return math.huge
    end
    if math.floor(tonumber(snapshot.z) or 0)
        ~= math.floor(tonumber(player:getZ()) or 0)
    then
        return math.huge
    end
    local dx = tonumber(snapshot.x) - player:getX()
    local dy = tonumber(snapshot.y) - player:getY()
    return dx * dx + dy * dy
end

local function targetMatches(target, player, zombie, npcID)
    if not target then return false end
    if target == player or target == zombie then return true end
    if type(target) ~= "table" then return false end
    return tostring(target.id or "") == tostring(npcID or "")
        or target.player == player
        or target.worldObject == player
        or target.worldObject == zombie
end

local function targetTargetsPlayer(target, player)
    if not target or not player then return false end
    if target == player then return true end
    if type(target) ~= "table" then return false end
    return target.player == player or target.worldObject == player
end

local function engineTargetsConversation(candidate, player, zombie)
    if not candidate or not candidate.getTarget then return false end
    local target = candidate:getTarget()
    return targetMatches(target, player, zombie, nil)
end

function Safety.ResolveActors(spec)
    local context = spec and spec.context or {}
    local entry = context.entry or {}
    local npcID = tostring(spec and spec.npcID or entry.id or "")
    local registry = PNC.Registry
    local record = registry and registry.Get and registry.Get(npcID)
        or entry.record
    local zombie = registry and registry.GetLiveZombie
        and registry.GetLiveZombie(npcID)
        or entry.zombie
        or spec and spec.character
    local player = context.player
        or getSpecificPlayer and getSpecificPlayer(0)
        or getPlayer and getPlayer()
    return player, zombie, record, npcID
end

function Safety.GetMaximumDistance()
    return math.max(
        1,
        tonumber(settingsValue("maximumConversationDistance", 5.5)) or 5.5
    )
end

function Safety.GetDangerRadius()
    return math.max(
        1,
        tonumber(settingsValue("conversationDangerRadius", 8.0)) or 8.0
    )
end

local function managedCandidateIsEnemy(candidate, currentRecord, npcID)
    local registry = PNC.Registry
    local candidateRecord = registry
        and registry.FindRecordByZombie
        and registry.FindRecordByZombie(candidate)
        or nil
    if candidateRecord then
        if tostring(candidateRecord.id or "") == tostring(npcID) then
            return false, candidateRecord
        end
        local relationships = PNC.Relationships
        return relationships
            and relationships.AreNPCsEnemies
            and currentRecord
            and relationships.AreNPCsEnemies(
                currentRecord,
                candidateRecord
            )
            or false,
            candidateRecord
    end
    local modData = candidate.getModData
        and candidate:getModData() or nil
    local managedID = modData and modData.PNC_UUID or nil
    if not managedID then return true, nil end
    if tostring(managedID) == tostring(npcID) then return false, nil end
    local snapshots = PNC.Network
        and PNC.Network.ClientState
        and PNC.Network.ClientState.snapshots
        or {}
    local snapshot = snapshots[tostring(managedID)]
    return snapshot and type(snapshot.hostility) == "table"
        and snapshot.hostility.attackPlayers == true or false, nil
end

local function candidateTargetsConversation(
    candidate,
    candidateRecord,
    player,
    zombie,
    npcID
)
    local runtime = candidateRecord and candidateRecord.runtime or nil
    if runtime and targetMatches(
        runtime.target,
        player,
        zombie,
        npcID
    ) then
        return true
    end
    return engineTargetsConversation(candidate, player, zombie)
end

function Safety.HasDanger(
    player,
    zombie,
    record,
    npcID,
    radius,
    allowTalkingHostile
)
    local current = PNC.Core and PNC.Core.Now and PNC.Core.Now()
        or getTimeInMillis and getTimeInMillis()
        or 0
    local runtime = record and record.runtime or {}
    local health = record and record.health or {}
    local talkingTarget = targetTargetsPlayer(runtime.target, player)
    local hostileTalkingTarget = allowTalkingHostile == true
        and talkingTarget
    local passiveTalkingTarget = talkingTarget
        and runtime.attackAction == nil
        and current >= (tonumber(runtime.inCombatUntil) or 0)
    local ignoredTalkingTarget = hostileTalkingTarget or passiveTalkingTarget
    if (runtime.target ~= nil and not ignoredTalkingTarget)
        or (runtime.attackAction ~= nil and not hostileTalkingTarget)
        or (current < (tonumber(runtime.inCombatUntil) or 0)
            and not hostileTalkingTarget)
        or current < (tonumber(health.recentDamageUntil) or 0)
    then
        return true
    end
    local cell = getCell and getCell() or nil
    local list = cell and cell.getZombieList
        and cell:getZombieList() or nil
    if not list then return false end
    radius = tonumber(radius) or Safety.GetDangerRadius()
    local radiusSq = radius * radius
    for index = 0, list:size() - 1 do
        local candidate = list:get(index)
        local hostile
        local candidateRecord
        hostile, candidateRecord = managedCandidateIsEnemy(
            candidate,
            record,
            npcID
        )
        if candidate ~= zombie
            and alive(candidate)
            and (
                distanceSq(candidate, player) <= radiusSq
                or distanceSq(candidate, zombie) <= radiusSq
            )
            and hostile == true
            and candidateTargetsConversation(
                candidate,
                candidateRecord,
                player,
                zombie,
                npcID
            )
        then
            return true
        end
    end
    return false
end

function Safety.Check(spec)
    local player, zombie, record, npcID = Safety.ResolveActors(spec)
    local snapshot = snapshotFor(spec)
    local snapshotConversation = allowsSnapshotConversation(spec, zombie)
    if not alive(zombie) and not snapshotConversation then
        return "npc_unavailable"
    end
    local maximumDistance = Safety.GetMaximumDistance()
    local targetDistance = alive(zombie)
        and distanceSq(player, zombie)
        or snapshotDistanceSq(player, snapshot)
    if targetDistance > maximumDistance * maximumDistance then
        return "distance"
    end
    if settingsValue("closeConversationOnDanger", true) == true
        and Safety.HasDanger(
            player,
            zombie,
            record,
            npcID,
            Safety.GetDangerRadius(),
            spec and spec.context
                and spec.context.allowHostileParley == true
        )
    then
        return "danger"
    end
    return nil
end

return Safety
