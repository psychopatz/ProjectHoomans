-- Definition import and sparse serialization for the Unique NPC editor model.

PNC = PNC or {}
PNC.UniqueNPCEditorModel = PNC.UniqueNPCEditorModel or {}

local Model = PNC.UniqueNPCEditorModel
local Internal = Model.Internal or {}
local Unique = PNC.UniqueNPCs
local Identity = PNC.Identity
local Appearance = Identity and Identity.Appearance
local Authoring = PNC.NPCAuthoring or require "PNC/Core/Identity/PNC_NPCAuthoring"
local Blueprint = Authoring.Blueprint
local copy = Internal.copy
local text = Internal.text
local hasEntries = Internal.hasEntries
local nextSeed = Internal.nextSeed
local nameParts = Internal.nameParts
local exportItems = Internal.exportItems
local captureAppearanceItems = Internal.captureAppearanceItems

function Model.FromDefinition(definition, fileName, options)
    if type(fileName) == "table" then
        options = fileName
        fileName = options.fileName
    end
    options = type(options) == "table" and options or {}
    local source = copy(definition or {})
    local canonical
    local reason
    local canonicalClears
    local canonicalSeed
    if source.schemaId == Authoring.Registry.SCHEMA_ID
        or source.fields and source.schemaId
    then
        canonical, reason = Blueprint.Deserialize(source)
        if not canonical then return nil, reason end
        canonicalClears = copy(canonical.clears or {})
        canonicalSeed = canonical.generationSeed
        source, reason = Blueprint.ToDefinition(canonical, {
            id = source.id or canonical.id,
            version = source.version,
        })
        if not source then return nil, reason end
    end
    local output = Model.New({
        previewSeed = canonicalSeed or source.generationSeed
            or options.previewSeed,
    })
    for key, value in pairs(source) do output[key] = value end
    output.displayName = text(output.displayName) or ""
    output.isFemale = output.isFemale == true
    output.identity = type(output.identity) == "table" and output.identity or { survivor = {} }
    output.identity.survivor = type(output.identity.survivor) == "table"
        and output.identity.survivor or {}
    local first, last = nameParts(output.displayName, output.identity.survivor)
    output.identity.survivor.forename = text(output.identity.survivor.forename) or first
    output.identity.survivor.surname = text(output.identity.survivor.surname) or last
    output.appearanceAuthored = type(output.appearanceAuthored) == "table"
        and output.appearanceAuthored or {}
    if Appearance and Appearance.Normalize then
        output.appearance = Appearance.Normalize(output.appearance,
            output.outfit)
        output.appearanceAuthored.appearance = source.appearance ~= nil
    end
    output.authoredFields = type(output.authoredFields) == "table"
        and output.authoredFields or {}
    output.authoringClears = canonicalClears or {}
    for _, key in ipairs({ "skillLevels", "vanillaTraits", "dynamicTraits",
        "npcTraits", "startingItems" }) do
        if source[key] ~= nil then output.authoredFields[key] = true end
    end
    for _, key in ipairs({ "hairModel", "beardModel", "skinTexture",
        "hairColor", "skinColor", "voice", "voicePrefix", "voiceType",
        "voicePitch" }) do
        if output.identity.survivor[key] ~= nil then
            output.appearanceAuthored[key] = true
        end
    end
    -- Older files may contain identitySeed.  Use it only to keep the loaded
    -- preview stable during this editing session; never emit it again.
    output.previewSeed = tonumber(output.previewSeed)
        or tonumber(canonicalSeed)
        or tonumber(source.generationSeed)
        or tonumber(output.identitySeed) or nextSeed()
    output.identitySeed = nil
    output.id = output.id or output.uniqueDefinitionId
    output.identityIDLocked = true
    output.fileName = fileName or options.fileName
    output.originalDisplayName = output.displayName
    output.startingItems = type(output.startingItems) == "table"
        and output.startingItems or {}
    output.equipmentSpawnMode = output.equipmentSpawnMode or "none"
    output._dirty = false
    return output
end

function Model.BuildBlueprint(draft, options)
    local source = copy(draft or {})
    local survivor = source.identity and source.identity.survivor or {}
    local appearance
    local voice
    local startingItems
    local optionsValue = type(options) == "table" and options or {}
    local blueprint
    local reason
    appearance = Appearance and Appearance.Normalize
        and Appearance.Normalize(source.appearance) or nil
    if appearance then captureAppearanceItems(draft, appearance) end
    source.appearance = appearance
    source.appearanceAuthored = source.appearanceAuthored or {}
    if appearance then source.appearanceAuthored.appearance = true end
    voice = appearance and appearance.voice or nil
    if voice and voice.mode == "item" then
        source.identity = source.identity or {}
        source.identity.survivor = source.identity.survivor or {}
        if voice.prefix ~= nil then source.identity.survivor.voice = copy(voice.prefix) end
        if voice.prefix ~= nil then source.identity.survivor.voicePrefix = copy(voice.prefix) end
        if voice.type ~= nil then source.identity.survivor.voiceType = copy(voice.type) end
        if voice.pitch ~= nil then source.identity.survivor.voicePitch = copy(voice.pitch) end
    end
    startingItems = exportItems(draft)
    if #startingItems == 0 then startingItems = nil end
    blueprint, reason = Blueprint.FromDraft(source, {
        id = optionsValue.id or Model.BuildID(source),
        generationSeed = optionsValue.generationSeed or source.previewSeed,
        startingItems = startingItems,
        explicitClears = source.authoringClears,
    })
    if source.nicknameCleared == true then
        blueprint, reason = Blueprint.Clear(blueprint, "identity.nickname")
    end
    if not blueprint then return nil, reason end
    return blueprint
end

function Model.BuildDefinition(draft)
    local blueprint, reason = Model.BuildBlueprint(draft)
    local definition
    if not blueprint then return nil, reason end
    definition, reason = Blueprint.ToDefinition(blueprint, {
        id = Model.BuildID(draft),
        version = 1,
    })
    if not definition then return nil, reason end
    return definition
end

return Model
