-- Definition and resolution contract for one-time NPC identities.

PNC = PNC or {}
PNC.UniqueNPCs = PNC.UniqueNPCs or {}

pcall(require, "PNC/Core/Identity/PNC_Identity_Appearance")

local Unique = PNC.UniqueNPCs
local Identity = PNC.Identity
local Appearance = Identity.Appearance

Unique.SCHEMA_VERSION = 2
Unique.Definitions = Unique.Definitions or {}
Unique.Ordered = Unique.Ordered or {}
Unique.Errors = Unique.Errors or {}
Unique.ErrorOrder = Unique.ErrorOrder or {}
Unique.InventoryTemplates = Unique.InventoryTemplates or {}

local function copy(value, seen)
    if PNC.Core and PNC.Core.DeepCopy then
        return PNC.Core.DeepCopy(value)
    end
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local output = {}
    seen[value] = output
    for key, item in pairs(value) do
        output[copy(key, seen)] = copy(item, seen)
    end
    return output
end

local function stringValue(value)
    if value == nil or value == "" then return nil end
    return tostring(value)
end

local function safeID(value)
    value = stringValue(value)
    if not value or #value < 3 or #value > 128 then return nil end
    if string.match(value, "^[%w_%-%.:]+$") == nil then return nil end
    return value
end

local function normalizeTraits(source, normalizer)
    if type(source) ~= "table" then return nil end
    if normalizer then return normalizer(source) end
    return copy(source)
end

