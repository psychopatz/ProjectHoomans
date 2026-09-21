-- Social callbacks consumed by PsychopatzCore's zombie-kill detector.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.SocialEventHooks = PNC.SocialEventHooks or {}
PNC.SocialEventHooksInternal = PNC.SocialEventHooksInternal or {}

local Hooks = PNC.SocialEventHooks
local H = PNC.SocialEventHooksInternal
local Core = PNC.Core
local EntityRef = PNC.EntityRef
local Registry = PNC.Registry
local Perception = PNC.Perception
local Const = PNC.Const
local Network = PNC.Network
local WITNESS_RADIUS = tonumber(Const and Const.ZOMBIE_TARGET_RADIUS) or 12
local ZOMBIE_HORDE_CLEAR_MS = 3000
local ZOMBIE_AWARENESS_PRESENTATION_COOLDOWN_MS = 12000
local MAX_RECENT_AWARENESS_PLAYERS = 128
local recentAwarenessByPlayer = {}
local recentAwarenessOrder = {}

local ZOMBIE_HORDE_MEMORY = "zombie_horde_encounter"
local ZOMBIE_STAMINA_MEMORY = "zombie_stamina_retreat"

local function call(object, method, ...)
    if not object or not object[method] then
        return nil
    end
    local ok, value = pcall(object[method], object, ...)
    if ok then
        return value
    end
    return nil
end

local function audit(fields)
    if not (PNC.Config
        and PNC.Config.Relationships
        and PNC.Config.Relationships.DebugCombatCallbacks == true)
    then
        return
    end
    local message = "[ZombieKillAudit] " .. table.concat(fields, " ")
    if Core and Core.LogInfo then
        Core.LogInfo(message)
    else
        print("[PNC][INFO] " .. message)
    end
end

local function coordinate(object, method, fallback)
    local value = call(object, method)
    if value == nil then
        value = fallback
    end
    return tonumber(value)
end

local function distanceSq(x1, y1, x2, y2)
    if Core and Core.DistanceSq then
        return Core.DistanceSq(x1, y1, x2, y2)
    end
    local dx = x2 - x1
    local dy = y2 - y1
    return (dx * dx) + (dy * dy)
end

local function canSee(record, target)
    local ok
    local visible
    if not Perception or type(Perception.CanSeeWorldObject) ~= "function" then
        return false
    end
    ok, visible = pcall(
        Perception.CanSeeWorldObject,
        record,
        target
    )
    return ok and visible == true
end

local function relationshipDelta(before, after)
    return {
        approval = (tonumber(after and after.approval) or 0)
            - (tonumber(before and before.approval) or 0),
        respect = (tonumber(after and after.respect) or 0)
            - (tonumber(before and before.respect) or 0),
        familiarity = (tonumber(after and after.familiarity) or 0)
            - (tonumber(before and before.familiarity) or 0),
    }
end

local function relationshipState(relationship)
    return tostring(relationship and (
        relationship.state or relationship.category
    ) or "unknown")
end

local function relationshipTier(relationship)
    local state = relationshipState(relationship)
    if state == "enemy" or state == "rival" then return "reserved" end
    local approval = tonumber(relationship and relationship.approval) or 0
    local familiarity = tonumber(relationship and relationship.familiarity) or 0
    if state == "friend" or approval >= 30 then return "warm" end
    if approval >= 10 or familiarity >= 5 then return "familiar" end
    return "reserved"
end

local function socialRole(record)
    local interactions = PNC.VanillaEmoteInteractions
    if interactions and type(interactions.ResolveNPCType) == "function" then
        local ok, value = pcall(interactions.ResolveNPCType, record)
        if ok and value then return tostring(value) end
    end
    return "neutral"
end

local function dayIndex(worldAgeHours)
    local interactions = PNC and PNC.VanillaEmoteInteractions
    if interactions and type(interactions.DayIndex) == "function" then
        local ok, value = pcall(
            interactions.DayIndex,
            worldAgeHours
        )
        if ok and tonumber(value) then
            return math.max(0, math.floor(tonumber(value)))
        end
    end
    return math.floor(math.max(0, tonumber(worldAgeHours) or 0) / 24)
