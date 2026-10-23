-- Canonical production Talk-start projection.
--
-- Native context-menu Talk and the Semantic Lab may adapt their input into a
-- canonical entry, but neither caller owns target classification, audience,
-- relationship, availability, or hostile route policy.  This module is the
-- single production-owned boundary for those facts.

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local Conversation = PNC.Conversation
local TalkStart = Conversation.TalkStart or {}
Conversation.TalkStart = TalkStart

TalkStart.VERSION = 1
TalkStart.SCHEMA = "semantic.talk.start.projection.v1"

if not PNC.NPCTypePalette then
    require "PNC/UI/PNC_NPCTypePalette"
end
if not Conversation.Audience then
    require "PNC/Conversation/PNC_ConversationAudience"
end
if not Conversation.Relationship
    or type(Conversation.Relationship.Resolve) ~= "function"
then
    Conversation.Relationship = Conversation.Relationship or {}
    require "PNC/Conversation/ConversationRelationship/PNC_ConversationRelationship_Resolution"
end

local Palette = PNC.NPCTypePalette
local Audience = Conversation.Audience
local Relationship = Conversation.Relationship

local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, item in pairs(value) do
        result[key] = copy(item)
    end
    return result
end

local function valueFromEntry(entry, key)
    local snapshot = entry and type(entry.snapshot) == "table"
        and entry.snapshot or {}
    local record = entry and type(entry.record) == "table"
        and entry.record or {}
    if entry and entry[key] ~= nil then return entry[key] end
    if snapshot[key] ~= nil then return snapshot[key] end
    return record[key]
end

local function relationshipProfile(entry, player)
    local relationshipID = Relationship.Resolve(entry, player)
    local state = PNC.Network and PNC.Network.ClientState or {}
    local colonyManagement = state.colonyManagement or {}
    local profile = Audience.BuildProfile(
        entry,
        player,
        relationshipID,
        colonyManagement.settlement ~= nil
    )
    return relationshipID, profile
end

local function availability(entry, targetType)
    local deathMarker = valueFromEntry(entry, "deathMarker") == true
        or valueFromEntry(entry, "alive") == false
        or valueFromEntry(entry, "healthState") == "dead"
        or targetType == "dead"
        or targetType == "deadColonist"
    if deathMarker then
        return {
            available = false,
            reason = "npc_unavailable",
            source = "entry_presence",
        }
    end

    if valueFromEntry(entry, "available") == false then
        return {
            available = false,
            reason = tostring(
                valueFromEntry(entry, "availabilityReason")
                    or "npc_unavailable"
            ),
            source = "entry_availability",
        }
    end

    return {
        available = true,
        reason = nil,
        source = "entry_presence",
    }
end

local function inlineAvailability()
    local integration = PNC.PBrainZ
    if type(integration) ~= "table" then
        return false, "pbrainz_unavailable"
    end

    if type(integration.GetProviderStatus) == "function" then
        local status = integration.GetProviderStatus()
        if type(status) ~= "table" or status.ready ~= true then
            return false, type(status) == "table"
                and (status.reason or status.status)
                or "provider_unavailable"
        end
    elseif type(integration.IsProviderAvailable) == "function" then
        if integration.IsProviderAvailable() ~= true then
            return false, "provider_unavailable"
        end
    end

    if type(integration.OpenInlineForTarget) ~= "function" then
        return false, "inline_route_unavailable"
    end
    return true, "pbrainz_inline_available"
end

local function ownershipFacts(entry)
    local snapshot = entry and entry.snapshot or {}
    local record = entry and entry.record or {}
    local orderSpec = type(record.orderSpec) == "table"
        and record.orderSpec or {}
    local orderKind = valueFromEntry(entry, "orderKind")
        or orderSpec.kind
    return {
        colonyOwned = valueFromEntry(entry, "colonyOwned") == true,
        recruited = valueFromEntry(entry, "recruited") == true,
        companion = valueFromEntry(entry, "companion") == true,
        ownedByPlayer = valueFromEntry(entry, "ownedByPlayer") == true,
        ownerUsername = valueFromEntry(entry, "ownerUsername"),
        orderKind = orderKind,
        orderSpec = copy(valueFromEntry(entry, "orderSpec") or orderSpec),
        followState = copy(valueFromEntry(entry, "followState")),
        activeBehavior = valueFromEntry(entry, "activeBehavior"),
        tacticalClass = valueFromEntry(entry, "tacticalClass")
            or snapshot.tacticalClass or record.tacticalClass,
    }
end

function TalkStart.Project(entry, player, options)
    options = type(options) == "table" and options or {}
    entry = type(entry) == "table" and entry or {}

    local targetType = Palette.ResolveType(entry)
    local relationshipID, audienceProfile = relationshipProfile(entry, player)
    local audience = Audience.Resolve(entry, relationshipID)
    local available = availability(entry, targetType)
    local hostile = audience.playerHostile == true
    local inlineAvailable, inlineReason = false, "not_hostile"
    if hostile and available.available then
        inlineAvailable, inlineReason = inlineAvailability()
    end

    local route
    local routeReason
    if not available.available then
        route = "unavailable"
        routeReason = available.reason
    elseif hostile and inlineAvailable then
        route = "hostile_inline"
        routeReason = "player_hostile_inline"
    elseif hostile then
        route = "hostile_full_conversation"
        routeReason = "player_hostile_inline_unavailable"
    else
        route = "full_conversation"
        routeReason = "native_talk_target"
    end

    return {
        schema = TalkStart.SCHEMA,
        version = TalkStart.VERSION,
        source = options.source or "production",
        entryID = tostring(entry.id or "debug-npc"),
        targetType = targetType,
        tacticalClass = tostring(
            audience.tacticalClass or valueFromEntry(entry, "tacticalClass")
                or "neutral"
        ),
        ownership = ownershipFacts(entry),
        audience = audience.audience,
        audienceReason = audience.reason,
        audienceProfile = audienceProfile,
        relationshipID = audience.relationshipID or relationshipID,
        hostile = hostile,
        hostileInlineAvailable = inlineAvailable == true,
        hostileInlineReason = inlineReason,
        availability = available,
        route = route,
        routeReason = routeReason,
        opening = {
            nodeID = "greeting",
            state = available.available and "ready" or "unavailable",
        },
    }
end

return TalkStart
