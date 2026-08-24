if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.StartingCompanions = PNC.StartingCompanions or {}
PNC.StartingCompanionServiceInternal =
    PNC.StartingCompanionServiceInternal or {}

local Starting = PNC.StartingCompanions
local H = PNC.StartingCompanionServiceInternal
local Traits = PNC.StartingCompanionTraits
local Identity = PNC.Identity
local Registry = PNC.Registry

function H.HasCanonicalAssignment(player, record)
    if not H.OwnerMatches(record, player)
        or not PNC.Factions or not PNC.Factions.GetPlayerFaction
        or not PNC.Factions.GetNPCAffiliation
        or not PNC.Communities or not PNC.Communities.GetNPCCommunity
    then return false end
    local playerFaction = PNC.Factions.GetPlayerFaction(player)
    local affiliation = PNC.Factions.GetNPCAffiliation(record.id)
    if not playerFaction or not affiliation
        or affiliation.factionID ~= playerFaction.id
    then return false end
    local community = PNC.Communities.GetNPCCommunity(record.id)
    return community ~= nil
        and community.status == "active"
        and community.factionID == playerFaction.id
end

function H.ApplyLifelongKnowledge(player, character, npcID, spec, at)
    local targetKey = PNC.EntityRef.ForPlayerIdentity(
        character.accountIdentity, character.uuid
    )
    if targetKey and PNC.Relationships
        and PNC.Relationships.SetInitialBaseline
    then
        local lover = spec.relationshipKind == "lover"
        local friend = spec.relationshipKind == "friend"
        PNC.Relationships.SetInitialBaseline(npcID, targetKey, {
            approval = lover and 90 or friend and 75 or 85,
            respect = lover and 75 or friend and 65 or 70,
            familiarity = friend and 90 or 100,
        }, at)
    end
    if PNC.NPCKnowledge and PNC.NPCKnowledge.DiscoverAllForPlayer then
        PNC.NPCKnowledge.DiscoverAllForPlayer(
            player, npcID, at, "lifelong_relationship", true
        )
    elseif PNC.NPCKnowledge
        and PNC.NPCKnowledge.DiscoverTopicForPlayer
    then
        PNC.NPCKnowledge.DiscoverTopicForPlayer(
            player, npcID, "identity_name", at,
            "direct_disclosure", true
        )
    end
    if PNC.NPCKnowledge
        and PNC.NPCKnowledge.BuildPlayerSnapshotForPlayer
        and PNC.Network and PNC.Network.SendNPCKnowledge
    then
        local snapshot = PNC.NPCKnowledge.BuildPlayerSnapshotForPlayer(
            player, npcID
        )
        if snapshot then
            PNC.Network.SendNPCKnowledge(
                player, snapshot, "lifelong_relationship"
            )
        end
    end
end

return Starting