end

local function memoryToday(relationship, memoryType, worldAgeHours)
    local interactions = PNC and PNC.VanillaEmoteInteractions
    local memories = relationship and relationship.memories or {}
    local targetDay = dayIndex(worldAgeHours)
    local hasToday
    local memory
    local createdAt
    local index
    if interactions and type(interactions.HasMemoryToday) == "function" then
        local ok, value = pcall(
            interactions.HasMemoryToday,
            relationship,
            memoryType,
            worldAgeHours
        )
        if ok then
            hasToday = value == true
        end
    end
    if hasToday == false then
        return nil, false
    end
    for index = 1, #memories do
        memory = memories[index]
        createdAt = tonumber(memory and memory.createdAt)
        if memory and memory.type == memoryType
            and createdAt ~= nil
            and dayIndex(createdAt) == targetDay
        then
            return tostring(memory.id or ""), true
        end
    end
    return nil, hasToday == true
end

local function rememberZombieAwareness(
    record,
    playerKey,
    memoryType,
    worldAgeHours,
    countSize,
    source
)
    local relationships = PNC and PNC.Relationships
    local relationship = record.social
        and record.social.relationships
        and record.social.relationships[playerKey] or nil
    local memoryID
    local alreadyRecorded
    local tags = {
        combat = true,
        witnessed = true,
        zombie_threat = true,
    }
    local day = dayIndex(worldAgeHours)
    if memoryType == ZOMBIE_HORDE_MEMORY then
        tags.zombie_horde = true
    elseif memoryType == ZOMBIE_STAMINA_MEMORY then
        tags.stamina_retreat = true
    end
    if countSize then
        tags["horde_size_" .. countSize] = true
    end
    if source == "follow" or source == "combat" then
        tags["detected_by_" .. source] = true
    end
    memoryID, alreadyRecorded = memoryToday(
        relationship,
        memoryType,
        worldAgeHours
    )
    if alreadyRecorded then
        return memoryID ~= "" and memoryID or nil
    end
    if not relationships or type(relationships.AddMemory) ~= "function" then
        return nil
    end
    memoryID = "zombie-awareness:" .. memoryType .. ":"
        .. tostring(record.id) .. ":" .. tostring(day)
    local added = relationships.AddMemory(record.id, playerKey, {
        id = memoryID,
        type = memoryType,
        aboutKey = playerKey,
        createdAt = worldAgeHours,
        approvalEffect = 0,
        respectEffect = 0,
        moraleEffect = 0,
        strength = 0.55,
        decayPerDay = 0.04,
        permanent = false,
        shareable = false,
        knowledgeSource = "experienced",
        tags = tags,
    })
    return added == true and memoryID or nil
end

local function reserveAwarenessPresentation(playerKey, now)
    local key = tostring(playerKey or "")
    local expiresAt = recentAwarenessByPlayer[key]
    local oldest
    if key == "" then return false end
    if expiresAt and now < expiresAt
        and expiresAt - now
            <= ZOMBIE_AWARENESS_PRESENTATION_COOLDOWN_MS
    then
        return false
    end
    while #recentAwarenessOrder >= MAX_RECENT_AWARENESS_PLAYERS do
        oldest = table.remove(recentAwarenessOrder, 1)
        if oldest
            and recentAwarenessByPlayer[oldest.key] == oldest.expiresAt
        then
            recentAwarenessByPlayer[oldest.key] = nil
        end
    end
    expiresAt = now + ZOMBIE_AWARENESS_PRESENTATION_COOLDOWN_MS
    recentAwarenessByPlayer[key] = expiresAt
    recentAwarenessOrder[#recentAwarenessOrder + 1] = {
        key = key,
        expiresAt = expiresAt,
    }
    return true
end

local function countBand(count)
    count = math.max(0, tonumber(count) or 0)
    if count < 3 then return nil end
    if count >= 8 then return "large" end
    if count >= 5 then return "several" end
    return "few"
