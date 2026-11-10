-- Production faction, player, and knowledge registry hydration.

local function install(ProductionRehydration)
    local Internal = ProductionRehydration.Internal

local function loadProductionOrganizations(context)
    local Values = context.Values
    local registries = Internal.RawRegistriesFor(context)
    local factions = registries.factions
    local communities = registries.communities
    local status = {
        schema = "semantic.production_faction_rehydration.v1",
        source = "ProjectHoomans.rawRegistries",
        status = "NO_REGISTRIES",
        factionRegistry = "MISSING",
        communityRegistry = "MISSING",
    }

    Internal.ResetOrganizationState()
    if type(factions) == "table"
        and PNC.Factions
        and type(PNC.Factions.LoadRaw) == "function"
    then
        local ok, loaded, reason = pcall(
            PNC.Factions.LoadRaw,
            Values.productionCopy(factions)
        )
        if not ok or loaded ~= true then
            return nil, "faction_load_failed:" .. tostring(
                ok and reason or loaded
            )
        end
        status.factionRegistry = "HYDRATED"
        status.factionLoadOwner = "PNC.Factions.LoadRaw"
    elseif type(factions) == "table" then
        return nil, "production_faction_loader_unavailable"
    end

    if type(communities) == "table"
        and PNC.Communities
        and type(PNC.Communities.LoadRaw) == "function"
    then
        local ok, loaded, reason = pcall(
            PNC.Communities.LoadRaw,
            Values.productionCopy(communities)
        )
        if not ok or loaded ~= true then
            return nil, "community_load_failed:" .. tostring(
                ok and reason or loaded
            )
        end
        status.communityRegistry = "HYDRATED"
        status.communityLoadOwner = "PNC.Communities.LoadRaw"
    elseif type(communities) == "table" then
        return nil, "production_community_loader_unavailable"
    end

    if status.factionRegistry == "HYDRATED"
        or status.communityRegistry == "HYDRATED"
    then
        status.status = "HYDRATED"
    end
    return status
end

local function loadProductionPlayerCharacters(context)
    local Runtime = context.Runtime
    local Values = context.Values
    local raw = Internal.RawPlayerRegistryFor(context)
    local status = {
        schema = "semantic.production_player_rehydration.v1",
        source = "ProjectHoomans.rawRegistries.playerCharacters",
        status = "MISSING",
        loadOwner = "PNC.PlayerCharacters.Load",
    }
    if not PNC or not PNC.PlayerCharacters
        or type(PNC.PlayerCharacters.Load) ~= "function"
    then
        return nil, "production_player_loader_unavailable"
    end

    -- ModData is the production persistence boundary.  This table belongs to
    -- the isolated worker runtime; it is never connected to the source save.
    Runtime.playerModData = {}
    local key = PNC.PlayerCharacterConstants
        and PNC.PlayerCharacterConstants.REGISTRY_MODDATA_KEY
        or "PNC_PlayerCharacters"
    Runtime.modData[key] = type(raw) == "table"
        and Values.productionCopy(raw) or nil
    PNC.PlayerCharacters.Loaded = false
    PNC.PlayerCharacters.Dirty = false
    if type(PNC.PlayerCharacters.ResetRuntimeBindings) == "function" then
        PNC.PlayerCharacters.ResetRuntimeBindings("harness_rehydration")
    end

    local ok = pcall(PNC.PlayerCharacters.Load)
    if not ok then
        return nil, "production_player_load_failed"
    end

    -- Older/compact saved registries may omit derived indexes.  Let the
    -- production normalizer repair that persisted shape after the real Load
    -- owner has inspected the raw ModData; Python never builds these indexes.
    local registry = PNC.PlayerCharacters.Registry
    local needsProductionNormalization = type(raw) == "table"
        and type(raw.byUUID) == "table"
        and (type(registry) ~= "table"
            or type(registry.byUUID) ~= "table"
            or not Internal.HasEntries(registry.byUUID))
    if needsProductionNormalization
        and type(PNC.PlayerCharacters.NormalizeRegistry) == "function"
    then
        local normalized = PNC.PlayerCharacters.NormalizeRegistry(
            Values.productionCopy(raw)
        )
        if type(normalized) ~= "table"
            or type(normalized.byUUID) ~= "table"
        then
            return nil, "production_player_normalization_failed"
        end
        PNC.PlayerCharacters.Registry = normalized
        PNC.PlayerCharacters.Loaded = true
        PNC.PlayerCharacters.Dirty = false
        if type(PNC.PlayerCharacters.ResetRuntimeBindings) == "function" then
            PNC.PlayerCharacters.ResetRuntimeBindings(
                "harness_rehydration_normalized"
            )
        end
        status.normalizer = "PNC.PlayerCharacters.NormalizeRegistry"
    end
    if type(raw) == "table" and type(raw.byUUID) == "table"
        and type(PNC.PlayerCharacters.Registry) == "table"
        and type(PNC.PlayerCharacters.Registry.byUUID) == "table"
        and Internal.HasEntries(PNC.PlayerCharacters.Registry.byUUID)
    then
        status.status = "HYDRATED"
        status.recordCount = Internal.CountKeys(PNC.PlayerCharacters.Registry.byUUID)
    elseif type(raw) ~= "table" then
        status.status = "MISSING"
        status.missingClass = "LEGITIMATE_ABSENCE"
    else
        return nil, "production_player_registry_empty"
    end
    local productionPlayers = Runtime.productionPlayerCharactersService
    if context.player and productionPlayers
        and type(productionPlayers.GetEntityKey) == "function"
    then
        local entityKey, identityReason = productionPlayers.GetEntityKey(
            context.player,
            { callback = "semantic_lab_rehydration", worldAgeHours = Runtime.now }
        )
        status.entityKey = entityKey
        status.identityReason = identityReason
    end
    return status
