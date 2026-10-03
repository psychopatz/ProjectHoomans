local Awareness = PNC and PNC.CorpseAwareness
if not Awareness then return end

local Internal = Awareness.Internal or {}
local Deps = Internal.ReactionDeps or {}
local lower = Deps.lower
local safeDisplayText = Deps.safeDisplayText
local worldAgeHours = Deps.worldAgeHours
local deathMemoryID = Deps.deathMemoryID
local hasMemory = Deps.hasMemory
local knownKillerName = Deps.knownKillerName
local MEMORY_TYPE = Deps.MEMORY_TYPE
local MEMORY_LIMIT_PER_NPC = Deps.MEMORY_LIMIT_PER_NPC
local DETECTION_RADIUS_SQ = Deps.DETECTION_RADIUS_SQ

local function rememberWitness(
    observer,
    targetKey,
    identity,
    category,
    memoryID,
    attribution
)
    local relationships = PNC.Relationships
    local tags = {
        corpse = true,
        death = true,
        witnessed = true,
        death_witnessed = true,
        ["relation_" .. category] = true,
    }
    local factionID = tostring(identity.factionID or "")
    local ok
    local runtime
    local sourceKey
    if factionID ~= "" then
        tags["faction:" .. string.sub(factionID, 1, 120)] = true
    end
    if type(attribution) == "table" then
        local attackerKind = lower(attribution.kind)
        if attackerKind == "player" or attackerKind == "npc" then
            tags["death_caused_by_" .. attackerKind] = true
        end
        if attribution.sourceKey and PNC.EntityRef
            and PNC.EntityRef.IsValid
            and PNC.EntityRef.IsValid(attribution.sourceKey)
        then
            sourceKey = attribution.sourceKey
        elseif attackerKind == "player" then
            local killerName = safeDisplayText(
                attribution.killerName,
                ""
            )
            if killerName ~= "" then
                tags["killer_name:" .. string.sub(killerName, 1, 80)] = true
            end
        end
    end
    if not relationships or type(relationships.AddMemory) ~= "function" then
        return false
    end
    ok = relationships.AddMemory(observer.id, targetKey, {
        id = memoryID,
        type = MEMORY_TYPE,
        aboutKey = targetKey,
        createdAt = worldAgeHours(),
        approvalEffect = 0,
        respectEffect = 0,
        moraleEffect = 0,
        strength = 1,
        decayPerDay = 0,
        permanent = true,
        shareable = false,
        knowledgeSource = "witnessed",
        sourceKey = sourceKey,
        tags = tags,
    })
    if ok ~= true then return false end
    runtime = observer.runtime or {}
    observer.runtime = runtime
    runtime.corpseAwarenessMemorySocial = observer.social
    runtime.corpseAwarenessMemoryCount = math.min(
        MEMORY_LIMIT_PER_NPC,
        (tonumber(runtime.corpseAwarenessMemoryCount) or 0) + 1
    )
    return true
end

local function hasSpokenMemory(relation, memoryID)
    return hasMemory(relation, memoryID)
end

local function playerCanHear(player, x, y, z)
    local px
    local py
    local pz
    local dx
    local dy
    if not player or player.isDead and player:isDead() then return false end
    px = player.getX and tonumber(player:getX()) or nil
    py = player.getY and tonumber(player:getY()) or nil
    pz = player.getZ and tonumber(player:getZ()) or nil
    if not px or not py or not pz or math.floor(pz) ~= math.floor(z) then
        return false
    end
    dx = px - x
    dy = py - y
    return dx * dx + dy * dy <= DETECTION_RADIUS_SQ
end

local function sendToNearbyPlayers(observer, actor, greeting)
    local core = PNC.Core
    local network = PNC.Network
    local x = actor and actor.getX and tonumber(actor:getX())
        or tonumber(observer and observer.x)
    local y = actor and actor.getY and tonumber(actor:getY())
        or tonumber(observer and observer.y)
    local z = actor and actor.getZ and tonumber(actor:getZ())
        or tonumber(observer and observer.z) or 0
    local sent = false
    if not x or not y or not core or type(core.ForEachPlayer) ~= "function"
        or not network or type(network.SendSocialGreeting) ~= "function"
    then
        return false
    end
    core.ForEachPlayer(function(player)
        if playerCanHear(player, x, y, z)
            and network.SendSocialGreeting(player, greeting) == true
        then
            sent = true
        end
    end)
    return sent
end

local function speak(
    observer,
    actor,
    identity,
    category,
    token,
    attribution,
    revenge
)
    local memory = PNC.Conversation
    and PNC.Conversation.Memory or nil
    local template
    local gossipPacket
    local npcID = tostring(observer.id or "")
    local memoryID = deathMemoryID(token)
    local flavorID = "corpse_seen_" .. category
    local arguments = {
        subject = identity.name,
        faction = identity.factionName ~= ""
            and identity.factionName or "an unknown faction",
    }
    if not memory or type(memory.SelectGossipTemplate) ~= "function"
        or type(memory.BuildGossipPacket) ~= "function"
        or not actor
        or not memoryID
    then
        return false
    end
    if revenge and knownKillerName(attribution) then
        flavorID = "corpse_seen_revenge_" .. category
        arguments.killer = safeDisplayText(attribution.killerName, "")
        if arguments.faction == "an unknown faction" then
            arguments.faction = "our group"
        end
    end
    template = memory.SelectGossipTemplate(
        flavorID,
        observer.identitySeed or 1,
        token
    )
    if not template then return false end
    gossipPacket = memory.BuildGossipPacket(template, arguments)
    if type(gossipPacket) ~= "table" then return false end
    if npcID == "" or not sendToNearbyPlayers(observer, actor, {
        eventID = string.sub(
            "corpse-reaction:" .. npcID .. ":" .. memoryID,
            1,
            384
        ),
        npcID = npcID,
        flavorID = flavorID,
        eventType = "corpse_reaction",
        gossipPacket = gossipPacket,
        corpseNPCID = identity.npcID,
        corpseName = identity.name,
        factionName = identity.factionName,
        relationshipKind = category,
        memoryID = memoryID,
        memoryType = MEMORY_TYPE,
    }) then
        return false
    end
    return true
end

Awareness.Internal.Reactions = {
    rememberWitness = rememberWitness,
    hasSpokenMemory = hasSpokenMemory,
    speak = speak,
}