end

local function playerCanHearNPC(player, record, radiusSq)
    local px = coordinate(player, "getX")
    local py = coordinate(player, "getY")
    local pz = coordinate(player, "getZ")
    local nx = tonumber(record and record.x)
    local ny = tonumber(record and record.y)
    local nz = tonumber(record and record.z)
    if not px or not py or not pz or not nx or not ny or not nz then
        return false
    end
    if math.abs(pz - nz) >= 1
        or distanceSq(px, py, nx, ny) > radiusSq
    then
        return false
    end
    return canSee(record, player)
end

local function newZombieAwarenessEventID(record, eventType, now)
    local runtime = record.runtime or {}
    local sequence = math.floor(
        tonumber(runtime.zombieAwarenessEventSequence) or 0
    ) + 1
    record.runtime = runtime
    runtime.zombieAwarenessEventSequence = sequence
    return "social:" .. eventType .. ":" .. tostring(record.id) .. ":"
        .. tostring(math.floor(tonumber(now) or 0)) .. ":"
        .. tostring(sequence)
end

local function emitZombieAwareness(
    record,
    eventType,
    flavorID,
    eventID,
    source,
    now,
    count,
    reason
)
    local npcID = tostring(record and record.id or "")
    local radiusSq = WITNESS_RADIUS * WITNESS_RADIUS
    local role = socialRole(record)
    local worldAgeHours = H.WorldAgeHours()
    local band = countBand(count)
    local emitted = 0
    if npcID == "" or not Core
        or type(Core.ForEachPlayer) ~= "function"
    then
        return 0
    end
    Core.ForEachPlayer(function(player)
        local playerKey
        local memoryID
        local relationship
        local state
        local speakerRole
        local tier
        local context
        local result
        local ok
        local sent
        if not player or not playerCanHearNPC(player, record, radiusSq) then
            return
        end
        playerKey = Hooks.ResolvePlayerKey(player)
        if not playerKey then return end
        memoryID = rememberZombieAwareness(
            record,
            playerKey,
            eventType,
            worldAgeHours,
            band,
            source
        )
        if not Network
            or type(Network.SendConversationRelationshipForNPC)
                ~= "function"
            or not reserveAwarenessPresentation(playerKey, now)
        then
            return
        end
        relationship = record.social
            and record.social.relationships
            and record.social.relationships[playerKey] or nil
        state = relationshipState(relationship)
        speakerRole = (state == "enemy" or state == "rival")
            and "hostile" or role
        tier = relationshipTier(relationship)
        context = {
            eventType = eventType,
            memoryID = memoryID,
            memoryType = eventType,
            source = source,
            zombieCountBand = band,
            retreatReason = reason,
            npcType = role,
            socialRole = speakerRole,
            relationshipState = state,
            relationshipTier = tier,
        }
        result = {
            source = eventType,
            eventID = eventID,
            npcID = npcID,
            ambientFlavor = {
                eventID = eventID,
                flavorID = flavorID,
                eventType = eventType,
                family = "zombie_awareness",
                priority = 12,
                weight = 0.25,
                llmEligible = false,
                memoryEligible = false,
                npcID = npcID,
                npcType = role,
                socialRole = speakerRole,
                relationshipState = state,
                relationshipTier = tier,
                mergeKey = eventID,
                cooldowns = {
                    familyMs = ZOMBIE_AWARENESS_PRESENTATION_COOLDOWN_MS,
                    speakerMs = 0,
                    ambientMs = 4500,
                    mergeWindowMs = 0,
                },
                ttlMs = 8000,
                holdMs = 1800,
                context = context,
                source = {
                    kind = "social_flavor",
                    channel = "combat",
                    eventType = eventType,
                },
            },
        }
        ok, sent = pcall(
            Network.SendConversationRelationshipForNPC,
            player,
            npcID,
            eventType,
            result
        )
        if ok and sent == true then
            recentAwarenessByPlayer[tostring(playerKey)] =
                now + ZOMBIE_AWARENESS_PRESENTATION_COOLDOWN_MS
            emitted = emitted + 1
        else
            recentAwarenessByPlayer[tostring(playerKey)] = nil
        end
    end)
    return emitted
