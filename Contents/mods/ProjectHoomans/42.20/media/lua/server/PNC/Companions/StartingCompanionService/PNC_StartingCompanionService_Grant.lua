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

function H.SpawnOffset(index)
    local column = (index - 1) % 3
    local row = math.floor((index - 1) / 3)
    return column + 1, row + 1
end

function H.EnsureOne(player, character, state, spec, index, at)
    local grant = state.grants[spec.id]
    if grant and grant.status == "granted"
        and (tonumber(grant.enrichmentVersion) or 0)
            >= Starting.ENRICHMENT_VERSION
    then
        return true, "granted"
    end
    local npcID = grant and grant.npcID
        or H.MakeNPCID(character.uuid, spec.id)
    local record = Registry.Get(npcID)
    if not record then
        local x, y, z = H.PlayerPosition(player)
        local offsetX, offsetY = H.SpawnOffset(index)
        local seed = Identity.NormalizeSeed(nil, npcID)
        local isFemale = Traits.ResolveCompanionFemale(
            spec,
            H.PlayerFemale(player),
            H.ResolveOrientation(character.uuid),
            Identity.Index(seed, "companion_sex", 2) == 1
        )
        local resolvedIdentity = H.BuildIdentity(
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
    local appearanceChanged = H.ApplySharedAppearance(player, record, spec)
    if Registry.MarkDirty then
        Registry.MarkDirty(record, "starting_companion_relationship")
    end
    local renamed = H.ApplySharedSurname(player, record, spec)
    if not H.HasCanonicalAssignment(player, record) then
        local assigned
        local reason
        assigned, reason = PNC.Recruitment.Assign(player, record, {
            source = "starting_companion",
            tags = { startingCompanion = true },
            endConversation = false,
        })
        if not assigned then return false, reason end
    end
    H.ApplyLifelongKnowledge(player, character, npcID, spec, at)
    if (renamed or appearanceChanged)
        and PNC.Network and PNC.Network.BroadcastRecord
    then
        PNC.Network.BroadcastRecord(
            record,
            appearanceChanged
                and "starting_companion_shared_appearance"
                or "starting_companion_shared_name"
        )
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
    return H.UpdateState(
        character.uuid, state, "starting_companion_granted"
    )
end

return Starting
