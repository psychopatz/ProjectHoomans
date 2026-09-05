-- Follow-phase combat abandonment attribution and return commentary.
--
-- Capture is a single edge at live -> abstract. Delivery is delegated to the
-- social greeting pump, which already has the bounded player/NPC candidate
-- set and the reusable visibility-aware meeting gate.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.FollowerAbandonment = PNC.FollowerAbandonment or {}

local Service = PNC.FollowerAbandonment
local Core = PNC.Core
local Const = PNC.Const
local Common = PNC.BehaviorCommon
local Registry = PNC.Registry
local EntityRef = PNC.EntityRef
local PlayerCharacters = PNC.PlayerCharacters
local Relationships = PNC.Relationships
local Network = PNC.Network
local Meeting = PNC.SocialMeeting
    or PNC.SocialGreeting

Service.FLAVOR_ZOMBIE = "social.follower_abandoned_zombie"
Service.FLAVOR_HOSTILE_NPC = "social.follower_abandoned_hostile_npc"

local function worldAgeHours(value)
    value = tonumber(value)
    if value ~= nil and value == value
        and value ~= math.huge and value ~= -math.huge
    then
        return math.max(0, value)
    end
    if getGameTime and getGameTime()
        and getGameTime().getWorldAgeHours
    then
        return math.max(
            0,
            tonumber(getGameTime():getWorldAgeHours()) or 0
        )
    end
    return 0
end

local function audit(eventName, fields)
    local diagnostics = PNC.PerformanceScalingDiagnostics
    if not diagnostics
        or not diagnostics.IsFollowerAbandonmentAuditEnabled
        or diagnostics.IsFollowerAbandonmentAuditEnabled() ~= true
        or not diagnostics.LogFollowerAbandonment
    then
        return
    end
    diagnostics.LogFollowerAbandonment(eventName, fields)
end

local function markDirty(record, domain)
    if Registry and Registry.MarkDirty then
        Registry.MarkDirty(record, domain or "follower_abandonment")
    end
end

local function pendingFor(record)
    local marker = record and record.followerAbandonment or nil
    if type(marker) ~= "table" or not marker.eventID then return nil end
    return marker
end

local function resolveOwner(record)
    local owner
    local ok
    if not record then return nil end
    if Common and Common.GetOwner then
        ok, owner = pcall(Common.GetOwner, record)
        if ok and owner then return owner end
    end
    if Core and Core.ResolvePlayerByOnlineID
        and record.ownerOnlineID ~= nil
    then
        ok, owner = pcall(
            Core.ResolvePlayerByOnlineID,
            record.ownerOnlineID
        )
        if ok and owner then return owner end
    end
    if Core and Core.ResolvePlayerByUsername
        and record.ownerUsername
    then
        ok, owner = pcall(
            Core.ResolvePlayerByUsername,
            record.ownerUsername
        )
        if ok and owner then return owner end
    end
    return nil
end

local function stablePlayerKey(player, at)
    local key
    if not player or not PlayerCharacters
        or not PlayerCharacters.GetEntityKey
    then
        return nil
    end
    key = PlayerCharacters.GetEntityKey(player, {
        callback = "follower_abandonment",
        worldAgeHours = at,
    })
    if key and tostring(key) ~= "" then return tostring(key) end
    return nil
end

local function hostileID(target)
    local value = target and (
        target.kind == "zombie" and (target.zombieId or target.id)
        or target.id
    ) or nil
    if value == nil or type(value) == "table" then return nil end
    return tostring(value)
end

local function eventIDFor(record, at)
    return "social:follow_abandonment:" .. tostring(record.id)
        .. ":" .. tostring(record.presenceRevision or 0)
        .. ":" .. tostring(math.floor(at * 1000))
end

local function roleFor(record)
    local interactions = PNC.VanillaEmoteInteractions
    local ok
    local role
    if interactions and interactions.ResolveNPCType then
        ok, role = pcall(interactions.ResolveNPCType, record)
        if ok and role then return tostring(role) end
    end
    if record and record.recruited == true then return "colonist" end
    return "neutral"
end