end

function Hooks.ObserveZombieHorde(record, count, threshold, now, source)
    local runtime
    local state
    local lastDetectedAt
    local eventType = ZOMBIE_HORDE_MEMORY
    local eventID
    count = math.max(0, tonumber(count) or 0)
    threshold = math.max(1, tonumber(threshold) or 4)
    now = tonumber(now) or (Core and Core.Now and Core.Now()) or 0
    if not record or record.alive == false or not record.id then
        return false, "invalid_observer"
    end
    if count < threshold then
        return false, "below_horde_threshold"
    end
    runtime = record.runtime
    state = runtime and runtime.zombieHordeAwareness or nil
    lastDetectedAt = tonumber(state and state.lastDetectedAt)
    if lastDetectedAt and now >= lastDetectedAt
        and now - lastDetectedAt < ZOMBIE_HORDE_CLEAR_MS
    then
        state.lastDetectedAt = now
        return false, "horde_episode_active"
    end
    runtime = runtime or {}
    state = state or {}
    record.runtime = runtime
    runtime.zombieHordeAwareness = state
    state.lastDetectedAt = now
    eventID = newZombieAwarenessEventID(record, eventType, now)
    emitZombieAwareness(
        record,
        eventType,
        "social.zombie_horde_detected",
        eventID,
        source or "combat",
        now,
        count
    )
    return true, eventID
end

function Hooks.RecordZombieStaminaRetreat(record, reason, now)
    local count
    local eventType = ZOMBIE_STAMINA_MEMORY
    local eventID
    if not record or record.alive == false or not record.id then
        return false, "invalid_observer"
    end
    now = tonumber(now) or (Core and Core.Now and Core.Now()) or 0
    count = record.runtime
        and record.runtime.combatThreatAssessment
        and record.runtime.combatThreatAssessment.hordeCount or 0
    eventID = newZombieAwarenessEventID(record, eventType, now)
    return emitZombieAwareness(
        record,
        eventType,
        "social.zombie_stamina_retreat",
        eventID,
        "combat",
        now,
        count,
        tostring(reason or "recovering_stamina")
    ) > 0, eventID
end

local function liveNPCIsWitness(record, body, killer, zombie, radiusSq)
    local npcX = coordinate(body, "getX", record and record.x)
    local npcY = coordinate(body, "getY", record and record.y)
    local npcZ = coordinate(body, "getZ", record and record.z)
    local killerX = coordinate(killer, "getX")
    local killerY = coordinate(killer, "getY")
    local killerZ = coordinate(killer, "getZ")
    local zombieX = coordinate(zombie, "getX")
    local zombieY = coordinate(zombie, "getY")
    local zombieZ = coordinate(zombie, "getZ")
    if not npcX or not npcY or not npcZ
        or not killerX or not killerY or not killerZ
        or not zombieX or not zombieY or not zombieZ
    then
        return false
    end
    if math.abs(npcZ - killerZ) >= 1
        or math.abs(npcZ - zombieZ) >= 1
    then
        return false
    end
    if distanceSq(npcX, npcY, killerX, killerY) > radiusSq
        or distanceSq(npcX, npcY, zombieX, zombieY) > radiusSq
    then
        return false
    end
    return canSee(record, killer) and canSee(record, zombie)
end

H.LiveNPCIsWitness = liveNPCIsWitness
H.RelationshipDelta = relationshipDelta
H.WitnessRadius = WITNESS_RADIUS

