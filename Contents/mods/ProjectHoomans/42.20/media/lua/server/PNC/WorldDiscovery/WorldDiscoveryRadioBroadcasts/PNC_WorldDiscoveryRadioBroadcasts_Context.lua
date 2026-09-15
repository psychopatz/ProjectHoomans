if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Discovery = PNC.WorldDiscovery
local Internal = Discovery.RadioBroadcastsInternal
local Types = PNC.WorldDiscoveryTypes
require "PNC/Core/Identity/PNC_FlavorAddress"
local FlavorAddress = PNC.FlavorAddress

Discovery.RADIO_IDENTITY_REVEAL_CHANCE = 35
Discovery.RADIO_ARGUMENT_CHANCE = 25
Discovery.RADIO_CONFLICT_CHANCE = 15
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
        identitySeed = summary.identitySeed or record.identitySeed,
        isFemale = summary.isFemale == true or record.isFemale == true,
        recruited = record.recruited == true,
        tacticalClass = PNC.Types and PNC.Types.ResolveTacticalClass
            and PNC.Types.ResolveTacticalClass(record)
            or tostring(record.tacticalClass or "neutral"),
    }
end

local function playerContextFor(player)
    return PNC.PlayerContext and PNC.PlayerContext.Resolve
        and PNC.PlayerContext.Resolve(player, "radio_discovery") or {}
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

local function withinRadioRange(player, entity)
    if not player or not entity then return false end
    if Discovery.Internal and Discovery.Internal.DistanceSquared then
        return Discovery.Internal.DistanceSquared(player, entity)
            <= Discovery.RADIO_RANGE * Discovery.RADIO_RANGE
    end
    if type(player.getX) ~= "function"
        or type(player.getY) ~= "function"
    then
        return false
    end
    local dx = (tonumber(player:getX()) or 0) - (tonumber(entity.x) or 0)
    local dy = (tonumber(player:getY()) or 0) - (tonumber(entity.y) or 0)
    return dx * dx + dy * dy
        <= Discovery.RADIO_RANGE * Discovery.RADIO_RANGE
end

local function playerFactionID(player)
    local faction
    if not PNC.Factions or type(PNC.Factions.GetPlayerFaction) ~= "function"
    then
        return nil
    end
    faction = PNC.Factions.GetPlayerFaction(player)
    return faction and faction.id and tostring(faction.id) or nil
end

local function factionID(entity)
    return entity and entity.factionID and tostring(entity.factionID) or nil
end

local function factionArchetype(entity)
    local archetype = entity and entity.archetypeID
    if archetype then return tostring(archetype) end
    local faction = entity and entity.factionID and PNC.Factions
        and PNC.Factions.Get and PNC.Factions.Get(entity.factionID) or nil
    return faction and faction.archetypeID
        and tostring(faction.archetypeID) or nil
end

local function participantTraits(entity, speaker, playerFaction)
    local isLooter = factionArchetype(entity) == "looter"
    local isPlayerColonist = playerFaction ~= nil
        and factionID(entity) == playerFaction
        and (speaker.recruited == true
            or speaker.tacticalClass == "colonist")
    local isNeutral = not isLooter
        and not isPlayerColonist
        and speaker.tacticalClass == "neutral"
    return {
        isLooter = isLooter,
        isPlayerColonist = isPlayerColonist,
        isNeutral = isNeutral,
    }
end

local function conflictScenario(primaryEntity, primarySpeaker,
    secondaryEntity, secondarySpeaker, playerFaction)
    local primary = participantTraits(
        primaryEntity, primarySpeaker, playerFaction)
    local secondary = participantTraits(
        secondaryEntity, secondarySpeaker, playerFaction)
    if (primary.isLooter and secondary.isNeutral)
        or (secondary.isLooter and primary.isNeutral)
    then
        return "looter_neutral", 300
    end
    if (primary.isLooter and secondary.isPlayerColonist)
        or (secondary.isLooter and primary.isPlayerColonist)
    then
        return "looter_colonist", 200
    end
    return "cross_faction", 100
end

local function conflictRoll()
    local roll
    if type(Discovery.RadioConflictRoll) == "function" then
        roll = Discovery.RadioConflictRoll()
    elseif ZombRand then
        roll = ZombRand(100)
    else
        roll = math.random(0, 99)
    end
    return (tonumber(roll) or 99)
        < Discovery.RADIO_CONFLICT_CHANCE
end

