if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Discovery = PNC.WorldDiscovery
local Internal = Discovery.RadioBroadcastsInternal
local Types = PNC.WorldDiscoveryTypes

Discovery.RADIO_IDENTITY_REVEAL_CHANCE = 35
Discovery.RADIO_AMBIENT_VARIANTS = {
    "open_band",
    "cross_talk",
}

local function clean(value)
    value = value ~= nil and tostring(value) or nil
    if not value then return nil end
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    if value == "" then return nil end
    return value
end

local function nameParts(fullName, firstName, lastName)
    fullName = clean(fullName)
    firstName = clean(firstName)
    lastName = clean(lastName)
    if not firstName and fullName then
        firstName = string.match(fullName, "^(%S+)")
    end
    if not lastName and fullName then
        lastName = string.match(fullName, "^%S+%s+(.+)$")
    end
    if not fullName then
        fullName = clean(table.concat({ firstName or "", lastName or "" }, " "))
    end
    return fullName, firstName, lastName
end

local function npcNames(npcID)
    local record = npcID and PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(npcID) or nil
    if not record or record.alive == false then return nil end
    local summary = PNC.Identity and PNC.Identity.GetCharacterSummary
        and PNC.Identity.GetCharacterSummary(record) or {}
    local survivor = summary.survivor or record.identity
        and record.identity.survivor or {}
    local full, first, last = nameParts(
        summary.displayName or record.name,
        survivor.forename or record.forename,
        survivor.surname or record.surname
    )
    return {
        npcID = tostring(npcID),
        fullName = full or "Unknown survivor",
        firstName = first or full or "Unknown",
        lastName = last or "",
    }
end

local function playerNames(player)
    local context = PNC.PlayerContext and PNC.PlayerContext.Resolve
        and PNC.PlayerContext.Resolve(player, "radio_discovery") or {}
    local descriptor = player and player.getDescriptor
        and player:getDescriptor() or nil
    local full, first, last = nameParts(
        context and context.displayName,
        context and context.forename
            or descriptor and descriptor.getForename
                and descriptor:getForename(),
        context and context.surname
            or descriptor and descriptor.getSurname
                and descriptor:getSurname()
    )
    if not full and player and player.getUsername then
        full, first, last = nameParts(player:getUsername())
    end
    return full or "unknown listener", first or "listener", last or "",
        context
end

local function playerKnowsSpeakerName(playerContext, speakerID)
    if not playerContext or not playerContext.characterUUID
        or not speakerID
        or not PNC.NPCKnowledge
        or type(PNC.NPCKnowledge.GetDescriptor) ~= "function"
    then return false end
    local ok, descriptor = pcall(
        PNC.NPCKnowledge.GetDescriptor,
        playerContext.characterUUID, speakerID, "identity.name"
    )
    return ok and descriptor ~= nil
end

