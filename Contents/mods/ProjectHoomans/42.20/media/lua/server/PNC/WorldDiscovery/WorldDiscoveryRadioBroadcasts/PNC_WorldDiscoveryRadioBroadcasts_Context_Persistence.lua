if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Discovery = PNC.WorldDiscovery
local Internal = Discovery.RadioBroadcastsInternal
local clean = Internal.Clean

function Internal.PersistIntroduction(player, context)
    -- The spoken name is flavor. Only the faction claim is persisted here.
    if not context.identityIntroduced or not context.speakerNPCID
    then return false end
    local factionChanged = false
    local disclosedFaction = clean(context.factionName)
    if disclosedFaction and disclosedFaction ~= "our group"
        and disclosedFaction ~= "an unnamed group"
        and context.kind and context.entityID
        and Discovery.MarkFactionRevealed
    then
        local entity = Discovery.ResolveEntity(
            context.kind, context.entityID)
        if entity then
            local _, reason = Discovery.MarkFactionRevealed(
                player, entity, disclosedFaction,
                "radio_disclosure", true)
            factionChanged = reason == "advanced"
        end
    end
    if not PNC.NPCKnowledge
        or not PNC.NPCKnowledge.DiscoverTopicForPlayer
    then
        if factionChanged then Discovery.Save() end
        return factionChanged
    end
    local characterContext = PNC.PlayerContext
        and PNC.PlayerContext.Resolve
        and PNC.PlayerContext.Resolve(player, "radio_knowledge") or nil
    local characterUUID = characterContext
        and characterContext.characterUUID or nil
    local knowledge = PNC.NPCKnowledge
    local function known(descriptorID)
        if not characterUUID or type(knowledge.GetDescriptor) ~= "function" then
            return false
        end
        local ok, value = pcall(knowledge.GetDescriptor,
            characterUUID, context.speakerNPCID, descriptorID)
        return ok and value ~= nil
    end
    local changed = false
    if not known("faction.identity") then
        changed = knowledge.DiscoverTopicForPlayer(
            player, context.speakerNPCID, "faction", nil,
            "radio_disclosure"
        ) ~= nil or changed
    end
    if not changed then
        if factionChanged then Discovery.Save() end
        return factionChanged
    end
    if PNC.Network and PNC.Network.SendNPCKnowledge
        and PNC.NPCKnowledge.BuildPlayerSnapshotForPlayer
    then
        local snapshot = PNC.NPCKnowledge.BuildPlayerSnapshotForPlayer(
            player, context.speakerNPCID
        )
        if snapshot then
            PNC.Network.SendNPCKnowledge(player, snapshot, "radio_disclosure")
        end
    end
    if factionChanged then Discovery.Save() end
    return changed or factionChanged
end

return Internal