local function pickConflictParticipant(player, entity, primarySpeaker)
    local playerFaction = playerFactionID(player)
    local candidates = {}
    for _, candidate in ipairs(Discovery.ListWorldEntities()) do
        local candidateFaction = factionID(candidate)
        if candidateFaction
            and candidateFaction ~= factionID(entity)
            and withinRadioRange(player, candidate)
        then
            local secondarySpeaker = pickSpeakers(candidate)
            if secondarySpeaker and secondarySpeaker.npcID
                ~= primarySpeaker.npcID
            then
                local scenario, score = conflictScenario(
                    entity, primarySpeaker,
                    candidate, secondarySpeaker,
                    playerFaction
                )
                candidates[#candidates + 1] = {
                    entity = candidate,
                    speaker = secondarySpeaker,
                    scenario = scenario,
                    score = score,
                }
            end
        end
    end
    if #candidates == 0 then return nil end
    table.sort(candidates, function(left, right)
        if left.score ~= right.score then return left.score > right.score end
        if left.entity.kind ~= right.entity.kind then
            return left.entity.kind < right.entity.kind
        end
        return left.entity.entityID < right.entity.entityID
    end)
    local bestScore = candidates[1].score
    local best = {}
    for _, candidate in ipairs(candidates) do
        if candidate.score == bestScore then
            best[#best + 1] = candidate
        end
    end
    local index
    if type(Discovery.RadioRandomIndex) == "function" then
        index = Discovery.RadioRandomIndex(#best)
    elseif ZombRand then
        index = ZombRand(#best) + 1
    else
        index = math.random(#best)
    end
    index = math.max(1, math.min(#best, tonumber(index) or 1))
    return best[index]
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

local function argumentRoll()
    local roll
    if type(Discovery.RadioArgumentRoll) == "function" then
        roll = Discovery.RadioArgumentRoll()
    elseif ZombRand then
        roll = ZombRand(100)
    else
        roll = math.random(0, 99)
    end
    return (tonumber(roll) or 99)
        < Discovery.RADIO_ARGUMENT_CHANCE
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
    local playerContext = playerContextFor(player)
    local speaker, second = pickSpeakers(entity)
    local conflict = speaker and pickConflictParticipant(
        player, entity, speaker) or nil
    local conflictVariant = conflict ~= nil and conflictRoll() or false
    if not conflictVariant then conflict = nil end
    local playerAddress = FlavorAddress.ResolveForNPC({
        npcID = speaker and speaker.npcID or "radio:unknown",
        npcIdentitySeed = speaker and speaker.identitySeed,
        player = player,
        playerContext = playerContext,
        playerUUID = playerContext and playerContext.characterUUID,
        state = playerContext,
    })
    local introduced = speaker ~= nil and revealRoll()
    local argumentVariant = not conflictVariant
        and second ~= nil and argumentRoll() or false
    local activeSecond = conflictVariant and conflict.speaker or second
    return {
        entityID = entity.entityID,
        kind = entity.kind,
        groupType = entity.groupType,
        archetypeID = entity.archetypeID,
        phase = phase,
        location = location,
        settlementName = tostring(entity.name or "unknown enclave"),
        playerFirstName = playerAddress.firstName,
        playerLastName = playerAddress.lastName,
        playerSurname = playerAddress.surname,
        playerFullName = playerAddress.fullName,
        playerAddressName = playerAddress.addressName,
        playerNameKnown = playerAddress.known,
        playerIsFemale = playerAddress.isFemale,
        playerNicknameID = playerAddress.nicknameID,
        npcIdentitySeed = speaker and speaker.identitySeed,
        npcFirstName = introduced and speaker.firstName or "unknown caller",
        npcLastName = introduced and speaker.lastName or "",
        npcFullName = introduced and speaker.fullName or "unknown caller",
        npc2FirstName = introduced and second and second.firstName or "",
        npc2LastName = introduced and second and second.lastName or "",
        npc2FullName = introduced and second and second.fullName or "",
        hasSecondSpeaker = activeSecond ~= nil,
        factionName = introduced and factionName(entity) or "our group",
        speakerNPCID = speaker and speaker.npcID or nil,
        secondarySpeakerNPCID = activeSecond and activeSecond.npcID or nil,
        -- Presentation-only flag: the broadcast may speak the NPC's name,
        -- but radio disclosure never grants identity.name knowledge.
        identityIntroduced = introduced,
        argumentVariant = argumentVariant,
        -- Argument names are deliberately separate from the knowledge-facing
        -- identity fields. They exist only for the named flavor exchange.
        argumentPrimaryName = argumentVariant and speaker
            and speaker.firstName or "",
        argumentSecondaryName = argumentVariant and second
            and second.firstName or "",
        -- Cross-faction conflict names are presentation-only. They are kept
        -- separate from the normal identity fields and never persisted as
        -- identity.name knowledge.
        conflictVariant = conflictVariant,
        conflictScenario = conflict and conflict.scenario or nil,
        conflictPrimaryName = conflictVariant and speaker
            and speaker.firstName or "",
        conflictSecondaryName = conflictVariant and conflict.speaker
            and conflict.speaker.firstName or "",
        conflictPrimaryFactionID = conflictVariant
            and factionID(entity) or nil,
        conflictSecondaryFactionID = conflictVariant
            and factionID(conflict.entity) or nil,
        conflictSecondaryEntityID = conflictVariant
            and conflict.entity.entityID or nil,
        conflictSecondaryKind = conflictVariant
            and conflict.entity.kind or nil,
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
