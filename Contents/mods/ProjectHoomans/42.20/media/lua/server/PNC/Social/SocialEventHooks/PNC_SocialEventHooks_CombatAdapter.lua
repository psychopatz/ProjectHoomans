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
