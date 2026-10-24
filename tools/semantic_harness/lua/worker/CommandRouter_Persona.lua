-- Persona and relationship catalogs for the semantic worker router.

local Persona = {}

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


Persona.catalog = personaCatalog
Persona.preview = personaPreview

function Persona.handle(context, command, payload)
    local Runtime = context.Runtime
    local Values = context.Values

    if command == "PERSONA_CATALOG" then
        return personaCatalog(context, payload)
    elseif command == "PERSONA_PREVIEW" then
        return personaPreview(context, payload)
    end
    return false
end

return Persona
