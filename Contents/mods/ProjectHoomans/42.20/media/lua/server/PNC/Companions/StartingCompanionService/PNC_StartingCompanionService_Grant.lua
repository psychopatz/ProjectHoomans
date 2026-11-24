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

function H.EnsureOne(player, character, state, spec, index, at, options)
    local grant = state.grants[spec.id]
    local npcID
    local record
    local customization
    local resolvedDefinition
    local resolvedPlan
    local resolveReason
    local spawnDefinition
    options = type(options) == "table" and options or {}
    customization = options.blueprints
        and options.blueprints[spec.id] or nil
    if not grant then return false, "starting_companion_grant_missing" end
    npcID = grant.npcID
    record = npcID and Registry.Get(npcID) or nil
    local coreProvider = PNC.Persistence and PNC.Persistence.CoreProvider or nil
    if not record
        and npcID
        and coreProvider
        and type(coreProvider.IsAliveCoreActor) == "function"
        and type(coreProvider.PromoteCoreActor) == "function"
        and coreProvider.IsAliveCoreActor(npcID, PsychopatzCore)
    then
        record = coreProvider.PromoteCoreActor(
            npcID,
            PsychopatzCore,
            { reason = "starting_companion_ensure" }
        )
    end
    if not record
        and grant and grant.status == "granted"
        and npcID
        and coreProvider
        and type(coreProvider.IsRetiredCoreActor) == "function"
        and coreProvider.IsRetiredCoreActor(npcID, PsychopatzCore) == true
    then
        return true, "companion_retired"
    end
    if record and record.colonistDeparture
        and record.colonistDeparture.state == "completed"
    then
        return false, "companion_departed"
    end
    if grant and grant.status == "granted"
        and (tonumber(grant.enrichmentVersion) or 0)
            >= Starting.ENRICHMENT_VERSION
        and record
        and H.HasCanonicalAssignment(player, record)
    then
        return true, "granted"
    end
    if not record then
        local x, y, z = H.PlayerPosition(player)
        local offsetX, offsetY = H.SpawnOffset(index)
        local seedID = H.MakeNPCSeedID(character.uuid, spec.id)
        local seed = Identity.NormalizeSeed(nil, seedID)
        local isFemale = Traits.ResolveCompanionFemale(
            spec,
            H.PlayerFemale(player),
            H.ResolveOrientation(character.uuid),
            Identity.Index(seed, "companion_sex", 2) == 1
        )
        local resolvedIdentity = H.BuildIdentity(
            player, seedID, spec, isFemale, seed
        )
        if customization and H.ResolveAuthoringDefinition then
            resolvedDefinition, resolvedPlan = H.ResolveAuthoringDefinition(
                player,
                character,
                seedID,
                spec,
                seed,
                customization
            )
            if not resolvedDefinition then
                return false, resolvedPlan or "starter_resolution_failed"
            end
            resolvedIdentity = resolvedDefinition.identity
            isFemale = resolvedDefinition.isFemale == true
        end
        if not npcID then
            npcID = H.MakeNPCID(character.uuid, spec.id, resolvedIdentity)
            if not npcID then return false, "npc_id_generation_failed" end
            grant.npcID = npcID
            local recorded, recordReason = H.UpdateState(
                character.uuid, state, "starting_companion_id_assigned"
            )
            if not recorded then
                grant.npcID = nil
                return false, recordReason
            end
        end
        spawnDefinition = resolvedDefinition or {}
        spawnDefinition.id = npcID
        spawnDefinition.archetypeID = spawnDefinition.archetypeID or "General"
        spawnDefinition.tacticalClass = spawnDefinition.tacticalClass
            or PNC.Const.TACTICAL_CLASS_NEUTRAL
        spawnDefinition.isFemale = isFemale
        spawnDefinition.identitySeed = spawnDefinition.identitySeed or seed
        spawnDefinition.identity = resolvedIdentity
        spawnDefinition.x = x + offsetX
        spawnDefinition.y = y + offsetY
        spawnDefinition.z = z
        spawnDefinition.forceLive = true
        spawnDefinition.persist = true
        spawnDefinition.generation = {
            source = "starting_companion_trait",
            traitID = spec.id,
            relationshipKind = spec.relationshipKind,
            relationshipSince = "before_outbreak",
            playerCharacterUUID = character.uuid,
        }
        local spawnReason
        record, spawnReason = PNC.API.Spawn(spawnDefinition, function(created)
            return PNC.Recruitment.Assign(player, created, {
                source = "starting_companion",
                endConversation = false,
                publish = false,
            })
        end)
        if not record then return false, spawnReason or "spawn_failed" end
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
        relationshipKeyVersion = Starting.RELATIONSHIP_KEY_VERSION,
    }
    return H.UpdateState(
        character.uuid, state, "starting_companion_granted"
    )
end

return Starting
