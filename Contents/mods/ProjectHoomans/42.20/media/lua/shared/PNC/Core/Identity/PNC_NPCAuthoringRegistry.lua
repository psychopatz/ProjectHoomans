-- Canonical authoring field registry and representation codecs for NPCs.
--
-- Durable authoring data uses the logical field IDs below.  Runtime records
-- still use their existing concrete accessors; the registry is the adapter
-- between those representations.  This keeps the field vocabulary in one
-- place without making the compact transport a second authoring schema.

PNC = PNC or {}
PNC.NPCAuthoringFieldRegistry = PNC.NPCAuthoringFieldRegistry or {}

local Registry = PNC.NPCAuthoringFieldRegistry

Registry.SCHEMA_ID = "ProjectHoomans.NPCAuthoring"
Registry.SCHEMA_VERSION = 1
Registry.PROTOCOL_VERSION = 1
Registry.MAX_FIELDS = 96
Registry.MAX_CLEAR_FIELDS = 48

Registry._fields = Registry._fields or {}
Registry._retiredWireCodes = Registry._retiredWireCodes or {}
Registry._fingerprint = nil

local function copy(value, seen)
    if PNC.Core and PNC.Core.DeepCopy then
        return PNC.Core.DeepCopy(value)
    end
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local output = {}
    seen[value] = output
    for key, child in pairs(value) do
        output[copy(key, seen)] = copy(child, seen)
    end
    return output
end

local function trim(value)
    local output = tostring(value or "")
    output = string.gsub(output, "^%s+", "")
    output = string.gsub(output, "%s+$", "")
    return output ~= "" and output or nil
end

local function normalizeString(value, limits)
    if value == nil then return nil end
    local output = trim(value)
    if not output then return nil end
    limits = limits or {}
    if limits.maxLength and #output > limits.maxLength then
        return nil, "string_too_long"
    end
    return output
end

local function normalizeBoolean(value)
    if type(value) ~= "boolean" then return nil, "boolean_required" end
    return value
end

local function normalizeNumber(value, limits)
    local output = tonumber(value)
    if not output then return nil, "number_required" end
    limits = limits or {}
    if limits.integer then
        output = math.floor(output)
    end
    if limits.min and output < limits.min then
        return nil, "number_below_min"
    end
    if limits.max and output > limits.max then
        return nil, "number_above_max"
    end
    return output
end

local function normalizeColor(value)
    if type(value) ~= "table" then return nil, "color_required" end
    local output = {}
    for _, key in ipairs({ "r", "g", "b" }) do
        local number = tonumber(value[key])
        if not number then return nil, "color_component_required" end
        output[key] = math.max(0, math.min(1, number))
    end
    return output
end

local function normalizeCollection(value, limits, depth)
    if type(value) ~= "table" then return nil, "table_required" end
    limits = limits or {}
    depth = depth or 0
    if depth > (limits.maxDepth or 8) then
        return nil, "table_too_deep"
    end
    local output = {}
    local count = 0
    for key, child in pairs(value) do
        count = count + 1
        if count > (limits.maxEntries or 128) then
            return nil, "table_too_large"
        end
        if type(child) == "table" then
            local normalized, reason = normalizeCollection(child, limits, depth + 1)
            if not normalized then return nil, reason end
            output[key] = normalized
        elseif type(child) == "string" then
            local normalized, reason = normalizeString(child, limits)
            if not normalized and child ~= "" then return nil, reason end
            output[key] = normalized
        elseif type(child) == "number" or type(child) == "boolean" then
            output[key] = child
        elseif child == nil then
            output[key] = nil
        else
            return nil, "unsupported_value_type"
        end
    end
    return output
end

local function normalizeMap(value)
    if type(value) ~= "table" then return nil, "map_required" end
    local output = {}
    for key, child in pairs(value) do
        if child then output[tostring(key)] = true end
    end
    return output
end

local function pathGet(root, path)
    local current = root
    local index
    if type(path) ~= "table" then return nil end
    for index = 1, #path do
        if type(current) ~= "table" then return nil end
        current = current[path[index]]
    end
    return current
end

