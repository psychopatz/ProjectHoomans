PNC = PNC or {}
PNC.Identity = PNC.Identity or {}

local Identity = PNC.Identity

local NPC_ID_ALPHABET = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
local NPC_ID_SUFFIX_SPACE = 36 ^ 4
local NPC_ID_NAME_LIMIT = 20

local function cleanIDPart(value)
    return string.gsub(tostring(value or ""), "[^%a%d]", "")
end

local function identityNameParts(source)
    local identity = type(source) == "table" and source.identity or source
    local survivor = type(identity) == "table" and identity.survivor or nil
    local displayName = type(identity) == "table" and identity.displayName or nil
    local forename = survivor and survivor.forename or nil
    local surname = survivor and survivor.surname or nil
    if not forename and displayName then
        forename = string.match(tostring(displayName), "^(%S+)")
    end
    if not surname and displayName then
        surname = string.match(tostring(displayName), "%s+(%S+)%s*$")
    end
    return cleanIDPart(forename), cleanIDPart(surname)
end

local function encodeSuffix(value)
    local output = {}
    local index
    value = math.floor(tonumber(value) or 0) % NPC_ID_SUFFIX_SPACE
    for index = 4, 1, -1 do
        local digit = value % 36
        output[index] = string.sub(NPC_ID_ALPHABET, digit + 1, digit + 1)
        value = math.floor(value / 36)
    end
    return table.concat(output)
end

local function randomSuffix(fallback)
    local value
    if type(ZombRand) == "function" then
        value = ZombRand(NPC_ID_SUFFIX_SPACE)
    else
        value = Identity.HashText(tostring(fallback or "npc"))
    end
    return encodeSuffix(value)
end

local function registryHasID(id)
    local registry = PNC.Registry
    local directory
    if not registry then return false end
    if registry.Data and registry.Data[id] then return true end
    if registry.Loaded == true and registry.GetStorageDirectory then
        directory = registry.GetStorageDirectory()
        return directory and directory.records
            and directory.records[id] ~= nil or false
    end
    return false
end

function Identity.IsNPCIDAvailable(id)
    local value = tostring(id or "")
    if value == "" then return false end
    if Identity.ReservedNPCIDs and Identity.ReservedNPCIDs[value] then
        return false
    end
    return not registryHasID(value)
end

function Identity.GenerateNPCID(source, fallback)
    local forename
    local surname
    local slug
    local base
    local attempt
    local candidate
    local registry = PNC.Registry
    local reserved = Identity.ReservedNPCIDs
    if not reserved then
        reserved = {}
        Identity.ReservedNPCIDs = reserved
    end
    if registry and registry.Loaded == false
        and registry.EnsureLoaded and ModData
        and ModData.getOrCreate
    then
        pcall(registry.EnsureLoaded)
    end
    forename, surname = identityNameParts(source)
    slug = forename .. surname
    if slug == "" then slug = "Survivor" end
    slug = string.sub(slug, 1, NPC_ID_NAME_LIMIT)
    base = "npc" .. slug .. "_"
    for attempt = 0, NPC_ID_SUFFIX_SPACE - 1 do
        candidate = base .. randomSuffix(
            tostring(fallback or "npc") .. ":" .. tostring(attempt)
        )
        if Identity.IsNPCIDAvailable(candidate) then
            reserved[candidate] = true
            return candidate
        end
    end
    if PNC.Core and PNC.Core.LogWarn then
        PNC.Core.LogWarn("PNC NPC readable ID space exhausted for " .. base)
    end
    return tostring(fallback
        or (PNC.Core and PNC.Core.GenerateID
            and PNC.Core.GenerateID("npc")) or "npc")
end

return Identity