function H.RecordPlayerKillWitnesses(killer, zombie, context)
    local playerKey
    local threatID
    local killerX
    local killerY
    local killerZ
    local zombieX
    local zombieY
    local zombieZ
    local radiusSq = WITNESS_RADIUS * WITNESS_RADIUS
    local candidates = 0
    local emitted = 0
    local eventID
    local ok
    local processed
    local emitReason
    local detail
    local presentationSent
    local presentationReason
    if not killer or not zombie or not Registry
        or type(Registry.ForEachLive) ~= "function"
    then
        return 0, 0, "witness_registry_unavailable"
    end
    playerKey = Hooks.ResolvePlayerKey(killer)
    if not playerKey then
        return 0, 0, "player_identity_unavailable"
    end
    threatID = tostring(
        context and context.threatID or H.ThreatIDFor(zombie) or "unknown"
    )
    killerX = coordinate(killer, "getX")
    killerY = coordinate(killer, "getY")
    killerZ = coordinate(killer, "getZ")
    zombieX = coordinate(zombie, "getX")
    zombieY = coordinate(zombie, "getY")
    zombieZ = coordinate(zombie, "getZ")
    if not killerX or not killerY or not killerZ
        or not zombieX or not zombieY or not zombieZ
    then
        return 0, 0, "kill_position_unavailable"
    end
    Registry.ForEachLive(function(record, body, npcID)
        local targetKey
        if not record or record.alive == false or not body
            or (body.isDead and body:isDead())
            or not npcID
        then
            return
        end
        if not liveNPCIsWitness(record, body, killer, zombie, radiusSq) then
            return
        end
        candidates = candidates + 1
        targetKey = EntityRef and EntityRef.ForNPC
            and EntityRef.ForNPC(npcID) or nil
        if not targetKey or not PNC.SocialEvents
            or type(PNC.SocialEvents.Emit) ~= "function"
        then
            audit({
                "luaSide=server",
                "event=PlayerKillWitness",
                "phase=relationship_dispatch",
                "result=false",
                "reason=social_event_service_unavailable",
                "playerKey=" .. tostring(playerKey),
                "witnessNPCID=" .. tostring(npcID),
                "threatID=" .. threatID,
            })
            return
        end
        eventID = "social:witnessed_player_kill:" .. threatID .. ":"
            .. tostring(npcID)
        ok, processed = pcall(
            PNC.SocialEvents.Emit,
            {
                id = eventID,
                type = "witnessed_player_kill",
                actorKey = playerKey,
                targetKey = targetKey,
                occurredAt = H.WorldAgeHours(),
                sourceSystem = "combat",
                x = zombieX,
                y = zombieY,
                z = zombieZ,
                context = {
                    threatID = threatID,
                    witnessNPCID = tostring(npcID),
                    killerSource = context and context.killerSource
                        or context and context.source or "unknown",
                },
            }
        )
        emitReason = ok and processed and processed.reason
            or (ok and "unknown_result" or "emit_error")
        if ok and processed and processed.ok == true then
            emitted = emitted + 1
            detail = processed.details and processed.details[1] or nil
            local before = detail and detail.relationshipBefore or nil
            local after = detail and detail.relationshipAfter or nil
            local role = socialRole(record)
            local state = relationshipState(before)
            if Network
                and type(Network.SendConversationRelationshipForNPC)
                    == "function"
            then
                presentationSent, presentationReason =
                    Network.SendConversationRelationshipForNPC(
                        killer,
                        npcID,
                        "witnessed_player_kill",
                        {
                            source = "witnessed_player_kill",
                            eventID = processed.eventID or eventID,
                            relationshipBefore = detail
                                and detail.relationshipBefore or nil,
                            relationshipAfter = detail
                                and detail.relationshipAfter or nil,
                            relationshipDelta = relationshipDelta(
                                before,
                                after
                            ),
                            ambientFlavor = {
                                flavorID = "social.witnessed_player_kill",
                                eventType = "witnessed_player_kill",
                                family = "combat_commentary",
                                priority = 35,
                                llmEligible = true,
                                llmPriority = 90,
                                weight = 1,
                                npcID = tostring(npcID),
                                npcType = role,
                                socialRole = role,
                                relationshipState = state,
                                relationshipTier = relationshipTier(before),
                                mergeKey = tostring(npcID)
                                    .. ":combat_commentary",
                                context = {
                                    eventType = "witnessed_player_kill",
                                    threatID = threatID,
                                    witnessNPCID = tostring(npcID),
                                    npcType = role,
                                    socialRole = role,
                                    relationshipState = state,
                                    relationshipTier = relationshipTier(before),
                                    killerSource = context and context.killerSource
                                        or context and context.source or "unknown",
                                },
                            },
                            npcID = tostring(npcID),
                        }
                    )
                audit({
                    "luaSide=server",
                    "event=PlayerKillWitnessPresentation",
                    "phase=relationship_feedback",
                    "result=" .. tostring(presentationSent == true),
                    "reason=" .. tostring(
                        presentationReason or "nil"
                    ),
                    "playerKey=" .. tostring(playerKey),
                    "witnessNPCID=" .. tostring(npcID),
                    "threatID=" .. threatID,
                })
            else
                audit({
                    "luaSide=server",
                    "event=PlayerKillWitnessPresentation",
                    "phase=relationship_feedback",
                    "result=false",
                    "reason=relationship_transport_unavailable",
                    "playerKey=" .. tostring(playerKey),
                    "witnessNPCID=" .. tostring(npcID),
                    "threatID=" .. threatID,
                })
            end
        end
        audit({
            "luaSide=server",
            "event=PlayerKillWitness",
            "phase=relationship_dispatch",
            "result=" .. tostring(ok and processed and processed.ok),
            "reason=" .. tostring(emitReason),
            "playerKey=" .. tostring(playerKey),
            "witnessNPCID=" .. tostring(npcID),
            "threatID=" .. threatID,
        })
    end)
    return emitted, candidates, emitted > 0 and "witnesses_notified"
        or "no_witness_event_emitted"
