-- JSON-lines command routing for one semantic worker session.

local CommandRouter = {}

local function hasEntries(value)
    if type(value) ~= "table" then return false end
    for _ in pairs(value) do return true end
    return false
end

local capabilities = {
    "CONFIG", "RESET", "INPUT", "LANGUAGE", "TOOL_REPLY",
    "PREVIEW", "SNAPSHOT", "CONVERSATION_GRAPH", "FLOW_CATALOG", "FLOW_VALIDATE",
    "RELATIONSHIP_PROPOSAL",
    "SUGGESTION_PREDICATE", "SUGGESTION_CLICK",
    "FLOW_REGISTER", "PING", "CAPABILITIES", "QUIT",
    "FACT_CATALOG", "EVENT_CATALOG", "FLOW_GENERATE", "FLOW_COVERAGE",
    "REPLAY_SEMANTIC_QUEST",
    "COMMITMENT", "BACKSTORY", "BACKSTORY_FACT",
    "KNOWLEDGE_BOOTSTRAP", "KNOWLEDGE_DISCOVER", "KNOWLEDGE_METRICS",
    "WORLD_KNOWLEDGE_INSPECT", "WORLD_KNOWLEDGE_PROPAGATE",
    "PERSONA_CATALOG",
    "SIMULATION_CONTROL_CATALOG",
}

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
    })
    add("world.worldAgeHours", "world.worldAgeHours", "World", "Time", "World age (hours)", "spinbox", "number", {
        min = 0, max = 1000000, step = 0.5, format = "%.1f",
    })
    add("world.zombieKills", "world.zombieKills", "World", "World facts", "Zombie kills", "integer", "integer", {
        min = 0, max = 1000000, step = 1,
    })
    add("world.weather", "world.weather", "World", "World facts", "Weather", "combobox", "enum", {
        options = { "clear", "rain", "fog", "snow" },
        optionsSource = "semantic_lab.harness",
    })
    add("world.weatherTransition", "world.weatherTransition", "World", "World facts", "Weather transition", "text", "text", {
        emptyToNull = true,
    })

    add("player.characterUUID", "player.characterUUID", "Actors", "Player", "Player ID", "text", "text", {
        workbench = true, workbenchPanel = "Player", workbenchTab = "Overview",
        workbenchSection = "Overview",
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
        workbench = true, workbenchPanel = "Player", workbenchTab = "Overview",
        workbenchSection = "Overview",
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
        workbench = true, workbenchPanel = "NPC Target", workbenchTab = "Overview",
        workbenchSection = "Overview",
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
        workbenchSection = "Needs + personality",
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
        workbenchSection = "Needs + personality",
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
            workbenchSection = "Needs + personality",
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

local function backstorySnapshot(payload)
    local memory = PNC.Conversation and PNC.Conversation.Memory
    if not memory or type(memory.GetBackstoryProfile) ~= "function" then
        return nil, "backstory_memory_unavailable"
    end
    payload = type(payload) == "table" and payload or {}
    local record = {
        id = tostring(payload.npcID or "harness-backstory-npc"),
        tacticalClass = tostring(payload.tacticalClass or "colonist"),
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
            tacticalClass = profile.tacticalClass,
            facts = facts,
        },
    }
end

local function backstoryFact(payload)
    local facts = PNC.Semantics and PNC.Semantics.DialogueFacts
    local result
    payload = type(payload) == "table" and payload or {}
    if not facts or type(facts.Resolve) ~= "function" then
        return nil, "dialogue_fact_registry_unavailable"
    end
    result = facts.Resolve({
        subject = "NPC_BACKSTORY",
        slots = { kind = payload.kind or payload.topic },
    }, nil, {
        npcRecord = {
            id = tostring(payload.npcID or "harness-backstory-npc"),
            tacticalClass = tostring(payload.tacticalClass or "colonist"),
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
        return context.ScenarioSession.reset(context, payload)
    elseif command == "RESET" then
        return context.ScenarioSession.reset(context, Values.copy(Runtime.scenario))
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
        return backstorySnapshot(payload)
    elseif command == "BACKSTORY_FACT" then
        return backstoryFact(payload)
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
    elseif command == "SIMULATION_CONTROL_CATALOG" then
        return simulationControlCatalog(context, payload)
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