local function pathSet(root, path, value)
    local current = root
    local index
    if type(path) ~= "table" or #path == 0 then return false end
    for index = 1, #path - 1 do
        if type(current[path[index]]) ~= "table" then
            current[path[index]] = {}
        end
        current = current[path[index]]
    end
    current[path[#path]] = value
    return true
end

local function pathClear(root, path)
    local current = root
    local index
    if type(path) ~= "table" or #path == 0 then return false end
    for index = 1, #path - 1 do
        if type(current) ~= "table" then return false end
        current = current[path[index]]
    end
    if type(current) ~= "table" then return false end
    current[path[#path]] = nil
    return true
end

local function normalizeAppearance(value)
    local appearance = PNC.Identity and PNC.Identity.Appearance
    if appearance and appearance.Normalize then
        return appearance.Normalize(value)
    end
    return normalizeCollection(value, { maxDepth = 8, maxEntries = 128 })
end

local function normalizeSkillLevels(value)
    if PNC.Types and PNC.Types.NormalizeSkillLevels then
        return PNC.Types.NormalizeSkillLevels(value)
    end
    if type(value) ~= "table" then return nil, "skill_map_required" end
    local output = {}
    for key, level in pairs(value) do
        local number = tonumber(level)
        if not number or number < 0 or number > 10
            or number ~= math.floor(number)
        then
            return nil, "invalid_skill_level:" .. tostring(key)
        end
        output[tostring(key)] = number
    end
    return output
end

local function normalizeTraits(value, kind)
    if kind == "physiological"
        and PNC.PlayerNeedsModel
        and PNC.PlayerNeedsModel.NormalizeTraits
    then
        return PNC.PlayerNeedsModel.NormalizeTraits(value)
    end
    if kind == "dynamic"
        and PNC.ConditionStats
        and PNC.ConditionStats.NormalizeTraits
    then
        return PNC.ConditionStats.NormalizeTraits(value)
    end
    if kind == "npc"
        and PNC.NPCTraits
        and PNC.NPCTraits.NormalizeSet
    then
        return PNC.NPCTraits.NormalizeSet(value)
    end
    return normalizeMap(value)
end

local function descriptor(id, wireCode, valueType, options)
    options = options or {}
    options.id = id
    options.wireCode = wireCode
    options.valueType = valueType
    options.introducedVersion = options.introducedVersion or 1
    options.authorable = options.authorable == true
    options.persistable = options.persistable == true
    options.networkable = options.networkable == true
    options.bindingAllowed = options.bindingAllowed == true
    options.clearable = options.clearable == true
    return options
end

local DESCRIPTORS = {
    descriptor("identity.displayName", 1, "string", {
        runtimePath = { "identity", "displayName" },
        draftPath = { "displayName" },
        authorable = true, persistable = true, networkable = true,
        bindingAllowed = true, clearable = false,
        limits = { maxLength = 128 },
        read = function(definition)
            return definition.identity and definition.identity.displayName
                or definition.displayName
        end,
        write = function(definition, value)
            definition.identity = definition.identity or {}
            definition.identity.displayName = value
            definition.displayName = value
            return true
        end,
        clearRuntime = function(definition)
            if definition.identity then definition.identity.displayName = nil end
            definition.displayName = nil
            return true
        end,
    }),
    descriptor("identity.forename", 2, "string", {
        runtimePath = { "identity", "survivor", "forename" },
        draftPath = { "identity", "survivor", "forename" },
        authorable = true, persistable = true, networkable = true,
        bindingAllowed = true, clearable = false,
        limits = { maxLength = 64 },
    }),
    descriptor("identity.surname", 3, "string", {
        runtimePath = { "identity", "survivor", "surname" },
        draftPath = { "identity", "survivor", "surname" },
        authorable = true, persistable = true, networkable = true,
        bindingAllowed = true, clearable = false,
        limits = { maxLength = 64 },
    }),
    descriptor("identity.nickname", 4, "string", {
        runtimePath = { "identity", "nickname" },
        draftPath = { "identity", "nickname" },
        authorable = true, persistable = true, networkable = true,
        bindingAllowed = true, clearable = true,
        limits = { maxLength = 64 },
    }),
    descriptor("identity.isFemale", 5, "boolean", {
        runtimePath = { "identity", "isFemale" },
        draftPath = { "isFemale" },
        authorable = true, persistable = true, networkable = true,
        bindingAllowed = true, clearable = false,
        read = function(definition)
            local value = definition.identity and definition.identity.isFemale
            if value == nil then value = definition.isFemale end
            return value
        end,
        write = function(definition, value)
            definition.identity = definition.identity or {}
            definition.identity.isFemale = value == true
            definition.isFemale = value == true
            return true
        end,
        clearRuntime = function(definition)
            if definition.identity then definition.identity.isFemale = nil end
            definition.isFemale = nil
            return true
        end,
    }),
    descriptor("appearance.hairModel", 6, "string", {
        runtimePath = { "identity", "survivor", "hairModel" },
        draftPath = { "identity", "survivor", "hairModel" },
        authoredPath = { "appearanceAuthored", "hairModel" },
        authorable = true, persistable = true, networkable = true,
        bindingAllowed = true, clearable = true,
        limits = { maxLength = 64 },
    }),
    descriptor("appearance.beardModel", 7, "string", {
        runtimePath = { "identity", "survivor", "beardModel" },
        draftPath = { "identity", "survivor", "beardModel" },
        authoredPath = { "appearanceAuthored", "beardModel" },
        authorable = true, persistable = true, networkable = true,
        bindingAllowed = true, clearable = true,
        limits = { maxLength = 64 },
    }),
    descriptor("appearance.skinTexture", 8, "string", {
        runtimePath = { "identity", "survivor", "skinTexture" },
        draftPath = { "identity", "survivor", "skinTexture" },
        authoredPath = { "appearanceAuthored", "skinTexture" },
        authorable = true, persistable = true, networkable = true,
        bindingAllowed = true, clearable = true,
        limits = { maxLength = 64 },
    }),
    descriptor("appearance.skinColor", 9, "color", {
        runtimePath = { "identity", "survivor", "skinColor" },
        draftPath = { "identity", "survivor", "skinColor" },
        authoredPath = { "appearanceAuthored", "skinColor" },
        authorable = true, persistable = true, networkable = true,
        bindingAllowed = true, clearable = true,
    }),
    descriptor("appearance.hairColor", 10, "color", {
        runtimePath = { "identity", "survivor", "hairColor" },
        draftPath = { "identity", "survivor", "hairColor" },
        authoredPath = { "appearanceAuthored", "hairColor" },
        authorable = true, persistable = true, networkable = true,
        bindingAllowed = true, clearable = true,
    }),
    descriptor("appearance.voice", 11, "string", {
        runtimePath = { "identity", "survivor", "voice" },
        draftPath = { "identity", "survivor", "voice" },
        authoredPath = { "appearanceAuthored", "voice" },
        authorable = true, persistable = true, networkable = true,
        bindingAllowed = true, clearable = true,
        limits = { maxLength = 64 },
    }),
    descriptor("appearance.voicePrefix", 12, "string", {
        runtimePath = { "identity", "survivor", "voicePrefix" },
        draftPath = { "identity", "survivor", "voicePrefix" },
        authoredPath = { "appearanceAuthored", "voicePrefix" },
        authorable = true, persistable = true, networkable = true,
        bindingAllowed = true, clearable = true,
        limits = { maxLength = 64 },
    }),
    descriptor("appearance.voiceType", 13, "number", {
        runtimePath = { "identity", "survivor", "voiceType" },
        draftPath = { "identity", "survivor", "voiceType" },
        authoredPath = { "appearanceAuthored", "voiceType" },
        authorable = true, persistable = true, networkable = true,
        bindingAllowed = true, clearable = true,
        limits = { min = 0, max = 32, integer = true },
    }),
    descriptor("appearance.voicePitch", 14, "number", {
        runtimePath = { "identity", "survivor", "voicePitch" },
        draftPath = { "identity", "survivor", "voicePitch" },
        authoredPath = { "appearanceAuthored", "voicePitch" },
        authorable = true, persistable = true, networkable = true,
        bindingAllowed = true, clearable = true,
        limits = { min = -100, max = 100 },
    }),
    descriptor("appearance", 20, "object", {
        runtimePath = { "appearance" },
        draftPath = { "appearance" },
        authoredPath = { "appearanceAuthored", "appearance" },
        authorable = true, persistable = true, networkable = true,
        bindingAllowed = true, clearable = true,
        normalize = normalizeAppearance,
    }),
    descriptor("archetypeID", 21, "string", {
        runtimePath = { "archetypeID" }, draftPath = { "archetypeID" },
        authorable = true, persistable = true, networkable = true,
        bindingAllowed = false, clearable = false,
        limits = { maxLength = 64 },
    }),
    descriptor("archetypeLabel", 22, "string", {
        runtimePath = { "archetypeLabel" }, draftPath = { "archetypeLabel" },
        authorable = true, persistable = true, networkable = false,
        bindingAllowed = false, clearable = true,
        limits = { maxLength = 128 },
    }),
    descriptor("tacticalClass", 23, "string", {
        runtimePath = { "tacticalClass" }, draftPath = { "tacticalClass" },
        authorable = true, persistable = true, networkable = true,
        bindingAllowed = false, clearable = false,
        limits = { maxLength = 32 },
    }),
    descriptor("weaponMode", 24, "string", {
        runtimePath = { "weaponMode" }, draftPath = { "weaponMode" },
        authorable = true, persistable = true, networkable = true,
        bindingAllowed = false, clearable = true,
        limits = { maxLength = 32 },
    }),
    descriptor("attackType", 25, "string", {
        runtimePath = { "attackType" }, draftPath = { "attackType" },
        authorable = true, persistable = true, networkable = true,
        bindingAllowed = false, clearable = true,
        limits = { maxLength = 32 },
    }),
    descriptor("equipmentSpawnMode", 26, "string", {
        runtimePath = { "equipmentSpawnMode" }, draftPath = { "equipmentSpawnMode" },
        authorable = true, persistable = true, networkable = true,
        bindingAllowed = false, clearable = true,
        limits = { maxLength = 32 },
    }),
    descriptor("equipmentPoolID", 27, "string", {
        runtimePath = { "equipmentPoolID" }, draftPath = { "equipmentPoolID" },
        authorable = true, persistable = true, networkable = true,
        bindingAllowed = false, clearable = true,
        limits = { maxLength = 64 },
    }),
    descriptor("chanceWeight", 28, "number", {
        runtimePath = { "chanceWeight" }, draftPath = { "chanceWeight" },
        authorable = true, persistable = true, networkable = false,
        bindingAllowed = false, clearable = true,
        limits = { min = 0, max = 100000 },
    }),
    descriptor("spawnChance", 29, "number", {
        runtimePath = { "spawnChance" }, draftPath = { "spawnChance" },
        authorable = true, persistable = true, networkable = false,
        bindingAllowed = false, clearable = true,
        limits = { min = 0, max = 1 },
    }),
    descriptor("hpMax", 30, "number", {
        runtimePath = { "hpMax" }, draftPath = { "hpMax" },
        authorable = true, persistable = true, networkable = false,
        bindingAllowed = false, clearable = true,
        limits = { min = 1, max = 10000, integer = true },
    }),
    descriptor("combatProfile", 31, "object", {
        runtimePath = { "combatProfile" }, draftPath = { "combatProfile" },
        authorable = true, persistable = true, networkable = false,
        bindingAllowed = false, clearable = true,
        normalize = function(value)
            return normalizeCollection(value, { maxDepth = 6, maxEntries = 64 })
        end,
    }),
    descriptor("equipment", 32, "object", {
        runtimePath = { "equipment" }, draftPath = { "equipment" },
        authorable = true, persistable = true, networkable = false,
        bindingAllowed = false, clearable = true,
        normalize = function(value)
            return normalizeCollection(value, { maxDepth = 8, maxEntries = 128 })
        end,
    }),
    descriptor("startingItems", 33, "list", {
        runtimePath = { "startingItems" }, draftPath = { "startingItems" },
        authorable = true, persistable = true, networkable = true,
        bindingAllowed = false, clearable = true,
        normalize = function(value)
            return normalizeCollection(value, { maxDepth = 8, maxEntries = 128 })
        end,
    }),
    descriptor("skills.baseLevels", 34, "map", {
        runtimePath = { "skillLevels" }, draftPath = { "skillLevels" },
        authorable = true, persistable = true, networkable = true,
        bindingAllowed = false, clearable = true,
        normalize = normalizeSkillLevels,
    }),
    descriptor("traits.physiological", 35, "map", {
        runtimePath = { "vanillaTraits" }, draftPath = { "vanillaTraits" },
        authorable = true, persistable = true, networkable = true,
        bindingAllowed = false, clearable = true,
        normalize = function(value) return normalizeTraits(value, "physiological") end,
    }),
    descriptor("traits.dynamic", 36, "map", {
        runtimePath = { "dynamicTraits" }, draftPath = { "dynamicTraits" },
        authorable = true, persistable = true, networkable = true,
        bindingAllowed = false, clearable = true,
        normalize = function(value) return normalizeTraits(value, "dynamic") end,
    }),
    descriptor("traits.npc", 37, "map", {
        runtimePath = { "npcTraits" }, draftPath = { "npcTraits" },
        authorable = true, persistable = true, networkable = true,
        bindingAllowed = false, clearable = true,
        normalize = function(value) return normalizeTraits(value, "npc") end,
    }),
    descriptor("inventory.startingTemplate", 38, "string", {
        runtimePath = { "inventoryTemplateRef" },
        draftPath = { "inventoryTemplateRef" },
        authorable = true, persistable = true, networkable = true,
        bindingAllowed = false, clearable = true,
        limits = { maxLength = 128 },
    }),
    descriptor("allowedJobs", 39, "list", {
        runtimePath = { "allowedJobs" }, draftPath = { "allowedJobs" },
        authorable = true, persistable = true, networkable = false,
        bindingAllowed = false, clearable = true,
        normalize = function(value)
            return normalizeCollection(value, { maxDepth = 4, maxEntries = 64 })
        end,
    }),
    descriptor("jobPriorities", 40, "map", {
        runtimePath = { "jobPriorities" }, draftPath = { "jobPriorities" },
        authorable = true, persistable = true, networkable = false,
        bindingAllowed = false, clearable = true,
        normalize = function(value)
            return normalizeCollection(value, { maxDepth = 4, maxEntries = 64 })
        end,
    }),
    descriptor("social", 41, "object", {
        runtimePath = { "social" }, draftPath = { "social" },
        authorable = true, persistable = true, networkable = false,
        bindingAllowed = false, clearable = true,
        normalize = function(value)
            return normalizeCollection(value, { maxDepth = 5, maxEntries = 64 })
        end,
    }),
    descriptor("hostility", 42, "object", {
        runtimePath = { "hostility" }, draftPath = { "hostility" },
        authorable = true, persistable = true, networkable = false,
        bindingAllowed = false, clearable = true,
        normalize = function(value)
            return normalizeCollection(value, { maxDepth = 5, maxEntries = 64 })
        end,
    }),
    descriptor("orderSpec", 43, "object", {
        runtimePath = { "orderSpec" }, draftPath = { "orderSpec" },
        authorable = true, persistable = true, networkable = false,
        bindingAllowed = false, clearable = true,
        normalize = function(value)
            return normalizeCollection(value, { maxDepth = 5, maxEntries = 64 })
        end,
    }),
    descriptor("patrolPoints", 44, "list", {
        runtimePath = { "patrolPoints" }, draftPath = { "patrolPoints" },
        authorable = true, persistable = true, networkable = false,
        bindingAllowed = false, clearable = true,
        normalize = function(value)
            return normalizeCollection(value, { maxDepth = 5, maxEntries = 128 })
        end,
    }),
    descriptor("mapPresentation", 45, "object", {
        runtimePath = { "mapPresentation" }, draftPath = { "mapPresentation" },
        authorable = true, persistable = true, networkable = false,
        bindingAllowed = false, clearable = true,
        normalize = function(value)
            return normalizeCollection(value, { maxDepth = 5, maxEntries = 64 })
        end,
    }),
    descriptor("recipeKnowledge", 46, "object", {
        runtimePath = { "recipeKnowledge" }, draftPath = { "recipeKnowledge" },
        authorable = true, persistable = true, networkable = false,
        bindingAllowed = false, clearable = true,
        normalize = function(value)
            return normalizeCollection(value, { maxDepth = 6, maxEntries = 128 })
        end,
    }),
    descriptor("appearance.hairStubble", 47, "boolean", {
        runtimePath = { "identity", "survivor", "hairStubble" },
        draftPath = { "identity", "survivor", "hairStubble" },
        authoredPath = { "appearanceAuthored", "hairStubble" },
        authorable = true, persistable = true, networkable = true,
        bindingAllowed = true, clearable = true,
    }),
    descriptor("appearance.beardStubble", 48, "boolean", {
        runtimePath = { "identity", "survivor", "beardStubble" },
        draftPath = { "identity", "survivor", "beardStubble" },
        authoredPath = { "appearanceAuthored", "beardStubble" },
        authorable = true, persistable = true, networkable = true,
        bindingAllowed = true, clearable = true,
    }),
    descriptor("appearance.chestHair", 49, "boolean", {
        runtimePath = { "identity", "survivor", "chestHair" },
        draftPath = { "identity", "survivor", "chestHair" },
        authoredPath = { "appearanceAuthored", "chestHair" },
        authorable = true, persistable = true, networkable = true,
        bindingAllowed = true, clearable = true,
    }),
    descriptor("factionID", nil, "string", {
        runtimePath = { "factionID" }, draftPath = { "factionID" },
        authorable = true, persistable = true, networkable = false,
        bindingAllowed = false, clearable = true,
        limits = { maxLength = 128 },
    }),
}

local function descriptorList()
    local output = {}
    for _, value in pairs(Registry._fields) do output[#output + 1] = value end
    table.sort(output, function(left, right) return left.id < right.id end)
    return output
end

local function stableKey(value)
    if type(value) == "number" then return "n:" .. tostring(value) end
    if type(value) == "boolean" then return value and "b:1" or "b:0" end
    return "s:" .. tostring(value)
end

local function stableEncode(value, depth)
    local parts = {}
    local keys = {}
    local index
    depth = depth or 0
    if depth > 12 then return "<depth>" end
    if value == nil then return "nil;" end
    if type(value) == "string" then
        return "s" .. #value .. ":" .. value .. ";"
    end
    if type(value) == "number" then
        return "n:" .. string.format("%.17g", value) .. ";"
    end
    if type(value) == "boolean" then
        return value and "b:1;" or "b:0;"
    end
    if type(value) ~= "table" then return "x:" .. tostring(value) .. ";" end
    for key in pairs(value) do keys[#keys + 1] = key end
    table.sort(keys, function(left, right)
        return stableKey(left) < stableKey(right)
    end)
    for index = 1, #keys do
        local key = keys[index]
        parts[#parts + 1] = stableEncode(key, depth + 1)
        parts[#parts + 1] = stableEncode(value[key], depth + 1)
    end
    return "t" .. #keys .. "{" .. table.concat(parts) .. "}"
end

local function hash(text)
    local value = 5381
    local index
    for index = 1, #text do
        value = (value * 33 + string.byte(text, index)) % 2147483647
    end
    return string.format("%010d", value)
end

function Registry.Copy(value)
    return copy(value)
end

function Registry.Get(id)
    return id and Registry._fields[tostring(id)] or nil
end

function Registry.List()
    return descriptorList()
end

function Registry.Register(value)
    local id = value and tostring(value.id or "") or ""
    local wireCode = value and value.wireCode or nil
    local existing
    local entry
    if id == "" or string.match(id, "^[%w_%.:%-]+$") == nil then
        return false, "field_id_invalid"
    end
    if Registry._fields[id] then return false, "field_id_already_registered" end
    if value.networkable and not wireCode then
        return false, "network_field_wire_code_required"
    end
    if wireCode then
        wireCode = tonumber(wireCode)
        if not wireCode or wireCode < 1 or wireCode ~= math.floor(wireCode) then
            return false, "wire_code_invalid"
        end
        if Registry._retiredWireCodes[wireCode] then
            return false, "wire_code_retired"
        end
        for _, existing in pairs(Registry._fields) do
            if existing.wireCode == wireCode then
                return false, "wire_code_already_registered"
            end
        end
    end
    entry = {}
    for key, item in pairs(value) do entry[key] = item end
    entry.id = id
    entry.wireCode = wireCode
    entry.introducedVersion = tonumber(entry.introducedVersion) or 1
    entry.authorable = entry.authorable == true
    entry.persistable = entry.persistable == true
    entry.networkable = entry.networkable == true
    entry.bindingAllowed = entry.bindingAllowed == true
    entry.clearable = entry.clearable == true
    Registry._fields[id] = entry
    Registry._fingerprint = nil
    return true, id
end

function Registry.RetireWireCode(code)
    local numeric = tonumber(code)
    local field
    if not numeric or numeric < 1 or numeric ~= math.floor(numeric) then
        return false, "wire_code_invalid"
    end
    for _, existing in pairs(Registry._fields) do
        if existing.wireCode == numeric then
            field = existing
            break
        end
    end
    if field then return false, "wire_code_active" end
    Registry._retiredWireCodes[numeric] = true
    Registry._fingerprint = nil
    return true, numeric
end

function Registry.NormalizeValue(fieldID, value)
    local field = Registry.Get(fieldID)
    local output
    local reason
    if not field then return nil, "unknown_field:" .. tostring(fieldID) end
    if field.valueType == "string" then
        output, reason = normalizeString(value, field.limits)
    elseif field.valueType == "boolean" then
        output, reason = normalizeBoolean(value)
    elseif field.valueType == "number" then
        output, reason = normalizeNumber(value, field.limits)
    elseif field.valueType == "color" then
        output, reason = normalizeColor(value)
    elseif field.normalize then
        output, reason = field.normalize(value)
    elseif field.valueType == "map" then
        output, reason = normalizeCollection(value, { maxDepth = 6, maxEntries = 128 })
    elseif field.valueType == "list" or field.valueType == "object" then
        output, reason = normalizeCollection(value, { maxDepth = 8, maxEntries = 128 })
    else
        output = copy(value)
    end
    if output == nil and value ~= nil then
        return nil, reason or "field_value_invalid"
    end
    return copy(output)
end

function Registry.Read(definition, fieldID)
    local field = Registry.Get(fieldID)
    local value
    if not field or type(definition) ~= "table" then return nil end
    if field.read then value = field.read(definition) else
        value = pathGet(definition, field.runtimePath)
    end
    return copy(value)
end

function Registry.Write(definition, fieldID, value)
    local field = Registry.Get(fieldID)
    if not field or type(definition) ~= "table" then return false end
    if field.write then return field.write(definition, copy(value)) end
    return pathSet(definition, field.runtimePath, copy(value))
end

function Registry.ClearRuntime(definition, fieldID)
    local field = Registry.Get(fieldID)
    if not field or type(definition) ~= "table" then return false end
    if field.clearRuntime then return field.clearRuntime(definition) end
    return pathClear(definition, field.runtimePath)
end

function Registry.ReadDraft(draft, fieldID)
    local field = Registry.Get(fieldID)
    if not field or type(draft) ~= "table" then return nil end
    if field.readDraft then return copy(field.readDraft(draft)) end
    return copy(pathGet(draft, field.draftPath))
end

function Registry.IsDraftAuthored(draft, fieldID)
    local field = Registry.Get(fieldID)
    local marker
    if not field or type(draft) ~= "table" then return false end
    marker = field.authoredPath and pathGet(draft, field.authoredPath) or nil
    if marker ~= nil then return marker == true end
    return Registry.ReadDraft(draft, fieldID) ~= nil
end

function Registry.Hash(value)
    return hash(stableEncode(value))
end

function Registry.Fingerprint()
    local fields = {}
    local list = descriptorList()
    for _, field in ipairs(list) do
        if field.networkable then
            fields[#fields + 1] = {
                id = field.id,
                wireCode = field.wireCode,
                valueType = field.valueType,
                introducedVersion = field.introducedVersion,
                deprecatedVersion = field.deprecatedVersion,
                authorable = field.authorable,
                persistable = field.persistable,
                bindingAllowed = field.bindingAllowed,
                clearable = field.clearable,
            }
        end
    end
    if not Registry._fingerprint then
        Registry._fingerprint = "registry:v" .. tostring(Registry.PROTOCOL_VERSION)
            .. ":" .. hash(stableEncode(fields))
    end
    return Registry._fingerprint
end

function Registry.Validate()
    local count = 0
    local seenCodes = {}
    local field
    for _, field in ipairs(descriptorList()) do
        count = count + 1
        if count > Registry.MAX_FIELDS then return false, "field_registry_too_large" end
        if type(field.id) ~= "string" or field.id == "" then
            return false, "field_id_missing"
        end
        if field.networkable then
            if not field.wireCode then return false, "network_field_wire_code_missing:" .. field.id end
            if Registry._retiredWireCodes[field.wireCode] then
                return false, "wire_code_retired:" .. tostring(field.wireCode)
            end
            if seenCodes[field.wireCode] then
                return false, "wire_code_duplicate:" .. tostring(field.wireCode)
            end
            seenCodes[field.wireCode] = field.id
        end
    end
    return true, count
end

function Registry.Serialize(blueprint)
    local Blueprint = PNC.NPCAuthoringBlueprint
    if not Blueprint then return nil, "blueprint_unavailable" end
    return Blueprint.Serialize(blueprint)
end

function Registry.Deserialize(payload)
    local Blueprint = PNC.NPCAuthoringBlueprint
    if not Blueprint then return nil, "blueprint_unavailable" end
    return Blueprint.Deserialize(payload)
end

local function fieldByWireCode(code)
    local numeric = tonumber(code)
    local field
    if not numeric then return nil end
    for _, field in pairs(Registry._fields) do
        if field.wireCode == numeric then return field end
    end
    return nil
end

function Registry.EncodeCompact(blueprint)
    local normalized
    local reason
    local values = {}
    local clears = {}
    local field
    local id
    local count = 0
    local clearCount = 0
    if not PNC.NPCAuthoringBlueprint then
        return nil, "blueprint_unavailable"
    end
    normalized, reason = PNC.NPCAuthoringBlueprint.Normalize(blueprint)
    if not normalized then return nil, reason end
    for id, value in pairs(normalized.fields) do
        count = count + 1
        if count > Registry.MAX_FIELDS then return nil, "too_many_compact_fields" end
        field = Registry.Get(id)
        if not field or not field.networkable then
            return nil, "field_not_networkable:" .. tostring(id)
        end
        values[field.wireCode] = copy(value)
    end
    for id, value in pairs(normalized.clears) do
        if value then
            clearCount = clearCount + 1
            if clearCount > Registry.MAX_CLEAR_FIELDS then
                return nil, "too_many_compact_clears"
            end
            field = Registry.Get(id)
            if not field or not field.networkable then
                return nil, "clear_not_networkable:" .. tostring(id)
            end
            clears[field.wireCode] = true
        end
    end
    return {
        protocolVersion = Registry.PROTOCOL_VERSION,
        registryFingerprint = Registry.Fingerprint(),
        schemaId = Registry.SCHEMA_ID,
        schemaVersion = Registry.SCHEMA_VERSION,
        generationSeed = normalized.generationSeed,
        values = values,
        clears = clears,
    }
end

function Registry.DecodeCompact(envelope)
    local Blueprint = PNC.NPCAuthoringBlueprint
    local raw
    local field
    local code
    local value
    local normalized
    local reason
    local count = 0
    local clearCount = 0
    if not Blueprint then return nil, "blueprint_unavailable" end
    if type(envelope) ~= "table" then return nil, "compact_envelope_invalid" end
    if tonumber(envelope.protocolVersion) ~= Registry.PROTOCOL_VERSION then
        return nil, "protocol_version_mismatch"
    end
    if tostring(envelope.registryFingerprint or "") ~= Registry.Fingerprint() then
        return nil, "registry_fingerprint_mismatch"
    end
    if tostring(envelope.schemaId or "") ~= Registry.SCHEMA_ID
        or tonumber(envelope.schemaVersion) ~= Registry.SCHEMA_VERSION
    then
        return nil, "schema_version_mismatch"
    end
    if type(envelope.values) ~= "table" or type(envelope.clears) ~= "table" then
        return nil, "compact_fields_invalid"
    end
    raw = Blueprint.New({ generationSeed = envelope.generationSeed })
    for code, value in pairs(envelope.values) do
        count = count + 1
        if count > Registry.MAX_FIELDS then return nil, "too_many_compact_fields" end
        field = fieldByWireCode(code)
        if not field or not field.networkable then
            return nil, "wire_code_unknown"
        end
        normalized, reason = Blueprint.Set(raw, field.id, value)
        if not normalized then return nil, reason end
        raw = normalized
    end
    for code, value in pairs(envelope.clears) do
        if value then
            clearCount = clearCount + 1
            if clearCount > Registry.MAX_CLEAR_FIELDS then
                return nil, "too_many_compact_clears"
            end
            if envelope.values[code] ~= nil then
                return nil, "compact_value_clear_conflict"
            end
            field = fieldByWireCode(code)
            if not field or not field.networkable then
                return nil, "clear_wire_code_unknown"
            end
            raw, reason = Blueprint.Clear(raw, field.id)
            if not raw then return nil, reason end
        end
    end
    return Blueprint.Normalize(raw)
end

for _, field in ipairs(DESCRIPTORS) do
    Registry._fields[field.id] = field
end

return Registry