end

function H.OnWeaponHitCharacter(attacker, target, context)
    local result, reason = Hooks.OnPlayerWeaponHitThreat(attacker, target)
    audit({
        "luaSide=server",
        "runtime=" .. tostring(context and context.runtime or "unknown"),
        "event=OnWeaponHitCharacter",
        "result=" .. tostring(result),
        "reason=" .. tostring(reason or "nil"),
        "attackerOnlineID="
            .. tostring(call(attacker, "getOnlineID") or "nil"),
        "zombieOnlineID="
            .. tostring(call(target, "getOnlineID") or "nil"),
        "zombiePersistentOutfitID="
            .. tostring(call(target, "getPersistentOutfitID") or "nil"),
    })
    return result, reason
end

function H.OnZombieDead(killer, zombie, context)
    local threatID = context and context.threatID
        or tostring(call(zombie, "getOnlineID") or "nil")
    local result, reason = Hooks.HandleClientZombieKill(
        killer,
        zombie,
        context
    )
    local witnessCount = 0
    local witnessCandidates = 0
    local witnessReason = "kill_not_dispatched"
    if result == true then
        witnessCount, witnessCandidates, witnessReason =
            H.RecordPlayerKillWitnesses(killer, zombie, context)
    end
    audit({
        "luaSide=server",
        "event=PlayerKillWitnessScan",
        "phase=relationship_dispatch",
        "result=" .. tostring(result == true and witnessCount > 0),
        "reason=" .. tostring(witnessReason),
        "threatID=" .. tostring(threatID),
        "witnessCandidates=" .. tostring(witnessCandidates),
        "witnessCount=" .. tostring(witnessCount),
    })
    audit({
        "luaSide=server",
        "runtime=" .. tostring(context and context.runtime or "unknown"),
        "event=OnZombieDead",
        "phase=relationship_dispatch",
        "result=" .. tostring(result),
        "reason=" .. tostring(reason or "nil"),
        "threatID=" .. tostring(threatID),
        "killerOnlineID="
            .. tostring(call(killer, "getOnlineID") or "nil"),
        "killerUsername="
            .. tostring(call(killer, "getUsername") or "nil"),
        "nativeZombieKills="
            .. tostring(call(killer, "getZombieKills") or "nil"),
        "witnessCount=" .. tostring(witnessCount),
    })
    return result, reason
end

return Hooks
