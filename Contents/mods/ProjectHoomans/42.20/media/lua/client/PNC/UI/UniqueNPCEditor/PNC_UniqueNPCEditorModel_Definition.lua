-- Definition import and sparse serialization for the Unique NPC editor model.

PNC = PNC or {}
PNC.UniqueNPCEditorModel = PNC.UniqueNPCEditorModel or {}

local Model = PNC.UniqueNPCEditorModel
local Internal = Model.Internal or {}
local Unique = PNC.UniqueNPCs
local Identity = PNC.Identity
local Appearance = Identity and Identity.Appearance
local copy = Internal.copy
local text = Internal.text
local hasEntries = Internal.hasEntries
local nextSeed = Internal.nextSeed
local nameParts = Internal.nameParts
local exportItems = Internal.exportItems
local captureAppearanceItems = Internal.captureAppearanceItems

function Model.FromDefinition(definition, fileName)
    local output = Model.New()
    for key, value in pairs(copy(definition or {})) do output[key] = value end
    output.displayName = text(output.displayName or output.name) or ""
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
        output.appearanceAuthored.appearance = definition.appearance ~= nil
    end
    output.authoredFields = type(output.authoredFields) == "table"
        and output.authoredFields or {}
    for _, key in ipairs({ "skillLevels", "vanillaTraits", "dynamicTraits",
        "npcTraits" }) do
        if definition[key] ~= nil then output.authoredFields[key] = true end
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
        or tonumber(output.identitySeed) or nextSeed()
    output.identitySeed = nil
    output.id = output.id or output.uniqueDefinitionId
    output.identityIDLocked = true
    output.fileName = fileName
    output.originalDisplayName = output.displayName
    output.startingItems = type(output.startingItems) == "table"
        and output.startingItems or {}
    output.equipmentSpawnMode = output.equipmentSpawnMode or "none"
    output._dirty = false
    return output
end

function Model.BuildDefinition(draft)
    local def = {}
    local survivor = draft.identity and draft.identity.survivor or {}
    local appearance
    local voice
    local fields = {
        "archetypeID", "archetypeLabel", "tacticalClass", "visualProfile",
        "weaponMode", "attackType", "equipmentSpawnMode",
        "equipmentPoolID", "chanceWeight", "spawnChance", "skillLevels",
        "vanillaTraits", "dynamicTraits", "npcTraits", "factionID",
        "membershipStatus", "factionRole", "factionRank", "ownerUsername",
        "forceLive", "debug", "persist", "recruited", "social", "hostility",
        "equipment", "combatProfile", "orderSpec", "patrolPoints",
        "allowedJobs", "jobPriorities", "mapPresentation", "recipeKnowledge",
        "inventoryTemplateRef", "ownerOnlineID", "factionJoinedAt",
    }
    def.id = Model.BuildID(draft)
    def.uniqueDefinitionId = def.id
    def.version = 1
    local forename, surname = Model.NameParts(draft)
    local displayName = nil
    if forename and surname then
        displayName = tostring(forename) .. " " .. tostring(surname)
    else
        displayName = text(draft.displayName)
    end
    def.displayName = displayName
    def.name = def.displayName
    def.isFemale = draft.isFemale == true
    for _, key in ipairs(fields) do
        if draft[key] ~= nil and draft[key] ~= "" then def[key] = copy(draft[key]) end
    end
    local explicit = {}
    for _, key in ipairs({ "forename", "surname", "hairModel", "beardModel",
        "skinTexture", "hairColor", "skinColor", "voice", "voicePrefix",
        "voiceType", "voicePitch" }) do
        if survivor[key] ~= nil
            and (survivor[key] ~= ""
                or draft.appearanceAuthored
                and draft.appearanceAuthored[key] == true)
        then
            explicit[key] = copy(survivor[key])
        end
    end
    appearance = Appearance and Appearance.Normalize
        and Appearance.Normalize(draft.appearance, draft.outfit) or nil
    if appearance then captureAppearanceItems(draft, appearance) end
    voice = appearance and appearance.voice or nil
    if voice and voice.mode == "item" then
        if voice.prefix ~= nil then explicit.voice = copy(voice.prefix) end
        if voice.prefix ~= nil then explicit.voicePrefix = copy(voice.prefix) end
        if voice.type ~= nil then explicit.voiceType = copy(voice.type) end
        if voice.pitch ~= nil then explicit.voicePitch = copy(voice.pitch) end
    end
    if hasEntries(explicit) then def.identity = { survivor = explicit } end
    def.startingItems = exportItems(draft)
    if #def.startingItems == 0 then def.startingItems = nil end
    if Appearance and Appearance.Normalize then
        def.appearance = appearance
        if appearance and Appearance.HasExplicitSlots
            and Appearance.HasExplicitSlots(appearance)
        then
            def.appearanceVersion = 2
        end
    end
    return def
end

return Model
