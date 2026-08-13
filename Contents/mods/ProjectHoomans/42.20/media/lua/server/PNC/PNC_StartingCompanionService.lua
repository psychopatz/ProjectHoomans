-- Server-authoritative, exactly-once companion grants from creation traits.

if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.StartingCompanions = PNC.StartingCompanions or {}

local Starting = PNC.StartingCompanions
local Traits = PNC.StartingCompanionTraits
local Identity = PNC.Identity
local Registry = PNC.Registry

Starting.NextRetryAt = Starting.NextRetryAt or {}
Starting.RETRY_DELAY_MS = 5000
Starting.ENRICHMENT_VERSION = 3

local function nowMs()
    return PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
end

local function playerFemale(player)
    if player and player.isFemale then
        local ok, value = pcall(player.isFemale, player)
        if ok then return value == true end
    end
    local descriptor = player and player.getDescriptor
        and player:getDescriptor() or nil
    return descriptor and descriptor.isFemale
        and descriptor:isFemale() == true or false
end

local function playerSurname(player)
    local descriptor = player and player.getDescriptor
        and player:getDescriptor() or nil
    local surname = descriptor and descriptor.getSurname
        and descriptor:getSurname() or nil
    surname = tostring(surname or "")
    return surname ~= "" and surname or nil
end

local function playerPosition(player)
    return player and player.getX and player:getX() or 0,
        player and player.getY and player:getY() or 0,
        player and player.getZ and player:getZ() or 0
end

local function persist(reason)
    if PNC.PersistenceCoordinator and PNC.PersistenceCoordinator.Commit then
        return PNC.PersistenceCoordinator.Commit(reason)
    end
    local saved, why = PNC.PlayerCharacters.Save()
    if saved == false and why ~= "not_dirty" then return false, why end
    return true, "committed"
end

local function updateState(characterUUID, state, reason)
    local _, why = PNC.PlayerCharacters.ApplyStartingCompanionState(
        characterUUID, state
    )
    if why ~= "updated" and why ~= "unchanged" then return false, why end
    return persist(reason)
end

local function ownerMatches(record, player)
    if not record or record.recruited ~= true then return false end
    local username = player and player.getUsername
        and player:getUsername() or nil
    return username ~= nil and record.ownerUsername == username
end

local function resolveOrientation(characterUUID)
    local profile = PNC.SocialProfiles
        and PNC.SocialProfiles.GetPlayerProfile
        and PNC.SocialProfiles.GetPlayerProfile(characterUUID) or nil
    return profile and profile.orientation or "straight"
end

local function safeID(value)
    value = string.lower(tostring(value or "companion"))
    return string.gsub(value, "[^%w_%-]", "_")
end

local function makeNPCID(characterUUID, traitID)
    return "pnc_starting_" .. tostring(characterUUID)
        .. "_" .. safeID(traitID)
end

local function sharesSurname(spec)
    return spec and spec.sharesSurname == true
end

local function buildIdentity(player, npcID, spec, isFemale, seed)
    if not Identity.GenerateResolvedIdentity then return nil end
    local identity = Identity.GenerateResolvedIdentity({
        id = npcID,
        isFemale = isFemale,
        identitySeed = seed,
        archetypeID = "General",
    })
    local surname = sharesSurname(spec) and playerSurname(player) or nil
    if surname and identity then
        identity.survivor = identity.survivor or {}
        local forename = tostring(identity.survivor.forename or "")
        if forename == "" then
            forename = string.match(
                tostring(identity.displayName or ""), "^(%S+)"
            ) or "Alex"
        end
        identity.survivor.forename = forename
        identity.survivor.surname = surname
        identity.displayName = forename .. " " .. surname
    end
    return identity
end

local function applySharedSurname(player, record, spec)
    local surname = sharesSurname(spec) and playerSurname(player) or nil
    local identity = record and record.identity or nil
    if not surname or not identity then return false end
    identity.survivor = identity.survivor or {}
    local forename = tostring(identity.survivor.forename or "")
    if forename == "" then
        forename = string.match(tostring(identity.displayName or ""), "^(%S+)")
            or "Alex"
    end
    if identity.survivor.surname == surname
        and identity.displayName == forename .. " " .. surname
    then
        return false
    end
    identity.survivor.forename = forename
    identity.survivor.surname = surname
    identity.displayName = forename .. " " .. surname
    record.name = identity.displayName
    if Registry.MarkDirty then
        Registry.MarkDirty(record, "starting_companion_shared_name")
    end
    return true
end

local function hasCanonicalAssignment(player, record)
    if not ownerMatches(record, player)
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

local function applyLifelongKnowledge(player, character, npcID, spec, at)
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

local function spawnOffset(index)
    local column = (index - 1) % 3
    local row = math.floor((index - 1) / 3)
    return column + 1, row + 1
end