local function relationshipTier(relationship)
    local interactions = PNC.VanillaEmoteInteractions
    if interactions and interactions.ResolveRelationshipTier then
        return interactions.ResolveRelationshipTier(relationship)
    end
    return "reserved"
end

local function relationshipState(relationship)
    return tostring(relationship and relationship.state or "unknown")
end

local function applyRelationship(record, marker, at)
    local targetKey
    local result
    if marker.relationshipApplied == true then
        return true, "already_applied"
    end
    if not marker.ownerKey then return false, "owner_identity_unavailable" end
    targetKey = EntityRef and EntityRef.ForNPC
        and EntityRef.ForNPC(record.id) or nil
    if not targetKey or not PNC.SocialEvents
        or not PNC.SocialEvents.Emit
    then
        return false, "social_event_service_unavailable"
    end
    result = PNC.SocialEvents.Emit({
        id = marker.eventID,
        type = "abandoned_in_combat",
        actorKey = marker.ownerKey,
        targetKey = targetKey,
        occurredAt = at,
        sourceSystem = "combat",
        x = record.x,
        y = record.y,
        z = record.z,
        context = {
            phase = "follow",
            detection = "follow_range_exit",
            hostileKind = marker.hostileKind,
            hostileID = marker.hostileID,
            npcID = tostring(record.id),
        },
    })
    if result == true
        or type(result) == "table"
            and (result.ok == true or result.reason == "duplicate_event")
    then
        marker.relationshipApplied = true
        markDirty(record, "follower_abandonment_relationship")
        audit("relationship_applied", {
            "npc=" .. tostring(record.id),
            "eventID=" .. tostring(marker.eventID),
            "owner=" .. tostring(marker.ownerKey),
            "hostileKind=" .. tostring(marker.hostileKind),
            "hostileID=" .. tostring(marker.hostileID or "nil"),
        })
        return true, "applied"
    end
    return false, type(result) == "table"
        and tostring(result.reason or "not_applied")
        or "not_applied"
end

local function clearPending(record, reason)
    if not record or not pendingFor(record) then return false end
    record.followerAbandonment = nil
    markDirty(record, "follower_abandonment_clear")
    audit("pending_cleared", {
        "npc=" .. tostring(record.id),
        "reason=" .. tostring(reason or "unknown"),
    })
    return true
end

function Service.HasPending(record)
    return pendingFor(record) ~= nil
end

function Service.CaptureAtRangeExit(record, zombie, occurredAt)
    local marker
    local owner
    local target
    local kind
    local combatReason
    local at
    local ownerKey
    if not Core or not Core.IsAuthority or not Core.IsAuthority() then
        return false, "not_authority"
    end
    if not record or record.alive == false then
        return false, "invalid_record"
    end
    if pendingFor(record) then return false, "already_pending" end
    at = worldAgeHours(occurredAt)
    if Common and Common.IsActiveFollowCombatTarget then
        target, kind, combatReason =
            Common.IsActiveFollowCombatTarget(record, at)
    end
    if not target or (kind ~= "zombie" and kind ~= "npc") then
        return false, "follow_combat_not_active"
    end
    owner = resolveOwner(record)
    ownerKey = stablePlayerKey(owner, at)
    marker = {
        eventID = eventIDFor(record, at),
        ownerKey = ownerKey,
        ownerUsername = record.ownerUsername,
        ownerOnlineID = record.ownerOnlineID,
        hostileKind = kind,
        hostileID = hostileID(target),
        capturedAt = at,
        relationshipApplied = false,
    }
    record.followerAbandonment = marker
    markDirty(record, "follower_abandonment_capture")
    if ownerKey then applyRelationship(record, marker, at) end
    audit("captured", {
        "npc=" .. tostring(record.id),
        "eventID=" .. tostring(marker.eventID),
        "owner=" .. tostring(marker.ownerKey or "unresolved"),
        "hostileKind=" .. tostring(kind),
        "hostileID=" .. tostring(marker.hostileID or "nil"),
        "combatEvidence=" .. tostring(combatReason),
        "bodyPresent=" .. tostring(zombie ~= nil),
    })
    return true, marker
end