end

local function loadProductionKnowledge(context)
    local Runtime = context.Runtime
    local Values = context.Values
    local raw = Internal.RawKnowledgeRegistryFor(context)
    local status = {
        schema = "semantic.production_knowledge_rehydration.v1",
        source = "ProjectHoomans.rawRegistries.npcKnowledge",
        status = "MISSING",
        loadOwner = "PNC.NPCKnowledge.Load",
        table = "PNC_NPCKnowledge",
    }
    if not PNC or not PNC.NPCKnowledge
        or type(PNC.NPCKnowledge.Load) ~= "function"
    then
        if type(raw) ~= "table" then
            status.missingClass = "LEGITIMATE_ABSENCE"
            return status
        end
        return nil, "production_knowledge_loader_unavailable"
    end

    -- Knowledge persistence uses the canonical ModData reset/load owner. The
    -- ModData table belongs to this worker and is replaced on every import;
    -- it is never backed by the source save after transport.
    Runtime.modData = Runtime.modData or {}
    Runtime.modData.PNC_NPCKnowledge = type(raw) == "table"
        and Values.productionCopy(raw) or nil
    PNC.NPCKnowledge.Loaded = false
    PNC.NPCKnowledge.Dirty = false
    local ok, loaded = pcall(PNC.NPCKnowledge.Load)
    if not ok or loaded ~= true then
        return nil, "production_knowledge_load_failed"
    end

    if type(raw) == "table" then
        status.status = "HYDRATED"
        status.characterCount = Internal.CountKeys(
            PNC.NPCKnowledge.Registry
                and PNC.NPCKnowledge.Registry.byCharacter
        )
    else
        status.status = "MISSING"
        status.missingClass = "LEGITIMATE_ABSENCE"
    end
    return status
end

    Internal.LoadProductionOrganizations = loadProductionOrganizations
    Internal.LoadProductionPlayerCharacters = loadProductionPlayerCharacters
    Internal.LoadProductionKnowledge = loadProductionKnowledge
end

return install