local function ensureOne(player, character, state, spec, index, at)
    local grant = state.grants[spec.id]
    if grant and grant.status == "granted"
        and (tonumber(grant.enrichmentVersion) or 0)
            >= Starting.ENRICHMENT_VERSION
    then
        return true, "granted"
    end
    local npcID = grant and grant.npcID
        or makeNPCID(character.uuid, spec.id)
    local record = Registry.Get(npcID)
    if not record then
        local x, y, z = playerPosition(player)
        local offsetX, offsetY = spawnOffset(index)
        local seed = Identity.NormalizeSeed(nil, npcID)
        local isFemale = Traits.ResolveCompanionFemale(
            spec,
            playerFemale(player),
            resolveOrientation(character.uuid),
            Identity.Index(seed, "companion_sex", 2) == 1
        )
        local resolvedIdentity = buildIdentity(
            player, npcID, spec, isFemale, seed
        )
        record = PNC.API.Spawn({
            id = npcID,
            archetypeID = "General",
            faction = PNC.Const.FACTION_NEUTRAL,
            isFemale = isFemale,
            identitySeed = seed,
            identity = resolvedIdentity,
            x = x + offsetX,
            y = y + offsetY,
            z = z,
            forceLive = true,
            persist = true,
            generation = {
                source = "starting_companion_trait",
                traitID = spec.id,
                relationshipKind = spec.relationshipKind,
                relationshipSince = "before_outbreak",
                playerCharacterUUID = character.uuid,
            },
        })
        if not record then return false, "spawn_failed" end
    end
    record.generation = record.generation or {}
    record.generation.source = "starting_companion_trait"
    record.generation.traitID = spec.id
    record.generation.relationshipKind = spec.relationshipKind
    record.generation.relationshipSince = "before_outbreak"
    record.generation.playerCharacterUUID = character.uuid
    if Registry.MarkDirty then
        Registry.MarkDirty(record, "starting_companion_relationship")
    end
    local renamed = applySharedSurname(player, record, spec)
    if not hasCanonicalAssignment(player, record) then
        local assigned
        local reason
        assigned, reason = PNC.Recruitment.Assign(player, record, {
            source = "starting_companion",
            tags = { startingCompanion = true },
            endConversation = false,
        })
        if not assigned then return false, reason end
    end
    applyLifelongKnowledge(player, character, npcID, spec, at)
    if renamed and PNC.Network and PNC.Network.BroadcastRecord then
        PNC.Network.BroadcastRecord(record, "starting_companion_shared_name")
    end
    state.grants[spec.id] = {
        status = "granted",
        traitID = spec.id,
        relationshipKind = spec.relationshipKind,
        npcID = npcID,
        selectedAt = grant and grant.selectedAt or at,
        grantedAt = at,
        enrichmentVersion = Starting.ENRICHMENT_VERSION,
    }
    return updateState(
        character.uuid, state, "starting_companion_granted"
    )
end

local function definitionsForState(state)
    local output = {}
    for index = 1, #Traits.DEFINITIONS do
        local spec = Traits.DEFINITIONS[index]
        if state.grants[spec.id] then output[#output + 1] = spec end
    end
    return output
end

function Starting.Ensure(player, characterUUID, at)
    if not player or not characterUUID then return false, "invalid_player" end
    local now = nowMs()
    if (Starting.NextRetryAt[characterUUID] or 0) > now then
        return false, "retry_throttled"
    end
    local character = PNC.PlayerCharacters.GetRegistryRecord(characterUUID)
    if not character then return false, "character_not_found" end
    local state = PNC.PlayerCharacterTypes.NormalizeStartingCompanionState(
        character.startingCompanions
    )
    local selections
    local reason
    if not state.resolved then
        selections, reason = Traits.ResolveSelections(player)
        if not selections then return false, reason or "traits_not_ready" end
        state.resolved = true
        for index = 1, #selections do
            local spec = selections[index]
            state.grants[spec.id] = {
                status = "pending",
                traitID = spec.id,
                relationshipKind = spec.relationshipKind,
                npcID = makeNPCID(characterUUID, spec.id),
                selectedAt = at,
                grantedAt = 0,
                enrichmentVersion = 0,
            }
        end
        local recorded
        recorded, reason = updateState(
            characterUUID, state, "starting_companion_selection"
        )
        if not recorded then
            Starting.NextRetryAt[characterUUID] =
                now + Starting.RETRY_DELAY_MS
            return false, reason
        end
    else
        selections = definitionsForState(state)
    end
    if #selections == 0 then return false, "none" end

    local needsWork = false
    for index = 1, #selections do
        local grant = state.grants[selections[index].id]
        if not grant or grant.status ~= "granted"
            or (tonumber(grant.enrichmentVersion) or 0)
                < Starting.ENRICHMENT_VERSION
        then
            needsWork = true
            break
        end
    end
    if not needsWork then return false, "granted" end

    local granted = {}
    local firstFailure
    for index = 1, #selections do
        local spec = selections[index]
        local ok
        ok, reason = ensureOne(
            player, character, state, spec, index, at
        )
        if ok then
            granted[#granted + 1] = state.grants[spec.id].npcID
        else
            firstFailure = firstFailure or reason
        end
    end
    if firstFailure then
        Starting.NextRetryAt[characterUUID] = now + Starting.RETRY_DELAY_MS
        return false, firstFailure, { npcIDs = granted }
    end
    Starting.NextRetryAt[characterUUID] = nil
    if PNC.Core and PNC.Core.LogInfo then
        PNC.Core.LogInfo("PNC starting companions ready character="
            .. tostring(characterUUID) .. " count=" .. tostring(#granted))
    end
    return true, "granted", { npcIDs = granted }
end

return Starting
