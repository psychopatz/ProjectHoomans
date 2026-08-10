if isClient and isClient() and (not isServer or not isServer()) then return end

local Discovery = PNC.WorldDiscovery
local Internal = Discovery.RadioBroadcastsInternal
local Types = PNC.WorldDiscoveryTypes

Discovery.RADIO_IDENTITY_REVEAL_CHANCE = 35

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
    return full or "unknown listener", first or "listener", last or ""
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
    local playerFull, playerFirst, playerLast = playerNames(player)
    local speaker, second = pickSpeakers(entity)
    local introduced = speaker ~= nil and revealRoll()
    return {
        entityID = entity.entityID,
        kind = entity.kind,
        groupType = entity.groupType,
        archetypeID = entity.archetypeID,
        phase = phase,
        location = location,
        settlementName = tostring(entity.name or "unknown enclave"),
        playerFirstName = playerFirst,
        playerLastName = playerLast,
        playerFullName = playerFull,
        npcFirstName = introduced and speaker.firstName or "unknown caller",
        npcLastName = introduced and speaker.lastName or "",
        npcFullName = introduced and speaker.fullName or "unknown caller",
        npc2FirstName = introduced and second and second.firstName or "",
        npc2LastName = introduced and second and second.lastName or "",
        npc2FullName = introduced and second and second.fullName or "",
        hasSecondSpeaker = second ~= nil,
        factionName = introduced and factionName(entity) or "our group",
        speakerNPCID = speaker and speaker.npcID or nil,
        identityIntroduced = introduced,
    }
end

function Internal.PersistIntroduction(player, context)
    if not context.identityIntroduced or not context.speakerNPCID
        or not PNC.NPCKnowledge
        or not PNC.NPCKnowledge.DiscoverTopicForPlayer
    then return false end
    local disclosure = PNC.NPCKnowledge.DiscoverTopicForPlayer(
        player, context.speakerNPCID, "identity_name", nil,
        "radio_disclosure"
    )
    if not disclosure then return false end
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
    return true
end

return Internal
