-- JSON-lines command routing for one semantic worker session.

local CommandRouter = {}
local TalkParity = PNC.Conversation
    and PNC.Conversation.TalkParity
    or require "PNC/Conversation/PNC_ConversationTalkParity"

local function talkCatalog()
    return {
        schema = "semantic.talk.catalog.v1",
        targets = TalkParity.GetCatalog(),
    }
end

local function hasEntries(value)
    if type(value) ~= "table" then return false end
    for _ in pairs(value) do return true end
    return false
end

local capabilities = {
    "CONFIG", "IMPORT_SOURCE", "RESET", "RESET_TURN", "RESET_CONVERSATION",
    "RESET_ACTOR_MUTATIONS", "RESET_WORLD", "INPUT", "LANGUAGE", "TOOL_REPLY",
    "PREVIEW", "SNAPSHOT", "CONVERSATION_GRAPH", "FLOW_CATALOG", "FLOW_VALIDATE",
    "INSPECT_ACTOR_STATE",
    "RELATIONSHIP_PROPOSAL", "RELATIONSHIP_PREVIEW",
    "SUGGESTION_PREDICATE", "SUGGESTION_CLICK",
    "FLOW_REGISTER", "PING", "CAPABILITIES", "QUIT",
    "FACT_CATALOG", "EVENT_CATALOG", "FLOW_GENERATE", "FLOW_COVERAGE",
    "REPLAY_SEMANTIC_QUEST",
    "COMMITMENT", "BACKSTORY", "BACKSTORY_FACT",
    "KNOWLEDGE_BOOTSTRAP", "KNOWLEDGE_DISCOVER", "KNOWLEDGE_METRICS",
    "WORLD_KNOWLEDGE_INSPECT", "WORLD_KNOWLEDGE_PROPAGATE",
    "PERSONA_CATALOG", "PERSONA_PREVIEW",
    "SIMULATION_CONTROL_CATALOG",
    "TALK_CATALOG", "TALK_START", "TALK_MATRIX",
}

-- Test-only production fixture generation.  This deliberately calls the
-- Project Hoomans persistence owners to produce raw saved records; it does
-- not encode an inventory payload in the harness.
local function productionInventoryFixture(context, payload)
    local Runtime = context.Runtime
    local Values = context.Values
    local sourceKind = tostring(
        Runtime.sourceMetadata and Runtime.sourceMetadata.sourceKind or "FIXTURE"
    )
    if sourceKind ~= "FIXTURE" then
        return nil, "production_inventory_fixture_requires_fixture_mode"
    end
    payload = type(payload) == "table" and payload or {}
    local mode = tostring(payload.mode or "")
    if mode ~= "SEED_ONLY"
        and mode ~= "BASELINE_DELTA"
        and mode ~= "FULL"
    then
        return nil, "production_inventory_fixture_mode_invalid"
    end
    if not PNC.Persistence
        or type(PNC.Persistence.DeserializeRecord) ~= "function"
        or not PNC.Inventory
        or type(PNC.Inventory.EnsureRecordInventory) ~= "function"
        or type(PNC.Persistence.SerializeRecord) ~= "function"
    then
        return nil, "production_inventory_fixture_owner_unavailable"
    end
    -- The normal developer fixture path intentionally installs its explicit
    -- fixture inventory owner.  This test command switches back to the
    -- captured production owner before generating a persisted record.
    if context.InventoryFixtures
        and type(context.InventoryFixtures.restoreProduction) == "function"
    then
        local metadata = Runtime.sourceMetadata or {}
        local previousSourceKind = metadata.sourceKind
        metadata.sourceKind = "SAVE"
        Runtime.sourceMetadata = metadata
        context.InventoryFixtures.restoreProduction(context)
        metadata.sourceKind = previousSourceKind
    end

    local ok, result = pcall(function()
        local npcID = "npcP14B_" .. string.lower(mode)
        local raw = {
            schemaVersion = PNC.Const and PNC.Const.PERSISTENCE_VERSION or 16,
            recordRevision = 1,
            id = npcID,
            tacticalClass = "neutral",
            persist = true,
            identity = {
                displayName = "P14B " .. mode,
                isFemale = false,
                archetypeID = "General",
                seed = 1402,
                survivor = {
                    forename = "P14B",
                    surname = mode,
                },
            },
            hostility = { mode = "neutral", attackPlayers = false },
        }
        local record = PNC.Persistence.DeserializeRecord(raw, npcID)
        if type(record) ~= "table" then
            error("production_deserializer_rejected_fixture")
        end
        local inventory = PNC.Inventory.EnsureRecordInventory(record)
        if type(inventory) ~= "table" then
            error("production_inventory_hydrator_rejected_fixture")
        end
        local markerType
        local markerID
        if mode == "BASELINE_DELTA" then
            markerType = "Base.Bandage"
            markerID = "p14b_baseline_delta_item"
        elseif mode == "FULL" then
            markerType = "Base.HuntingKnife"
            markerID = "p14b_full_item"
        end
        if markerType then
            local added = PNC.Inventory.AddItems(
                record,
                {{
                    id = markerID,
                    type = markerType,
                    stack = mode == "BASELINE_DELTA" and 3 or 1,
                }},
                "root",
                "p14b_production_fixture"
            )
            if added ~= true then error("production_inventory_fixture_add_failed") end
        end
        if mode == "FULL" then
            record.inventoryPersistenceMode = "FULL"
        end
        local serialized = PNC.Persistence.SerializeRecord(record)
        if type(serialized) ~= "table"
            or type(serialized.inventory) ~= "table"
        then
            error("production_inventory_fixture_not_serialized:" .. tostring(
                type(serialized)
            ) .. ":" .. tostring(serialized and serialized.id))
        end
        local roundTrip = PNC.Persistence.DeserializeRecord(serialized, npcID)
        local roundTripInventory = roundTrip
            and PNC.Inventory.EnsureRecordInventory(roundTrip) or nil
        return {
            ok = true,
            type = "production_inventory_fixture",
            mode = serialized.inventory[2],
            record = Values.productionCopy(serialized),
            runtimeItemCount = (function()
                local count = 0
                for _ in pairs(record.inventory and record.inventory.items or {}) do
                    count = count + 1
                end
                return count
            end)(),
            markerID = markerID,
            markerType = markerType,
            roundTripMode = roundTrip
                and (roundTrip.inventoryPersistenceMode
                    or roundTripInventory and roundTripInventory.persistenceMode)
                or nil,
            roundTripItemCount = roundTripInventory
                and (function()
                    local count = 0
                    for _ in pairs(roundTripInventory.items or {}) do
                        count = count + 1
                    end
                    return count
                end)()
                or 0,
        }
    end)
    if not ok then
        return nil, "production_inventory_fixture_error:" .. tostring(result)
    end
    return result
end