function Service.TryDeliver(player, record, body, occurredAt, meeting)
    local marker = pendingFor(record)
    local at
    local playerKey
    local owner
    local ownerKey
    local canMeet
    local meetingReason
    local relationship
    local role
    local tier
    local flavorID
    local context
    local sent
    local sendReason
    if not marker then return false, "no_pending_event" end
    at = worldAgeHours(occurredAt)
    if not record or record.alive == false then
        clearPending(record, "npc_unavailable")
        return false, "npc_unavailable"
    end
    if not record.orderSpec
        or tostring(record.orderSpec.kind or "")
            ~= tostring(Const.ORDER_FOLLOW or "follow")
    then
        clearPending(record, "follow_order_ended")
        return false, "follow_order_ended"
    end
    playerKey = stablePlayerKey(player, at)
    if not playerKey then return false, "player_identity_unavailable" end
    if marker.ownerKey then
        if marker.ownerKey ~= playerKey then
            return false, "not_owner"
        end
    else
        owner = resolveOwner(record)
        ownerKey = stablePlayerKey(owner, at)
        if not ownerKey or ownerKey ~= playerKey then
            return false, "owner_identity_unavailable"
        end
        marker.ownerKey = ownerKey
        markDirty(record, "follower_abandonment_owner")
    end
    if meeting and meeting.meetingEligible == false then
        return false, meeting.meetingReason or "not_meeting"
    end
    if not (meeting and meeting.meetingEligible == true) then
        if not Meeting or not Meeting.CanPlayerMeetNPC then
            return false, "meeting_service_unavailable"
        end
        canMeet, meetingReason = Meeting.CanPlayerMeetNPC(
            player,
            record,
            body,
            Meeting.DEFAULT_RADIUS
                or PNC.SocialGreeting.GREETING_RADIUS
        )
        if not canMeet then return false, meetingReason or "not_meeting" end
    end
    if not marker.relationshipApplied then
        applyRelationship(record, marker, at)
        if not marker.relationshipApplied then
            return false, "relationship_pending"
        end
    end
    relationship = Relationships and Relationships.Get
        and Relationships.Get(record.id, marker.ownerKey) or nil
    role = roleFor(record)
    tier = relationshipTier(relationship)
    flavorID = marker.hostileKind == "zombie"
        and Service.FLAVOR_ZOMBIE or Service.FLAVOR_HOSTILE_NPC
    context = {
        eventType = "abandoned_in_combat",
        phase = "follow",
        detection = "follow_range_exit",
        hostileKind = marker.hostileKind,
        hostileID = marker.hostileID,
        npcID = tostring(record.id),
        socialRole = role,
        relationshipState = relationshipState(relationship),
        relationshipTier = tier,
    }
    if not Network or not Network.SendConversationRelationshipForNPC then
        return false, "relationship_transport_unavailable"
    end
    sent, sendReason = Network.SendConversationRelationshipForNPC(
        player,
        record.id,
        "follow_abandonment_return",
        {
            source = "follow_abandonment",
            eventID = marker.eventID,
            npcID = tostring(record.id),
            ambientFlavor = {
                flavorID = flavorID,
                eventType = "abandoned_in_combat",
                family = "relationship_commentary",
                priority = 75,
                llmEligible = false,
                llmPriority = 0,
                weight = 2,
                npcID = tostring(record.id),
                npcType = role,
                socialRole = role,
                relationshipState = context.relationshipState,
                relationshipTier = tier,
                mergeKey = tostring(record.id)
                    .. ":follow_abandonment",
                cooldowns = {
                    familyMs = 20000,
                    speakerMs = 20000,
                    ambientMs = 4500,
                    mergeWindowMs = 5000,
                },
                context = context,
            },
        }
    )
    if sent ~= true then return false, sendReason or "send_failed" end
    clearPending(record, "delivered")
    audit("delivered", {
        "npc=" .. tostring(record.id),
        "eventID=" .. tostring(marker.eventID),
        "owner=" .. tostring(marker.ownerKey),
        "hostileKind=" .. tostring(marker.hostileKind),
        "hostileID=" .. tostring(marker.hostileID or "nil"),
        "flavorID=" .. tostring(flavorID),
    })
    return true, "delivered"
end

return Service