local function rememberError(definition, reason)
    local source = type(definition) == "table" and definition or {}
    local id = stringValue(source.uniqueDefinitionId or source.id)
    local key = id or ("invalid:" .. tostring(reason or "definition"))
    if not Unique.Errors[key] then
        Unique.ErrorOrder[#Unique.ErrorOrder + 1] = key
    end
    Unique.Errors[key] = {
        id = id,
        displayName = stringValue(source.displayName or source.name),
        reason = tostring(reason or "invalid_definition"),
    }
end

function Unique.NormalizeDefinition(definition)
    local source
    local id
    local displayName
    local output
    local spawnChance
    if type(definition) ~= "table" then
        return nil, "invalid_definition"
    end
    source = copy(definition)
    id = safeID(source.uniqueDefinitionId or source.id)
    if not id then return nil, "unique_definition_id_required" end
    displayName = stringValue(source.displayName or source.name)
    if not displayName then return nil, "display_name_required:" .. id end
    if type(source.isFemale) ~= "boolean" then
        return nil, "is_female_boolean_required:" .. id
    end
    if source.spawnChance ~= nil then
        spawnChance = math.max(0, math.min(1, tonumber(source.spawnChance) or 0))
    end
    output = {
        id = id,
        uniqueDefinitionId = id,
        version = math.max(1, math.floor(tonumber(source.version) or 1)),
        appearanceVersion = math.max(1, math.floor(
            tonumber(source.appearanceVersion)
            or (source.appearance and Appearance
                and Appearance.SCHEMA_VERSION)
                or 1
        )),
        displayName = displayName,
        name = displayName,
        isFemale = source.isFemale,
        identity = type(source.identity) == "table"
            and copy(source.identity) or nil,
        identitySeed = tonumber(source.identitySeed) or nil,
        archetypeID = stringValue(source.archetypeID),
        archetypeLabel = stringValue(source.archetypeLabel),
        tacticalClass = stringValue(source.tacticalClass),
        visualProfile = stringValue(source.visualProfile),
        outfit = stringValue(source.outfit),
        appearance = Appearance and Appearance.Normalize
            and Appearance.Normalize(source.appearance, source.outfit)
            or nil,
        chanceWeight = math.max(0, tonumber(source.chanceWeight) or 1),
        spawnChance = spawnChance,
        hpMax = tonumber(source.hpMax) or nil,
        weaponMode = stringValue(source.weaponMode),
        attackType = stringValue(source.attackType),
        equipmentSpawnMode = stringValue(source.equipmentSpawnMode),
        equipmentPoolID = stringValue(source.equipmentPoolID),
        combatProfile = type(source.combatProfile) == "table"
            and copy(source.combatProfile) or nil,
        equipment = type(source.equipment) == "table"
            and copy(source.equipment) or nil,
        inventory = type(source.inventory) == "table"
            and copy(source.inventory) or nil,
        orderSpec = type(source.orderSpec) == "table"
            and copy(source.orderSpec) or nil,
        patrolPoints = type(source.patrolPoints) == "table"
            and copy(source.patrolPoints) or nil,
        hostility = type(source.hostility) == "table"
            and copy(source.hostility) or nil,
        inventoryTemplateRef = stringValue(
            source.inventoryTemplateRef or source.startingInventoryTemplate
        ),
        startingItems = type(source.startingItems) == "table"
            and copy(source.startingItems) or nil,
        skillLevels = PNC.Types and PNC.Types.Internal
            and PNC.Types.Internal.NormalizeSkillLevels(
                source.skillLevels or source.skillBaseLevels
            ) or copy(source.skillLevels or source.skillBaseLevels),
        vanillaTraits = normalizeTraits(
            source.vanillaTraits or source.physiologicalTraits,
            PNC.PlayerNeedsModel and PNC.PlayerNeedsModel.NormalizeTraits
        ),
        dynamicTraits = normalizeTraits(
            source.dynamicTraits,
            PNC.ConditionStats and PNC.ConditionStats.NormalizeTraits
        ),
        npcTraits = PNC.NPCTraits and PNC.NPCTraits.NormalizeSet
            and PNC.NPCTraits.NormalizeSet(source.npcTraits) or nil,
        allowedJobs = type(source.allowedJobs) == "table"
            and copy(source.allowedJobs) or nil,
        jobPriorities = type(source.jobPriorities) == "table"
            and copy(source.jobPriorities) or nil,
        social = type(source.social) == "table"
            and copy(source.social) or nil,
        factionID = stringValue(source.factionID),
        membershipStatus = stringValue(source.membershipStatus),
        factionRole = stringValue(source.factionRole),
        factionRank = stringValue(source.factionRank),
        factionJoinedAt = tonumber(source.factionJoinedAt),
        ownerUsername = stringValue(source.ownerUsername),
        ownerOnlineID = tonumber(source.ownerOnlineID),
        forceLive = source.forceLive == true,
        debug = source.debug == true,
        persist = source.persist ~= false,
        recruited = source.recruited == true,
        mapPresentation = type(source.mapPresentation) == "table"
            and copy(source.mapPresentation) or nil,
        recipeKnowledge = type(source.recipeKnowledge) == "table"
            and copy(source.recipeKnowledge) or nil,
    }
    output.vanillaTraitsAuthored = source.vanillaTraits ~= nil
        or source.physiologicalTraits ~= nil
    output.dynamicTraitsAuthored = source.dynamicTraits ~= nil
    if Appearance and Appearance.Validate then
        local appearanceValid, appearanceReason = Appearance.Validate(
            output.appearance)
        if not appearanceValid then
            return nil, "invalid_appearance:" .. tostring(appearanceReason)
        end
    end
    return output
end

function Unique.Register(definition, options)
    local normalized
    local reason
    local existing
    local optionsValue = type(options) == "table" and options or {}
    normalized, reason = Unique.NormalizeDefinition(definition)
    if not normalized then
        rememberError(definition, reason)
        return false, reason
    end
    existing = Unique.Definitions[normalized.id]
    if existing and optionsValue.override ~= true then
        rememberError(definition,
            "duplicate_unique_definition:" .. normalized.id)
        return false, "duplicate_unique_definition:" .. normalized.id
    end
    if not existing then Unique.Ordered[#Unique.Ordered + 1] = normalized.id end
    Unique.Definitions[normalized.id] = normalized
    Unique.Errors[normalized.id] = nil
    return true, normalized.id
end

function Unique.Get(id)
    id = safeID(id)
    return id and copy(Unique.Definitions[id]) or nil
end

function Unique.List()
    local ids = {}
    local output = {}
    local index
    for id in pairs(Unique.Definitions) do ids[#ids + 1] = id end
    table.sort(ids)
    for index = 1, #ids do
        output[index] = copy(Unique.Definitions[ids[index]])
    end
    return output
end

function Unique.ListRegistrationErrors()
    local output = {}
    local key
    local value
    for _, key in ipairs(Unique.ErrorOrder) do
        value = Unique.Errors[key]
        if value then output[#output + 1] = copy(value) end
    end
    table.sort(output, function(left, right)
        return tostring(left.id or left.reason)
            < tostring(right.id or right.reason)
    end)
    return output
end

function Unique.RegisterInventoryTemplate(template, options)
    local source
    local id
    local items
    local normalized
    local index
    local item
    local key
    local optionsValue = type(options) == "table" and options or {}
    if type(template) ~= "table" then
        return false, "invalid_inventory_template"
    end
    source = copy(template)
    id = safeID(source.id)
    if not id then return false, "inventory_template_id_required" end
    items = type(source.items) == "table" and source.items or {}
    normalized = {
        id = id,
        version = math.max(1, math.floor(tonumber(source.version) or 1)),
        items = {},
    }
    for index = 1, #items do
        item = items[index]
        key = type(item) == "table"
            and stringValue(item.templateKey or item.key) or nil
        if type(item) ~= "table" or not key
            or not stringValue(item.type)
        then
            return false, "inventory_template_item_invalid:" .. id
        end
        normalized.items[index] = copy(item)
        normalized.items[index].templateKey = key
        normalized.items[index].type = stringValue(item.type)
    end
    if Unique.InventoryTemplates[id] and optionsValue.override ~= true then
        return false, "duplicate_inventory_template:" .. id
    end
    Unique.InventoryTemplates[id] = normalized
    return true, id
end

function Unique.GetInventoryTemplate(id)
    id = safeID(id)
    return id and copy(Unique.InventoryTemplates[id]) or nil
end

local function resolveSeed(definition, context)
    local seed
    local worldSeed
    context = type(context) == "table" and context or {}
    seed = tonumber(context.identitySeed) or tonumber(definition.identitySeed)
    if seed then return Identity.NormalizeSeed(seed, definition.id) end
    worldSeed = tonumber(context.worldSeed) or tonumber(context.seed)
    if worldSeed then
        return Identity.MixSeed(worldSeed, "unique:" .. definition.id)
    end
    return Identity.NormalizeSeed(nil, "unique:" .. definition.id)
end

function Unique.Resolve(definition, context)
    local normalized
    local reason
    local output
    local seed
    local identity
    context = type(context) == "table" and context or {}
    normalized, reason = Unique.NormalizeDefinition(definition)
    if not normalized then return nil, reason end
    seed = resolveSeed(normalized, context)
    identity = Identity.GenerateResolvedIdentity({
        id = normalized.id,
        displayName = normalized.displayName,
        isFemale = normalized.isFemale,
        identity = normalized.identity,
        archetypeID = normalized.archetypeID or context.archetypeID,
        identitySeed = seed,
    })
    output = copy(normalized)
    output.id = nil
    output.uniqueDefinitionId = normalized.id
    output.uniqueDefinitionVersion = normalized.version
    output.identitySeed = seed
    output.identity = identity
    output.displayName = identity.displayName
    output.name = identity.displayName
    output.isFemale = identity.isFemale == true
    output.archetypeID = normalized.archetypeID or context.archetypeID
    output.generation = copy(context.generation)
    output.vanillaTraitsAuthored = normalized.vanillaTraitsAuthored
    output.dynamicTraitsAuthored = normalized.dynamicTraitsAuthored
    if output.vanillaTraits == nil
        and PNC.PlayerNeedsModel
        and PNC.PlayerNeedsModel.ResolveInitialTraits
    then
        output.vanillaTraits = PNC.PlayerNeedsModel.ResolveInitialTraits(
            nil,
            seed,
            output.archetypeID,
            false
        )
        output.vanillaTraitsAuthored = true
    end
    if output.dynamicTraits == nil
        and PNC.ConditionStats
        and PNC.ConditionStats.ResolveInitialTraits
    then
        output.dynamicTraits = PNC.ConditionStats.ResolveInitialTraits(
            nil,
            seed,
            output.archetypeID,
            false
        )
        output.dynamicTraitsAuthored = true
    end
    return output
end

return Unique