local function memberIDs(entity)
    local output = {}
    if entity.kind == Types.KIND_SETTLEMENT then
        local community = PNC.Communities and PNC.Communities.Get
            and PNC.Communities.Get(entity.entityID) or nil
        local seen = {}
        if community and community.leaderNPCID then
            local leader = tostring(community.leaderNPCID)
            output[#output + 1], seen[leader] = leader, true
        end
        for npcID, included in pairs(community and community.memberIDs or {}) do
            npcID = tostring(npcID)
            if included == true and not seen[npcID] then
                output[#output + 1], seen[npcID] = npcID, true
            end
        end
    else
        local group = PNC.AbstractGroups and PNC.AbstractGroups.Get
            and PNC.AbstractGroups.Get(entity.entityID) or nil
        for _, npcID in ipairs(group and group.memberIds or {}) do
            output[#output + 1] = tostring(npcID)
        end
    end
    return output
end

local function pickSpeakers(entity)
    local candidates = {}
    for _, npcID in ipairs(memberIDs(entity)) do
        local identity = npcNames(npcID)
        if identity then candidates[#candidates + 1] = identity end
    end
    if #candidates == 0 then return nil, nil end
    local index
    if type(Discovery.RadioRandomIndex) == "function" then
        index = Discovery.RadioRandomIndex(#candidates)
    elseif ZombRand then
        index = ZombRand(#candidates) + 1
    else
        index = math.random(#candidates)
    end
    index = math.max(1, math.min(#candidates, tonumber(index) or 1))
    local first = candidates[index]
    local second = #candidates > 1
        and candidates[(index % #candidates) + 1] or nil
    return first, second
end

local function revealRoll()
    local roll
    if type(Discovery.RadioIdentityRevealRoll) == "function" then
        roll = Discovery.RadioIdentityRevealRoll()
    elseif ZombRand then
        roll = ZombRand(100)
    else
        roll = math.random(0, 99)
    end
    return (tonumber(roll) or 99)
        < Discovery.RADIO_IDENTITY_REVEAL_CHANCE
end

local function factionName(entity)
    local faction = entity.factionID and PNC.Factions
        and PNC.Factions.Get and PNC.Factions.Get(entity.factionID) or nil
    return clean(faction and faction.name) or "an unnamed group"
end

function Discovery.BuildRadioTemplateContext(player, entity, phase)
    if not entity then return nil end
    local exact = phase >= Types.PHASE_LOCATED
    local location = exact
        and tostring(math.floor(entity.x)) .. ", "
            .. tostring(math.floor(entity.y))
        or "grid " .. tostring(math.floor(entity.x / 100)) .. ", "
            .. tostring(math.floor(entity.y / 100))
    local playerFull, playerFirst, playerLast, playerContext = playerNames(player)
    local speaker, second = pickSpeakers(entity)
    local playerNameKnown = playerKnowsSpeakerName(
        playerContext, speaker and speaker.npcID or nil
    )
    local introduced = speaker ~= nil and revealRoll()
    return {
        entityID = entity.entityID,
        kind = entity.kind,
        groupType = entity.groupType,
        archetypeID = entity.archetypeID,
        phase = phase,
        location = location,
        settlementName = tostring(entity.name or "unknown enclave"),
        -- Do not put the player's real name in the template context unless
        -- this exact selected speaker is already known to this character.
        playerFirstName = playerNameKnown and playerFirst or "listener",
        playerLastName = playerNameKnown and playerLast or "",
        playerFullName = playerNameKnown and playerFull or "unknown listener",
        playerNameKnown = playerNameKnown,
        npcFirstName = introduced and speaker.firstName or "unknown caller",
        npcLastName = introduced and speaker.lastName or "",
        npcFullName = introduced and speaker.fullName or "unknown caller",
        npc2FirstName = introduced and second and second.firstName or "",
        npc2LastName = introduced and second and second.lastName or "",
        npc2FullName = introduced and second and second.fullName or "",
        hasSecondSpeaker = second ~= nil,
        factionName = introduced and factionName(entity) or "our group",
        speakerNPCID = speaker and speaker.npcID or nil,
        secondarySpeakerNPCID = second and second.npcID or nil,
        identityIntroduced = introduced,
    }
end

local function nextAmbientVariant()
    local state = Discovery.RadioAmbientState
        or { lastAiredAt = nil, hasAired = false,
            lastVariant = nil, sequence = 0 }
    Discovery.RadioAmbientState = state
    local previous = tostring(state.lastVariant or "")
    local variant = Discovery.RADIO_AMBIENT_VARIANTS[1]
    if previous == variant then
        variant = Discovery.RADIO_AMBIENT_VARIANTS[2]
    end
    state.lastVariant = variant
    state.sequence = (tonumber(state.sequence) or 0) + 1
    return variant, state.sequence
end

function Discovery.BuildAmbientTemplateContext()
    local variant, sequence = nextAmbientVariant()
    local prefix = "radio:ambient:" .. tostring(sequence)
    return {
        eventType = "ambient",
        ambientVariant = variant,
        ambientSequence = sequence,
        -- These IDs only keep the two generic radio voices consistent through
        -- the client TTS bridge. They are deliberately not NPC identities.
        speakerNPCID = prefix .. ":primary",
        secondarySpeakerNPCID = prefix .. ":secondary",
        hasSecondSpeaker = variant == "cross_talk",
    }
end

function Internal.PersistIntroduction(player, context)
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
    if not known("identity.name") then
        changed = knowledge.DiscoverTopicForPlayer(
            player, context.speakerNPCID, "identity_name", nil,
            "radio_disclosure"
        ) ~= nil or changed
    end
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
