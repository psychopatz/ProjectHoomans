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

local function targetMatches(target, player, zombie, npcID)
    if not target then return false end
    if target == player or target == zombie then return true end
    if type(target) ~= "table" then return false end
    return tostring(target.id or "") == tostring(npcID or "")
        or target.worldObject == player
        or target.worldObject == zombie
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
            return false
        end
        local relationships = PNC.Relationships
        return relationships
            and relationships.AreNPCsEnemies
            and currentRecord
            and relationships.AreNPCsEnemies(
                currentRecord,
                candidateRecord
            )
            or targetMatches(
                candidateRecord.runtime
                    and candidateRecord.runtime.target,
                nil,
                nil,
                npcID
            )
    end
    local modData = candidate.getModData
        and candidate:getModData() or nil
    local managedID = modData and modData.PNC_UUID or nil
    if not managedID then return true end
    if tostring(managedID) == tostring(npcID) then return false end
    local snapshots = PNC.Network
        and PNC.Network.ClientState
        and PNC.Network.ClientState.snapshots
        or {}
    local snapshot = snapshots[tostring(managedID)]
    return snapshot and tostring(snapshot.faction or "") == "hostile"
        or false
end

function Safety.HasDanger(player, zombie, record, npcID, radius)
    local current = PNC.Core and PNC.Core.Now and PNC.Core.Now()
        or getTimeInMillis and getTimeInMillis()
        or 0
    local runtime = record and record.runtime or {}
    local health = record and record.health or {}
    if runtime.target ~= nil
        or runtime.attackAction ~= nil
        or current < (tonumber(runtime.inCombatUntil) or 0)
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
        if candidate ~= zombie
            and alive(candidate)
            and (
                distanceSq(candidate, player) <= radiusSq
                or distanceSq(candidate, zombie) <= radiusSq
            )
            and managedCandidateIsEnemy(
                candidate,
                record,
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
    if not alive(zombie) then return "npc_unavailable" end
    local maximumDistance = Safety.GetMaximumDistance()
    if distanceSq(player, zombie) > maximumDistance * maximumDistance then
        return "distance"
    end
    if settingsValue("closeConversationOnDanger", true) == true
        and Safety.HasDanger(
            player,
            zombie,
            record,
            npcID,
            Safety.GetDangerRadius()
        )
    then
        return "danger"
    end
    return nil
end

return Safety
