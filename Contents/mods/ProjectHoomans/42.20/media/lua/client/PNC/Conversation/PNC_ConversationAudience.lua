-- Canonical conversation audience projection.
--
-- Tactical presentation, player hostility, and relationship state are
-- different inputs. This module intentionally keeps them separate so a
-- colonist-looking NPC cannot silently imply the member conversation menu.
PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local Conversation = PNC.Conversation
local Audience = Conversation.Audience or {}
Conversation.Audience = Audience

Audience.VERSION = 1

local function valueFromEntry(entry, key)
    local snapshot = entry and entry.snapshot or {}
    local record = entry and entry.record or {}
    return entry and entry[key] or snapshot[key] or record[key]
end

local function tacticalClass(entry)
    return tostring(valueFromEntry(entry, "tacticalClass") or "neutral")
end

function Audience.IsPlayerHostile(entry)
    local hostility = valueFromEntry(entry, "hostility") or {}
    return type(hostility) == "table" and hostility.attackPlayers == true
end

function Audience.Resolve(entry, relationshipID)
    local state = tostring(relationshipID or "FirstMeet")
    local hostile = Audience.IsPlayerHostile(entry)
    local audience = "neutral"
    local reason = "relationship_non_member"

    if hostile then
        audience = "hostile"
        reason = "player_hostile"
    elseif state == "Member" then
        audience = "member"
        reason = "member_relationship"
    elseif state == "Lover" then
        audience = "special"
        reason = "lover_relationship"
    elseif state == "Acquaintance" then
        reason = "acquaintance_relationship"
    elseif state == "FirstMeet" then
        reason = "first_meet_relationship"
    else
        reason = "unrecognized_relationship"
    end

    return {
        audience = audience,
        reason = reason,
        relationshipID = state,
        tacticalClass = tacticalClass(entry),
        playerHostile = hostile,
        audiences = {
            hostile = audience == "hostile",
            neutral = audience == "neutral",
            member = audience == "member",
            special = audience == "special",
            shared = true,
        },
    }
end

function Audience.BuildProfile(entry, player, relationshipID, baseEstablished)
    local profile = Audience.Resolve(entry, relationshipID)
    profile.baseEstablished = baseEstablished == true

    local verifier = PNC.Identity and PNC.Identity.Verifier
    if verifier and verifier.BuildOwnershipSummary then
        profile.ownership = verifier.BuildOwnershipSummary(entry)
    end
    if verifier and verifier.ResolveOwnership and player then
        local owned, ownershipReason = verifier.ResolveOwnership(entry, player)
        profile.viewerOwned = owned == true
        profile.viewerOwnershipReason = ownershipReason
    end

    return profile
end

return Audience