local function boundedInventory(context, inventory)
    local source = type(inventory) == "table" and inventory or {}
    local output = {
        revision = source.revision,
        items = {},
    }
    local itemIDs = {}
    for itemID in pairs(type(source.items) == "table" and source.items or {}) do
        itemIDs[#itemIDs + 1] = tostring(itemID)
    end
    table.sort(itemIDs)
    for index = 1, math.min(#itemIDs, 512) do
        local itemID = itemIDs[index]
        local item = source.items[itemID]
        if type(item) == "table" then
            output.items[itemID] = {
                id = item.id or itemID,
                itemID = item.itemID or itemID,
                type = item.type,
                fullType = item.fullType,
                displayName = item.displayName or item.customName,
                stack = item.stack or item.quantity or item.count,
                container = item.container,
                equipped = item.equipped,
                equipSlot = item.equipSlot,
                condition = item.condition or item.cond,
                uses = item.uses,
            }
        end
    end
    return output
end

local function boundedRelationship(context)
    local scenario = context.Runtime.scenario or {}
    local npc = scenario.npc or {}
    local snapshot = context.SemanticAdapters
        and type(context.SemanticAdapters.relationshipSnapshotFor) == "function"
        and context.SemanticAdapters.relationshipSnapshotFor(
            context, npc.npcID or npc.id
        ) or npc.relationship
    local relationship = type(snapshot) == "table" and snapshot or {}
    local output = {}
    for _, key in ipairs({
        "baselineApproval", "baselineRespect", "approval", "respect",
        "familiarity", "state", "previousState", "revision",
        "interactionRevision", "saturation", "cooldownUntil",
    }) do
        output[key] = relationship[key]
    end
    output.bond = context.Values.copy(relationship.bond)
    return output
end

local function actorStateProjection(context)
    local scenario = context.Runtime.scenario or {}
    local player = scenario.player or {}
    local npc = scenario.npc or {}
    local function traits(value)
        local output = {}
        if type(value) ~= "table" then return output end
        for index = 1, math.min(#value, 64) do
            output[#output + 1] = value[index]
        end
        return output
    end
    return {
        ok = true,
        type = "actor_state",
        scenario = {
            player = {
                characterUUID = player.characterUUID,
                displayName = player.displayName,
                accountKey = player.accountKey,
                entityKey = player.entityKey,
                gender = player.gender,
                traits = traits(player.traits),
                inventory = boundedInventory(context, context.playerInventory
                    or player.inventory),
            },
            npc = {
                npcID = npc.npcID or npc.id,
                displayName = npc.displayName,
                gender = npc.gender,
                identityState = npc.identityState,
                recruited = npc.recruited,
                companion = npc.companion,
                ownedByPlayer = npc.ownedByPlayer,
                factionID = npc.factionID,
                communityID = npc.communityID,
                role = npc.role,
                isTrader = npc.isTrader,
                isHostile = npc.isHostile,
                activeBehavior = npc.activeBehavior,
                traits = traits(npc.traits),
                inventory = boundedInventory(context, context.npcInventory
                    or npc.inventory),
                relationship = boundedRelationship(context),
            },
        },
    }
end

local function catalogValues(source, fallback)
    local values = {}
    if type(source) == "table" then
        if #source > 0 then
            for index = 1, #source do
                values[#values + 1] = source[index]
            end
        else
            for key, enabled in pairs(source) do
                if enabled == true then
                    values[#values + 1] = key
                end
            end
        end
    end
    if #values == 0 then
        for index = 1, #fallback do
            values[#values + 1] = fallback[index]
        end
    end
    table.sort(values, function(left, right)
        return tostring(left) < tostring(right)
    end)
    return values
end

local function relationshipKindCatalog(context, payload)
    local registry = PNC.RelationshipKinds
    if not registry or type(registry.GetDefinitions) ~= "function" then
        return { schema = "pnc.relationship.kind.catalog.v1", kinds = {} }
    end
    local registration
    if type(payload) == "table"
        and type(payload.registerRelationshipKind) == "table"
        and type(registry.Register) == "function"
    then
        local registered, reason = registry.Register(
            payload.registerRelationshipKind
        )
        registration = { registered = registered == true, reason = reason }
    end
    local translation = PNC.Translation
    local kinds = {}
    local definitions
    if registration and registration.registered == true then
        -- Explicit registration is the diagnostic fixture path. It may
        -- inspect an extensible/future kind without making that kind part of
        -- the normal production catalog.
        definitions = registry.GetDefinitions()
    elseif type(registry.GetProductionDefinitions) == "function" then
        definitions = registry.GetProductionDefinitions()
    else
        definitions = registry.GetDefinitions()
    end
    for index = 1, math.min(#definitions, 64) do
        local definition = definitions[index]
        local terms = definition.termKeys or {}
        local reference = terms.reference or definition.kind
        local address = terms.address or definition.kind
        if translation and type(translation.GetKey) == "function" then
            reference = translation.GetKey(terms.reference, definition.kind)
            address = translation.GetKey(terms.address, definition.kind)
        end
        kinds[#kinds + 1] = {
            kind = definition.kind,
            class = definition.class,
            termKeys = context.Values.copy(terms),
            terms = {
                reference = reference,
                address = address,
            },
        }
    end
    return {
        schema = "pnc.relationship.kind.catalog.v1",
        schemaVersion = 1,
        kinds = kinds,
        registration = registration,
    }
end

local function speechRealizationCatalog(context)
    local realization = PNC.Semantics
        and PNC.Semantics.SpeechRealization or nil
    if not realization then
        local ok, value = pcall(require, "PNC/Semantics/PNC_SpeechRealization")
        if ok then realization = value end
    end
    if type(realization) ~= "table" then
        return { schema = "pnc.speech.realization.catalog.v1", coverage = {}, families = {} }
    end
    local families = {}
    if type(realization.Families) == "function" then
        for templateID in pairs(realization.Families() or {}) do
            families[#families + 1] = tostring(templateID)
            if #families >= 64 then break end
        end
        table.sort(families)
    end
    return {
        schema = "pnc.speech.realization.catalog.v1",
        coverage = type(realization.Coverage) == "function"
            and realization.Coverage() or {},
        families = families,
    }
end

local function personaCatalog(context, payload)
    local definitions = PNC.NPCTraits
        and type(PNC.NPCTraits.GetDefinitions) == "function"
        and PNC.NPCTraits.GetDefinitions() or {}
    local playerDefinitions = PNC.SocialTraits
        and type(PNC.SocialTraits.GetDefinitions) == "function"
        and PNC.SocialTraits.GetDefinitions() or {}
    local constants = PNC.SocialProfileConstants or {}
    local traits = {}
    local playerTraits = {}
    local maximum = math.min(#definitions, 64)
    for index = 1, maximum do
        local definition = definitions[index]
        if type(definition) == "table" then
            local translation = PNC.Translation
            traits[#traits + 1] = {
                id = definition.id,
                labelKey = definition.labelKey or definition.uiName,
                label = translation and type(translation.GetKey) == "function"
                    and translation.GetKey(
                        definition.labelKey or definition.uiName,
                        definition.id
                    ) or definition.id,
                descriptionKey = definition.descriptionKey
                    or definition.uiDescription,
                excludes = context.Values.copy(definition.excludes),
                source = definition.source,
                aliases = context.Values.copy(definition.aliases),
                generation = context.Values.copy(definition.generation),
                speechStyle = context.Values.copy(definition.speechStyle),
                effects = context.Values.copy(definition.effects),
            }
        end
    end
    table.sort(traits, function(left, right)
        return tostring(left.id or "") < tostring(right.id or "")
    end)
    for index = 1, math.min(#playerDefinitions, 64) do
        local definition = playerDefinitions[index]
        if type(definition) == "table" then
            local translation = PNC.Translation
            playerTraits[#playerTraits + 1] = {
                id = definition.id,
                labelKey = definition.labelKey or definition.uiName,
                label = translation and type(translation.GetKey) == "function"
                    and translation.GetKey(
                        definition.labelKey or definition.uiName,
                        definition.id
                    ) or definition.id,
                descriptionKey = definition.descriptionKey
                    or definition.uiDescription,
                excludes = context.Values.copy(definition.excludes),
                source = definition.source,
                aliases = context.Values.copy(definition.aliases),
                effects = context.Values.copy(definition.effects),
            }
        end
    end
    table.sort(playerTraits, function(left, right)
        return tostring(left.id or "") < tostring(right.id or "")
    end)
    local archetypes = {}
    for archetypeID in pairs(constants.ARCHETYPE_MODIFIERS or {}) do
        archetypes[#archetypes + 1] = archetypeID
    end
    table.sort(archetypes)
    local relationshipKinds = relationshipKindCatalog(context, payload)
    local speechRealization = speechRealizationCatalog(context)
    local factionConstants = PNC.FactionConstants or {}
    if type(factionConstants.ROLES) ~= "table" then
        pcall(require, "PNC/Core/Factions/PNC_FactionConstants")
        factionConstants = PNC.FactionConstants or {}
    end
    return {
        schema = "semantic.persona.catalog.v1",
        schemaVersion = 1,
        identity = { genders = { "unknown", "female", "male" } },
        traits = traits,
        playerTraits = playerTraits,
        archetypes = archetypes,
        playerSocialProfile = context.Values.copy(context.playerSocialProfile),
        npcPersonality = context.Values.copy(context.npcPersonality),
        npcPersonalityMode = context.npcPersonalityMode or "generated",
        personality = {
            enums = {
                socialStyle = catalogValues(
                    constants.VALID_SOCIAL_STYLES,
                    { "neutral", "friendly", "withdrawn" }
                ),
            },
            dimensions = catalogValues(constants.NUMERIC_DIMENSIONS, {
                "compassion", "sociability", "forgiveness", "bravery",
                "materialism", "aggression", "loyalty",
            }),
        },
        roles = catalogValues(factionConstants.ROLES, {}),
        integrations = { "DTHoomans" },
        relationshipKinds = relationshipKinds.kinds,
        relationshipKindRegistration = relationshipKinds.registration,
        speechRealization = speechRealization,
    }
end

local function personaPreview(context, payload)
    local Values = context.Values
    local scenario = type(payload) == "table" and payload.scenario or nil
    local player = type(scenario) == "table" and scenario.player
        or context.Runtime.scenario and context.Runtime.scenario.player or {}
    local npc = type(scenario) == "table" and scenario.npc
        or context.Runtime.scenario and context.Runtime.scenario.npc or {}
    local identitySeed = npc.identitySeed
        or npc.identity and npc.identity.seed
        or npc.npcID
    local archetype = npc.archetype or npc.archetypeID or "General"
    local generator = PNC.SocialProfileGenerator
    if not generator or type(generator.Generate) ~= "function" then
        return nil, "npc_personality_generator_unavailable"
    end
    local personality = generator.Generate(
        identitySeed,
        archetype,
        nil,
        { npcTraits = npc.traits or {} }
    )
    local playerProfile = {}
    local playerConflicts = {}
    local playerFingerprint = ""
    local socialTraits = PNC.SocialTraits
    if socialTraits and type(socialTraits.ResolveTraits) == "function" then
        playerProfile, playerConflicts, playerFingerprint = socialTraits.ResolveTraits(
            player.traits or player.socialTraits or {}
        )
    end
    return {
        ok = true,
        type = "persona_preview",
        schema = "semantic.persona.preview.v1",
        mode = "generated",
        personality = Values.copy(personality),
        traits = Values.copy(npc.traits or {}),
        playerSocialProfile = Values.copy(playerProfile),
        playerTraitConflicts = Values.copy(playerConflicts),
        playerTraitFingerprint = playerFingerprint or "",
        persisted = false,
    }
end

local function simulationControlCatalog(context, payload)
    local persona = personaCatalog(context, payload)
    local controls = {}

    local function add(id, path, page, section, label, control, valueType, details)
        local row = {
            id = id,
            path = path,
            page = page,
            section = section,
            label = label,
            control = control,
            valueType = valueType,
        }
        for key, value in pairs(details or {}) do
            row[key] = value
        end
        controls[#controls + 1] = row
    end

    local function withNone(values)
        local result = { "none" }
        for index = 1, math.min(#(values or {}), 64) do
            if values[index] ~= "none" then
                result[#result + 1] = values[index]
            end
        end
        return result
    end

    local roles = withNone(persona.roles)
    local bondKinds = {}
    local traits = {}
    local playerTraitOptions = {}
    for index = 1, math.min(#(persona.relationshipKinds or {}), 64) do
        bondKinds[#bondKinds + 1] = persona.relationshipKinds[index].kind
    end
    for index = 1, math.min(#(persona.traits or {}), 64) do
        traits[#traits + 1] = {
            value = persona.traits[index].id,
            label = persona.traits[index].label or persona.traits[index].id,
        }
    end
    for index = 1, math.min(#(persona.playerTraits or {}), 64) do
        playerTraitOptions[#playerTraitOptions + 1] = {
            value = persona.playerTraits[index].id,
            label = persona.playerTraits[index].label
                or persona.playerTraits[index].id,
        }
    end

    -- UI metadata for the harness. ScenarioSession.configure remains the
    -- authority for accepted scenario state; catalogs below only describe
    -- how Semantic Lab edits that state.
    add("runtime.mode", "runtime.mode", "Runtime", "Worker", "Network mode", "combobox", "enum", {
        options = { "singleplayer", "multiplayer" },
        optionsSource = "semantic_lab.harness",
    })
    add("runtime.language", "runtime.language", "Runtime", "Worker", "Language", "combobox", "enum", {
        options = { "EN", "TL" },
        optionsSource = "semantic_lab.harness",
        workbench = true, workbenchPanel = "World", workbenchTab = "Overview",
        workbenchSection = "Context",
    })
    add("runtime.llmEnabled", "runtime.llmEnabled", "Runtime", "Integrations", "LLM bridge enabled", "boolean", "boolean")
    add("runtime.providerAvailable", "runtime.providerAvailable", "Runtime", "Integrations", "LLM provider available", "boolean", "boolean")
    add("runtime.semanticDialogueEnabled", "runtime.semanticDialogueEnabled", "Runtime", "Worker", "Semantic dialogue enabled", "boolean", "boolean", {
        workbench = true, workbenchPanel = "World", workbenchTab = "Overview",
        workbenchSection = "Context",
    })
    add("runtime.DTHoomans", "runtime.availableMods.DTHoomans", "Runtime", "Integrations", "Dynamic Trading adapter enabled", "boolean", "boolean", {
        workbench = true, workbenchPanel = "World", workbenchTab = "Overview",
        workbenchSection = "Context",
    })

    local needKeys = { "hunger", "thirst", "fatigue", "stress", "boredom", "panic" }
    for _, key in ipairs(needKeys) do
        local title = string.upper(string.sub(key, 1, 1)) .. string.sub(key, 2)
        add("world." .. key, "world." .. key, "World", "Needs", title, "slider", "number", {
            min = 0, max = 1, step = 0.05, format = "%.2f",
            legacy = true,
            settingsVisible = false,
            description = "Legacy world fallback for older scenarios; edit the owning actor field instead.",
        })
    end
    local function addActorNeeds(prefix, label, panel)
        local actor = context[prefix .. "Data"] or {}
        local source = type(actor.needs) == "table"
            and actor.needs or context.world or {}
        for _, key in ipairs(needKeys) do
            local title = string.upper(string.sub(key, 1, 1)) .. string.sub(key, 2)
            add(prefix .. ".needs." .. key, prefix .. ".needs." .. key,
                "Actors", label .. " Needs", title, "slider", "number", {
                    min = 0, max = 1, step = 0.05, format = "%.2f",
                    currentValue = source[key],
                    workbench = true, workbenchPanel = panel,
                    workbenchTab = "Needs", workbenchSection = "Needs",
                })
        end
    end
    addActorNeeds("player", "Player", "Player")
    addActorNeeds("npc", "NPC", "NPC Target")
    add("world.timeOfDay", "world.timeOfDay", "World", "Time", "Time of day", "slider", "number", {
        min = 0, max = 24, step = 0.25, format = "%.2f",
        workbench = true, workbenchPanel = "World", workbenchTab = "Overview",
        workbenchSection = "Time",
    })
    add("world.worldAgeHours", "world.worldAgeHours", "World", "Time", "World age (hours)", "spinbox", "number", {
        min = 0, max = 1000000, step = 0.5, format = "%.1f",
        workbench = true, workbenchPanel = "World", workbenchTab = "Overview",
        workbenchSection = "Time",
    })
    add("world.zombieKills", "world.zombieKills", "World", "World facts", "Zombie kills", "integer", "integer", {
        min = 0, max = 1000000, step = 1,
        workbench = true, workbenchPanel = "World", workbenchTab = "Overview",
        workbenchSection = "World facts",
    })
    add("world.weather", "world.weather", "World", "World facts", "Weather", "combobox", "enum", {
        options = { "clear", "rain", "fog", "snow" },
        optionsSource = "semantic_lab.harness",
        workbench = true, workbenchPanel = "World", workbenchTab = "Overview",
        workbenchSection = "World facts",
    })
    add("world.weatherTransition", "world.weatherTransition", "World", "World facts", "Weather transition", "text", "text", {
        emptyToNull = true,
        workbench = true, workbenchPanel = "World", workbenchTab = "Overview",
        workbenchSection = "World facts",
    })

    add("player.characterUUID", "player.characterUUID", "Actors", "Player", "Player ID", "text", "text", {
        derivedFrom = { "player.forename", "player.surname" },
        workbench = true, workbenchPanel = "Player", workbenchTab = "Overview",
        workbenchSection = "Overview", workbenchVisible = false, settingsVisible = false,
    })
    add("player.forename", "player.forename", "Actors", "Player", "Player first name", "text", "text", {
        workbench = true, workbenchPanel = "Player", workbenchTab = "Overview",
        workbenchSection = "Overview",
    })
    add("player.surname", "player.surname", "Actors", "Player", "Player surname", "text", "text", {
        workbench = true, workbenchPanel = "Player", workbenchTab = "Overview",
        workbenchSection = "Overview",
    })
    add("player.displayName", "player.displayName", "Actors", "Player", "Player display name", "text", "text", {
        derivedFrom = { "player.forename", "player.surname" },
        workbench = true, workbenchPanel = "Player", workbenchTab = "Overview",
        workbenchSection = "Overview", workbenchVisible = false, settingsVisible = false,
    })
    add("player.gender", "player.gender", "Actors", "Player", "Gender", "combobox", "enum", {
        options = persona.identity.genders,
        optionsSource = "semantic_lab.harness",
        workbench = true, workbenchPanel = "Player", workbenchTab = "Overview",
        workbenchSection = "Overview",
    })
    add("player.traits", "player.traits", "Actors", "Player", "Registered player traits", "multi_select", "array", {
        options = playerTraitOptions,
        optionsSource = "PsychopatzCore.Traits / PNC.SocialTraits",
        workbench = true, workbenchPanel = "Player", workbenchTab = "Personality & Traits",
        workbenchSection = "Traits",
    })
    for _, key in ipairs({ "orientation", "romanceStyle", "jealousyStyle", "socialStyle", "foodPreference" }) do
        add("player.socialProfile." .. key, nil, "Actors", "Player", key, "read_only", "text", {
            currentValue = context.playerSocialProfile
                and context.playerSocialProfile[key] or "unknown",
            source = "production.player_social_profile",
            workbench = true, workbenchPanel = "Player",
            workbenchTab = "Personality & Traits", workbenchSection = "Derived social profile",
        })
    end
    add("npc.identitySeed", "npc.identitySeed", "Actors", "NPC", "Identity seed", "text", "text", {
        workbench = true, workbenchPanel = "NPC Target", workbenchTab = "Overview",
        workbenchSection = "Overview",
    })
    add("npc.archetype", "npc.archetype", "Actors", "NPC", "Archetype", "combobox", "enum", {
        options = persona.archetypes,
        optionsSource = "PNC.SocialProfileConstants.ARCHETYPE_MODIFIERS",
        workbench = true, workbenchPanel = "NPC Target", workbenchTab = "Overview",
        workbenchSection = "Overview",
    })
    add("npc.npcID", "npc.npcID", "Actors", "NPC", "NPC ID", "text", "text", {
        derivedFrom = { "npc.forename", "npc.surname" },
        workbench = true, workbenchPanel = "NPC Target", workbenchTab = "Overview",
        workbenchSection = "Overview", workbenchVisible = false, settingsVisible = false,
    })
    add("npc.forename", "npc.forename", "Actors", "NPC", "First name", "text", "text", {
        workbench = true, workbenchPanel = "NPC Target", workbenchTab = "Overview",
        workbenchSection = "Overview",
    })
    add("npc.surname", "npc.surname", "Actors", "NPC", "Surname", "text", "text", {
        workbench = true, workbenchPanel = "NPC Target", workbenchTab = "Overview",
        workbenchSection = "Overview",
    })
    add("npc.identityState", "npc.identityState", "Actors", "NPC", "Identity state", "text", "text", {
        workbench = true, workbenchPanel = "NPC Target", workbenchTab = "Overview",
        workbenchSection = "Overview",
    })
    add("npc.gender", "npc.gender", "Actors", "NPC", "Gender", "combobox", "enum", {
        options = persona.identity.genders,
        optionsSource = "semantic_lab.harness",
        workbench = true, workbenchPanel = "NPC Target", workbenchTab = "Overview",
        workbenchSection = "Overview",
    })
    add("npc.role", "npc.role", "Actors", "NPC", "Role / capability", "combobox", "enum", {
        options = roles,
        optionsSource = "PNC.FactionConstants.ROLES",
        noneValue = "none",
        workbench = true, workbenchPanel = "NPC Target", workbenchTab = "Overview",
        workbenchSection = "Context",
    })
    add("npc.healthState", "npc.healthState", "Actors", "NPC", "Health", "combobox", "enum", {
        options = { "unknown", "healthy", "injured", "wounded", "critical", "dead" },
        optionsSource = "semantic_lab.harness",
        workbench = true, workbenchPanel = "NPC Target", workbenchTab = "Overview",
        workbenchSection = "Context",
    })
    add("npc.activeBehavior", "npc.activeBehavior", "Actors", "NPC", "Activity", "combobox", "enum", {
        options = { "idle", "following", "staying", "busy", "searching", "fleeing", "hostile", "combat" },
        optionsSource = "semantic_lab.harness",
        workbench = true, workbenchPanel = "NPC Target", workbenchTab = "Overview",
        workbenchSection = "Context",
    })
    add("relationship.identityTrust", "npc.relationship.identityTrust", "Persona", "Relationship", "Identity trust", "combobox", "enum", {
        options = { "unknown", "trusted", "untrustworthy" },
        optionsSource = "semantic_lab.harness",
    })
    add("persona.bondKind", "npc.startingRelationship.kind", "Persona", "Relationship", "Bond kind", "combobox", "enum", {
        options = withNone(bondKinds),
        optionsSource = "PNC.RelationshipKinds",
        noneValue = "none",
        clearPath = "npc.startingRelationship",
        advanced = true,
    })
    add("persona.traits", "npc.traits", "Persona", "Traits", "Registered traits", "multi_select", "array", {
        options = traits,
        optionsSource = "PNC.NPCTraits",
        workbench = true, workbenchPanel = "NPC Target", workbenchTab = "Personality & Traits",
        workbenchSection = "Registered traits",
    })
    add("npc.personalityOverride", "npc.personalityOverride", "Persona", "Personality", "Override generated personality", "boolean", "boolean", {
        workbench = true, workbenchPanel = "NPC Target", workbenchTab = "Personality & Traits",
        workbenchSection = "Personality source",
    })
    add("npc.personalityMode", nil, "Persona", "Personality", "Personality mode", "read_only", "text", {
        currentValue = context.npcPersonalityMode or "generated",
        source = "production.social_profile_generator",
        workbench = true, workbenchPanel = "NPC Target", workbenchTab = "Personality & Traits",
        workbenchSection = "Personality source",
    })
    add("persona.socialStyle", "npc.personality.socialStyle", "Persona", "Personality", "Social style", "combobox", "enum", {
        options = persona.personality.enums.socialStyle,
        optionsSource = "PNC.SocialProfileConstants.VALID_SOCIAL_STYLES",
        currentValue = context.npcPersonality and context.npcPersonality.socialStyle,
        requiresOverride = "npc.personalityOverride",
        workbench = true, workbenchPanel = "NPC Target", workbenchTab = "Personality & Traits",
        workbenchSection = "Generated personality",
    })
    add("relationship.approval", "npc.relationship.approval", "Persona", "Relationship", "Approval", "slider", "number", {
        min = -100, max = 100, step = 1, format = "%.0f",
        workbench = true, workbenchPanel = "Relationship", workbenchTab = "Overview",
        workbenchSection = "Context",
    })
    add("relationship.respect", "npc.relationship.respect", "Persona", "Relationship", "Respect", "slider", "number", {
        min = -100, max = 100, step = 1, format = "%.0f",
        workbench = true, workbenchPanel = "Relationship", workbenchTab = "Overview",
        workbenchSection = "Context",
    })
    add("relationship.familiarity", "npc.relationship.familiarity", "Persona", "Relationship", "Familiarity", "slider", "number", {
        min = 0, max = 100, step = 1, format = "%.0f",
        workbench = true, workbenchPanel = "Relationship", workbenchTab = "Overview",
        workbenchSection = "Context",
    })
    for _, key in ipairs(persona.personality.dimensions or {}) do
        add("persona.personality." .. key, "npc.personality." .. key, "Persona", "Personality", key, "slider", "number", {
            min = 0, max = 1, step = 0.05, format = "%.2f",
            optionsSource = "PNC.SocialProfileConstants.NUMERIC_DIMENSIONS",
            currentValue = context.npcPersonality and context.npcPersonality[key],
            requiresOverride = "npc.personalityOverride",
            workbench = true, workbenchPanel = "NPC Target", workbenchTab = "Personality & Traits",
            workbenchSection = "Generated personality",
        })
    end
    for _, key in ipairs({ "companion", "owned", "eligible" }) do
        add("persona.authority." .. key, "npc.actorAuthority." .. key, "Persona", "Authority", key, "boolean", "boolean")
    end
    add("relationship.state", nil, "Persona", "Relationship", "Derived relationship state", "read_only", "text", {
        source = "production.relationship.state",
        workbench = true, workbenchPanel = "Relationship", workbenchTab = "Overview",
        workbenchSection = "Context",
    })
    local durableBond = context.npcData and context.npcData.relationship
        and context.npcData.relationship.bond or nil
    local durableBondLabel = durableBond
        and (durableBond.kind or durableBond.class) or "none"
    local proposal = context.ScenarioSession
        and context.ScenarioSession.relationshipProposalProjection
        and context.ScenarioSession.relationshipProposalProjection(context)
        or {}
    add("relationship.bond", nil, "Persona", "Relationship", "Durable bond", "read_only", "text", {
        currentValue = durableBondLabel,
        source = "production.relationship.bond",
        workbench = true, workbenchPanel = "Relationship", workbenchTab = "Overview",
        workbenchSection = "Context",
    })
    local approval = context.npcData and context.npcData.relationship
        and context.npcData.relationship.approval or 0
    local respect = context.npcData and context.npcData.relationship
        and context.npcData.relationship.respect or 0
    local familiarity = context.npcData and context.npcData.relationship
        and context.npcData.relationship.familiarity or 0
    add("relationship.friendBondProgress", nil, "Persona", "Relationship", "Friend bond progress", "read_only", "text", {
        currentValue = string.format(
            "Approval %s / 80 · Respect %s / 50 · Familiarity %s / 60",
            tostring(approval), tostring(respect), tostring(familiarity)
        ),
        source = "PNC.RelationshipConstants",
        workbench = true, workbenchPanel = "Relationship", workbenchTab = "Overview",
        workbenchSection = "Friend bond",
    })
    add("relationship.romanceCompatibility", nil, "Persona", "Relationship", "Romance compatibility", "read_only", "text", {
        currentValue = proposal.compatible == true and "compatible" or "incompatible",
        source = "production.social_profile_math",
        workbench = true, workbenchPanel = "Relationship", workbenchTab = "Overview",
        workbenchSection = "Romance proposal",
    })
    add("relationship.proposalThreshold", nil, "Persona", "Relationship", "Proposal threshold", "read_only", "text", {
        currentValue = "Approval 85 · Respect 60 · Familiarity 80",
        source = "PNC.RelationshipConstants",
        workbench = true, workbenchPanel = "Relationship", workbenchTab = "Overview",
        workbenchSection = "Romance proposal",
    })
    add("relationship.proposalCooldown", nil, "Persona", "Relationship", "Proposal cooldown", "read_only", "text", {
        currentValue = proposal.cooldownRemaining or 0,
        source = "production.relationship.bond",
        workbench = true, workbenchPanel = "Relationship", workbenchTab = "Overview",
        workbenchSection = "Romance proposal",
    })
    add("relationship.proposalAvailable", nil, "Persona", "Relationship", "Proposal available", "read_only", "text", {
        currentValue = proposal.eligible == true and "yes" or "no",
        source = "production.relationship.proposal_policy",
        workbench = true, workbenchPanel = "Relationship", workbenchTab = "Overview",
        workbenchSection = "Romance proposal",
    })

    add("player.inventory", "player.inventory", "Inventories", "Player", "Player inventory", "structured_collection", "object", {
        collectionType = "inventory",
        itemCatalogSource = "Project Zomboid media/scripts",
    })
    add("npc.inventory", "npc.inventory", "Inventories", "NPC", "NPC inventory", "structured_collection", "object", {
        collectionType = "inventory",
        itemCatalogSource = "Project Zomboid media/scripts",
    })
    add("conversation.topic", "conversation.topic", "Advanced", "Conversation", "Topic", "text", "text")
    add("conversation.token", "conversation.token", "Advanced", "Conversation", "Token", "text", "text")
    add("runtime.commandResponses", "runtime.commandResponses", "Advanced", "Worker seams", "Command responses · Advanced JSON", "advanced_json", "object")
    add("runtime.nativeTranslations", "runtime.nativeTranslations", "Advanced", "Worker seams", "Native translations · Advanced JSON", "advanced_json", "object")

    return {
        schema = "semantic.simulation.control.catalog.v1",
        schemaVersion = 1,
        maxControls = 96,
        controls = controls,
    }
end

local function backstorySnapshot(context, payload)
    local memory = PNC.Conversation and PNC.Conversation.Memory
    if not memory or type(memory.GetBackstoryProfile) ~= "function" then
        return nil, "backstory_memory_unavailable"
    end
    payload = type(payload) == "table" and payload or {}
    local world = context.Runtime and context.Runtime.scenario
        and context.Runtime.scenario.world or {}
    local record = {
        id = tostring(payload.npcID or "harness-backstory-npc"),
        tacticalClass = tostring(payload.tacticalClass or "colonist"),
        saveSeed = payload.saveSeed or world.seedString
            or world.worldSeedString or world.worldSeed,
        identity = {
            seed = payload.identitySeed,
        },
    }
    local profile = memory.GetBackstoryProfile(record)
    if type(profile) ~= "table" then
        return nil, "backstory_profile_unavailable"
    end
    local facts = {}
    for kind, fact in pairs(profile.facts or {}) do
        if type(fact) == "table" then
            facts[kind] = {
                id = fact.id,
                kind = fact.kind,
                class = fact.class,
                value = fact.value,
                textKey = fact.textKey,
            }
        end
    end
    return {
        ok = true,
        type = "backstory",
        profile = {
            identitySeed = profile.identitySeed,
            saveSeed = profile.saveSeed,
            tacticalClass = profile.tacticalClass,
            facts = facts,
        },
    }
end

local function backstoryFact(context, payload)
    local facts = PNC.Semantics and PNC.Semantics.DialogueFacts
    local result
    payload = type(payload) == "table" and payload or {}
    if not facts or type(facts.Resolve) ~= "function" then
        return nil, "dialogue_fact_registry_unavailable"
    end
    local world = context.Runtime and context.Runtime.scenario
        and context.Runtime.scenario.world or {}
    result = facts.Resolve({
        subject = "NPC_BACKSTORY",
        slots = { kind = payload.kind or payload.topic },
    }, nil, {
        npcRecord = {
            id = tostring(payload.npcID or "harness-backstory-npc"),
            tacticalClass = tostring(payload.tacticalClass or "colonist"),
            saveSeed = payload.saveSeed or world.seedString
                or world.worldSeedString or world.worldSeed,
            identitySeed = payload.identitySeed,
            identity = { seed = payload.identitySeed },
        },
        language = payload.language,
        authoritativeBackstoryAccess = true,
    })
    return {
        ok = true,
        type = "backstory_fact",
        fact = result,
    }
end

local function knowledgeMetrics(context, payload)
    local knowledge = PNC.NPCKnowledge
    local syntheticNPCs = math.min(
        1000,
        math.max(0, math.floor(tonumber(
            type(payload) == "table" and payload.syntheticNPCs or 0
        ) or 0))
    )
    local factsPerNPC = math.min(
        32,
        math.max(1, math.floor(tonumber(
            type(payload) == "table" and payload.factsPerNPC or 1
        ) or 1))
    )
    local descriptorIDs = {
        "personality.social_style",
        "personality.compassion",
        "personality.sociability",
        "personality.forgiveness",
        "personality.bravery",
        "personality.materialism",
        "personality.aggression",
        "personality.loyalty",
        "personality.compassion",
        "personality.sociability",
    }
    local recorded = 0
    local index
    local factIndex
    if not knowledge or type(knowledge.EnsureLoaded) ~= "function"
        or type(knowledge.RecordEvidence) ~= "function"
    then
        return nil, "knowledge_metrics_unavailable"
    end
    knowledge.EnsureLoaded()
    for index = 1, syntheticNPCs do
        for factIndex = 1, factsPerNPC do
            local descriptorID = descriptorIDs[
                ((factIndex - 1) % #descriptorIDs) + 1
            ]
            local result = knowledge.RecordEvidence({
                characterUUID = context.playerData.characterUUID,
                npcID = "harness-synthetic-npc-" .. tostring(index),
                descriptorID = descriptorID,
                sourceType = "observed_behavior",
                direction = 1,
                strength = 0.5,
                reliability = 0.75,
                sourceEventID = "harness-metrics-"
                    .. tostring(index) .. "-" .. tostring(factIndex),
                payload = { observedValue = "synthetic" },
            })
            if result then recorded = recorded + 1 end
        end
    end
    if recorded > 0 and type(knowledge.Save) == "function" then
        knowledge.Save(false)
    end

    local raw = ModData and type(ModData.get) == "function"
        and ModData.get("PNC_NPCKnowledge") or nil
    local canonicalKnowledge = type(knowledge.Registry) == "table"
        and knowledge.Registry or raw
    local hasKnowledge = canonicalKnowledge
        and type(canonicalKnowledge.byCharacter) == "table"
        and hasEntries(canonicalKnowledge.byCharacter)
    local knowledgeSerialized = hasKnowledge
        and context.Protocol.encode(canonicalKnowledge) or ""
    local modDataSerialized = raw and context.Protocol.encode(raw) or ""
    local registry = PNC.Registry
    local actor = registry and type(registry.Get) == "function"
        and registry.Get(context.npcData and context.npcData.npcID) or nil
    actor = type(actor) == "table" and actor or context.npcData or {}
    local backstoryMetadata = type(actor.identity) == "table"
        and actor.identity.backstory or nil
    local actorSerialized = context.Protocol.encode(actor)
    local backstorySerialized = backstoryMetadata
        and context.Protocol.encode(backstoryMetadata) or ""
    local combinedSerialized = context.Protocol.encode({
        npc = actor,
        playerKnowledge = hasKnowledge and canonicalKnowledge or nil,
    })
    local characterCount = 0
    local npcCount = 0
    local evidenceCount = 0
    local knowledgeRegistry = hasKnowledge
        and canonicalKnowledge.byCharacter or {}
    for _ in pairs(knowledgeRegistry) do characterCount = characterCount + 1 end
    for _, character in pairs(knowledgeRegistry) do
        for _, note in pairs(character.byNPC or {}) do
            npcCount = npcCount + 1
            evidenceCount = evidenceCount + #(note.evidence or {})
        end
    end
    return {
        ok = true,
        type = "knowledge_metrics",
        modDataKey = "PNC_NPCKnowledge",
        serializedBytes = #knowledgeSerialized,
        actorStorageBytes = #actorSerialized,
        backstoryMetadataBytes = #backstorySerialized,
        knowledgeStorageBytes = #knowledgeSerialized,
        combinedStorageBytes = #combinedSerialized,
        modDataSnapshotBytes = #modDataSerialized,
        actorRecordPresent = hasEntries(actor),
        backstoryMetadataPresent = backstoryMetadata ~= nil,
        persisted = raw ~= nil,
        characterCount = characterCount,
        npcCount = npcCount,
        evidenceCount = evidenceCount,
        syntheticNPCsRequested = syntheticNPCs,
        syntheticEvidenceRecorded = recorded,
        encoding = "worker_protocol_json_of_production_npc_and_moddata_tables",
        registryRevision = raw and raw.revision or 0,
    }
end

local function knowledgeDiscover(context, payload)
    local knowledge = PNC.NPCKnowledge
    payload = type(payload) == "table" and payload or {}
    if not knowledge or type(knowledge.DiscoverTopicForPlayer) ~= "function" then
        return nil, "knowledge_discovery_unavailable"
    end
    local topicID = tostring(payload.topicID or "")
    if topicID == "" then return nil, "knowledge_topic_required" end
    local result, reason = knowledge.DiscoverTopicForPlayer(
        context.player,
        tostring(payload.npcID or context.npcData.npcID),
        topicID,
        tonumber(payload.worldAgeHours or context.world.worldAgeHours) or 0,
        "direct_disclosure",
        false
    )
    if not result then return nil, reason end
    return {
        ok = true,
        type = "knowledge_discovery",
        topicID = topicID,
        result = result,
    }
end

local function worldKnowledgeInspect(context, payload)
    local Runtime = context.Runtime
    local Values = context.Values
    local adapter = PNC.WorldKnowledge
    local core = adapter and adapter.Core or nil
    local ledger
    local knowledge
    local facts
    local actors = {}
    local actorID
    local actorRecord
    local worldContext
    payload = type(payload) == "table" and payload or {}
    if not core or not core.LedgerState or not core.KnowledgeState then
        return nil, "world_knowledge_unavailable"
    end
    ledger = core.Ledger
    knowledge = core.ActorKnowledge
    facts = ledger.Query(core.LedgerState, {
        max = math.min(64, math.max(1, math.floor(
            tonumber(payload.maxFacts) or 32))),
    })
    for id, entry in pairs(core.KnowledgeState.byActor or {}) do
        local row = { actorID = id, references = {}, explanations = {} }
        for index = 1, math.min(#(entry.order or {}), 64) do
            local factID = entry.order[index]
            local reference = knowledge.Get(core.KnowledgeState,
                id, factID)
            if reference then
                row.references[#row.references + 1] = reference
                local explanation = core.Explain(id, factID, Runtime.now)
                if explanation then
                    row.explanations[#row.explanations + 1] = explanation
                end
            end
        end
        actors[#actors + 1] = row
        if tostring(payload.actorID or "") ~= ""
            and tostring(payload.actorID) == tostring(id)
        then
            actorID = id
        end
    end
    table.sort(actors, function(left, right)
        return tostring(left.actorID) < tostring(right.actorID)
    end)
    if actorID then
        actorRecord = PNC.Registry and PNC.Registry.Get
            and PNC.Registry.Get(actorID) or nil
        if actorRecord and type(adapter.BuildConversationContext) == "function" then
            worldContext = adapter.BuildConversationContext(actorRecord, {
                language = (Runtime.scenario and Runtime.scenario.runtime
                    and Runtime.scenario.runtime.language) or "EN",
                now = Runtime.now,
                max = 4,
            })
        end
    end
    local realization = worldContext and worldContext.npcGossip or {
        statements = {}, factRefs = {},
    }
    realization.source = "world_knowledge"
    realization.language = (Runtime.scenario and Runtime.scenario.runtime
        and Runtime.scenario.runtime.language) or "EN"
    return {
        ok = true,
        type = "world_knowledge_inspection",
        actorID = actorID,
        scenarioOwned = Runtime.worldKnowledgeScenario ~= nil,
        ledger = {
            facts = facts,
            metrics = Values.copy(core.LedgerState.metrics),
            maxFacts = core.LedgerState.maxFacts,
            revision = core.LedgerState.revision,
        },
        actorKnowledge = actors,
        propagationTrace = Values.copy(adapter.PropagationTrace),
        corePropagationTrace = Values.copy(core.Trace),
        candidates = worldContext and worldContext.worldKnowledge
            and worldContext.worldKnowledge.candidates or {},
        finalRealization = realization,
        explanation = actorID and payload.factID
            and core.Explain(actorID, payload.factID, Runtime.now) or nil,
    }
end

local function worldKnowledgePropagate(context, payload)
    local Values = context.Values
    local adapter = PNC.WorldKnowledge
    local registry = PNC.Registry
    local from = registry and registry.Get
        and registry.Get(payload and payload.fromActorID) or nil
    local to = registry and registry.Get
        and registry.Get(payload and payload.toActorID) or nil
    local transferred
    local reason
    if adapter and type(adapter.PropagateConversation) == "function" then
        transferred, reason = adapter.PropagateConversation(from, to, {
            authorized = payload and payload.authorized == true,
            channel = payload and payload.channel or "conversation",
            now = payload and payload.now or context.Runtime.now,
            max = payload and payload.max or 3,
        })
    else
        reason = "world_knowledge_unavailable"
    end
    return {
        ok = transferred ~= nil,
        type = "world_knowledge_propagation",
        transferred = Values.copy(transferred or {}),
        reason = reason,
        trace = Values.copy(adapter and adapter.PropagationTrace or {}),
    }
end

function CommandRouter.hello(context)
    local Runtime = context.Runtime
    return {
        ok = true,
        type = "hello",
        worker = "project_hoomans_semantic_harness",
        capabilities = capabilities,
        loadedModules = Runtime.loadedModules,
        moduleManifest = Runtime.moduleManifest,
        headlessRequires = Runtime.headlessRequires,
        personaCatalog = personaCatalog(context),
        simulationControlCatalog = simulationControlCatalog(context),
        talkCatalog = talkCatalog(),
        simulationProjection = context.ScenarioSession
            .simulationProjection(context),
        suggestions = context.Values.copy(
            Runtime.view and Runtime.view.semanticSuggestions
        ),
        -- The full production flow catalog is fetched through FLOW_CATALOG.
        -- Keeping the handshake bounded matters as automatic generation grows.
        translation = context.OutputProjection.translationSnapshot(context),
    }
end

function CommandRouter.dispatch(context, request)
    local Runtime = context.Runtime
    local Values = context.Values
    local command = request.command
    local payload = request.payload

    if command == "CONFIG" then
        if type(payload) ~= "table" then
            return nil, "scenario_must_be_object"
        end
        return context.ScenarioSession.compactTransportResponse(
            context,
            context.ScenarioSession.reset(context, payload)
        )
    elseif command == "IMPORT_SOURCE" then
        if type(payload) ~= "table"
            or type(payload.scenario) ~= "table"
        then
            return nil, "source_scenario_must_be_object"
        end
        return context.ScenarioSession.compactTransportResponse(
            context,
            context.ScenarioSession.importSource(
                context,
                payload.scenario,
                payload.metadata,
                payload.provenance,
                payload.providerPayloads
            )
        )
    elseif command == "RESET" then
        return context.ScenarioSession.compactTransportResponse(
            context,
            context.ScenarioSession.reset(context, Values.copy(Runtime.scenario))
        )
    elseif command == "RESET_TURN" then
        context.RuntimeState.resetTurn(Runtime)
        return context.ScenarioSession.snapshot(context)
    elseif command == "RESET_CONVERSATION" then
        return context.ScenarioSession.compactTransportResponse(
            context,
            context.ScenarioSession.resetConversation(context)
        )
    elseif command == "RESET_ACTOR_MUTATIONS" then
        local actor = type(payload) == "table" and payload.actor or payload
        return context.ScenarioSession.compactTransportResponse(
            context,
            context.ScenarioSession.resetActorMutations(context, actor)
        )
    elseif command == "RESET_WORLD" then
        return context.ScenarioSession.compactTransportResponse(
            context,
            context.ScenarioSession.resetWorld(context)
        )
    elseif command == "INPUT" then
        if payload == nil then return nil, "input_required" end
        return context.Conversation.turn(context, tostring(payload))
    elseif command == "PREVIEW" then
        if payload == nil then return nil, "input_required" end
        return context.Conversation.preview(context, tostring(payload))
    elseif command == "RELATIONSHIP_PROPOSAL" then
        local npcID = type(payload) == "table" and payload.npcID
            or context.npcData.npcID
        local propose = PNC.Relationships
            and PNC.Relationships.Propose
        if type(propose) ~= "function" then
            return nil, "relationship_proposal_unavailable"
        end
        local applied, reason, details = propose(npcID)
        details = type(details) == "table" and details or {}
        return {
            ok = true,
            type = "relationship_proposal",
            action = PNC.RelationshipProposalPolicy
                and PNC.RelationshipProposalPolicy.ActionID()
                or "RELATIONSHIP_PROPOSAL",
            accepted = details.accepted == true,
            applied = applied == true,
            reason = reason,
            proposal = context.Values.copy(details),
            simulationProjection = context.ScenarioSession
                .simulationProjection(context),
        }
    elseif command == "RELATIONSHIP_PREVIEW" then
        local npcID = type(payload) == "table" and payload.npcID
            or context.npcData.npcID
        local values = type(payload) == "table" and payload.relationship
            or payload
        local preview = PNC.Relationships
            and PNC.Relationships.Preview
        if type(preview) ~= "function" then
            return nil, "relationship_preview_unavailable"
        end
        local result = preview(npcID, values)
        if type(result) ~= "table" then
            return nil, "relationship_preview_unavailable"
        end
        local relationship = result.relationship or {}
        return {
            ok = true,
            type = "relationship_preview",
            schema = "semantic.relationship.preview.v1",
            action = result.action or "RELATIONSHIP_PROPOSAL",
            standing = result.standing or relationship.state or "unknown",
            reason = result.standingReason,
            approval = relationship.approval or 0,
            respect = relationship.respect or 0,
            familiarity = relationship.familiarity or 0,
            bond = context.Values.copy(result.bond or relationship.bond),
            proposal = context.Values.copy(result),
            persisted = false,
        }
    elseif command == "SUGGESTION_PREDICATE" then
        local predicates = PNC.Semantics
            and PNC.Semantics.SuggestionPredicates or nil
        local view = context.Runtime and context.Runtime.view or nil
        if not predicates or type(predicates.Evaluate) ~= "function" then
            return nil, "suggestion_predicates_unavailable"
        end
        if type(payload) ~= "table" or type(payload.predicate) ~= "table" then
            return nil, "suggestion_predicate_required"
        end
        return {
            ok = true,
            type = "suggestion_predicate",
            result = predicates.Evaluate(
                payload.predicate,
                view and view.spec and view.spec.context or {}
            ),
        }
    elseif command == "SUGGESTION_CLICK" then
        local view = context.Runtime and context.Runtime.view or nil
        if type(payload) ~= "table" or type(payload.frame) ~= "table" then
            return nil, "suggestion_frame_required"
        end
        if not view or not view.session then
            return nil, "conversation_unavailable"
        end
        local suggestions = PNC.Semantics
            and PNC.Semantics.DialogueSuggestions or nil
        if suggestions
            and (
                (type(suggestions.IsConversationCategoryFrame) == "function"
                    and suggestions.IsConversationCategoryFrame(payload.frame))
                or (type(suggestions.IsConversationChoiceFrame) == "function"
                    and suggestions.IsConversationChoiceFrame(payload.frame))
                or (type(suggestions.IsConversationRootChoiceFrame)
                    == "function"
                    and suggestions.IsConversationRootChoiceFrame(payload.frame))
                or (type(suggestions.IsShortcutFrame) == "function"
                    and suggestions.IsShortcutFrame(payload.frame))
                or (type(suggestions.IsBackFrame) == "function"
                    and suggestions.IsBackFrame(payload.frame))
                or (type(suggestions.IsGroupFrame) == "function"
                    and suggestions.IsGroupFrame(payload.frame))
            )
        then
            return context.Conversation.semanticClick(
                context,
                Values.copy(payload.frame)
            )
        end
        context.Runtime.semanticClickFrame = Values.copy(payload.frame)
        return context.Conversation.turn(
            context,
            tostring(payload.frame.textFallback or payload.frame.candidateID or "")
        )
    elseif command == "LANGUAGE" then
        if payload == nil then return nil, "language_required" end
        local response = context.Translations.setLanguage(context,
            type(payload) == "table" and payload.language or payload)
        context.Conversation.refreshViewContext(context)
        local view = context.Runtime.view
        local input = PNC.Semantics and PNC.Semantics.DialogueInput or nil
        local internal = input and input.Internal or nil
        local suggestions
        if view and view.lastSemanticDialogueResult
            and internal and type(internal.RefreshSuggestions) == "function"
        then
            suggestions = internal.RefreshSuggestions(
                view, view.lastSemanticDialogueResult
            )
        elseif internal
            and type(internal.RefreshRootSuggestions) == "function"
        then
            suggestions = internal.RefreshRootSuggestions(view)
        end
        response.suggestions = context.Values.copy(suggestions)
        return response
    elseif command == "TOOL_REPLY" then
        return context.OutputProjection.toolReply(context, payload)
    elseif command == "TEST_PRODUCTION_INVENTORY_FIXTURE" then
        return productionInventoryFixture(context, payload)
    elseif command == "INSTALL_ENGINE_ITEM_TYPES" then
        if not context.ProductionRehydration
            or type(context.ProductionRehydration
                .installEngineItemTypeFixture) ~= "function"
        then
            return nil, "engine_item_type_fixture_unavailable"
        end
        local count = context.ProductionRehydration
            .installEngineItemTypeFixture(context, payload)
        return {
            ok = true,
            type = "engine_item_type_fixture",
            count = count,
        }
    elseif command == "INSPECT_ACTOR_STATE" then
        return actorStateProjection(context)
    elseif command == "SNAPSHOT" then
        return context.ScenarioSession.snapshot(context)
    elseif command == "CONVERSATION_GRAPH" then
        return {
            ok = true,
            type = "conversation_graph",
            graph = context.Conversation.graphProjection(
                context.Runtime and context.Runtime.view
            ),
        }
    elseif command == "FLOW_CATALOG" then
        return context.FlowEditor.catalog(context)
    elseif command == "FLOW_VALIDATE" then
        if type(payload) ~= "table" then
            return nil, "flow_definition_must_be_object"
        end
        return context.FlowEditor.validate(context, payload)
    elseif command == "FLOW_REGISTER" then
        if type(payload) ~= "table" then
            return nil, "flow_definition_must_be_object"
        end
        return context.FlowEditor.register(context, payload)
    elseif command == "FLOW_GENERATE" or command == "FLOW_COVERAGE" then
        return context.FlowEditor.generate(context)
    elseif command == "REPLAY_SEMANTIC_QUEST" then
        if type(payload) ~= "table" then
            return nil, "quest_request_must_be_object"
        end
        local router = PNC.ServerCommandRouter
        local handled = router and type(router.Handle) == "function"
            and router.Handle(
                PNC.Const.CMD_SEMANTIC_QUEST_REQUEST,
                context.player,
                payload
            ) or false
        return { ok = true, type = "semantic_quest_replay", handled = handled }
    elseif command == "COMMITMENT" then
        if type(payload) ~= "table" then
            return nil, "commitment_request_must_be_object"
        end
        return context.Commitments.dispatch(context, payload)
    elseif command == "BACKSTORY" then
        return backstorySnapshot(context, payload)
    elseif command == "BACKSTORY_FACT" then
        return backstoryFact(context, payload)
    elseif command == "KNOWLEDGE_BOOTSTRAP" then
        local callback = PNC.PlayerKnowledgeCommands
            and PNC.PlayerKnowledgeCommands.HandleBootstrap
        if type(callback) ~= "function" then
            return nil, "knowledge_bootstrap_unavailable"
        end
        local args = Values.copy(type(payload) == "table" and payload or {})
        args.requestID = args.requestID
            or "harness-bootstrap-" .. tostring(Runtime.now)
        args.scope = "all"
        local result = callback(context.player, args)
        return {
            ok = true,
            type = "knowledge_bootstrap",
            result = Values.copy(result),
        }
    elseif command == "KNOWLEDGE_DISCOVER" then
        return knowledgeDiscover(context, payload)
    elseif command == "KNOWLEDGE_METRICS" then
        return knowledgeMetrics(context, payload)
    elseif command == "WORLD_KNOWLEDGE_INSPECT" then
        return worldKnowledgeInspect(context, payload)
    elseif command == "WORLD_KNOWLEDGE_PROPAGATE" then
        return worldKnowledgePropagate(context, payload)
    elseif command == "PERSONA_CATALOG" then
        return personaCatalog(context, payload)
    elseif command == "PERSONA_PREVIEW" then
        return personaPreview(context, payload)
    elseif command == "SIMULATION_CONTROL_CATALOG" then
        return simulationControlCatalog(context, payload)
    elseif command == "TALK_CATALOG" then
        return {
            ok = true,
            type = "talk_catalog",
            schema = "semantic.talk.catalog.v1",
            targets = TalkParity.GetCatalog(),
        }
    elseif command == "TALK_START" then
        payload = type(payload) == "table" and payload or {}
        local result, reason = TalkParity.Start(
            context,
            payload.targetID or payload.target or "current",
            payload.utterance or "hello"
        )
        if not result then return nil, reason end
        return result
    elseif command == "TALK_MATRIX" then
        return TalkParity.Matrix(context, payload)
    elseif command == "FACT_CATALOG" then
        return {
            ok = true,
            type = "fact_catalog",
            facts = context.EngineFacts and context.EngineFacts.List
                and context.EngineFacts.List() or {},
        }
    elseif command == "EVENT_CATALOG" then
        return {
            ok = true,
            type = "event_catalog",
            events = context.EngineEvents and context.EngineEvents.ListTypes
                and context.EngineEvents.ListTypes() or {},
        }
    elseif command == "PING" then
        return {
            ok = true,
            type = "pong",
            worker = "project_hoomans_semantic_harness",
            state = "ready",
        }
    elseif command == "CAPABILITIES" then
        return {
            ok = true,
            type = "capabilities",
            protocolVersion = context.Protocol.VERSION,
            capabilities = capabilities,
            loadedModules = Runtime.loadedModules,
            moduleManifest = Runtime.moduleManifest,
            headlessRequires = Runtime.headlessRequires,
            personaCatalog = personaCatalog(context),
            simulationControlCatalog = simulationControlCatalog(context),
            talkCatalog = talkCatalog(),
            simulationProjection = context.ScenarioSession
                .simulationProjection(context),
            suggestions = context.Values.copy(
                Runtime.view and Runtime.view.semanticSuggestions
            ),
            translation = context.OutputProjection.translationSnapshot(context),
        }
    elseif command == "QUIT" then
        return { ok = true, type = "closed" }, nil, true
    end

    return nil, "unknown_command:" .. tostring(command)
end

return CommandRouter
