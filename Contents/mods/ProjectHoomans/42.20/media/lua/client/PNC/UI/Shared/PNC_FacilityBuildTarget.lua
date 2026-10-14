-- Canonical identity bridge between a work station and the integrated Base
-- facility catalog.  Callers may start with a station row, a facility
-- definition, or a definition id; the returned target keeps the native
-- object identity alongside the stable Hoomans option id.

local Target = {}

local function text(value)
    local value = tostring(value or "")
    return value ~= "" and value or nil
end

local function translated(key, fallback)
    if not key then return fallback end
    local translation = PNC and PNC.Translation
    if translation and type(translation.GetKey) == "function" then
        local value = translation.GetKey(key)
        if value and value ~= key and tostring(value) ~= "" then
            return tostring(value)
        end
    end
    return fallback
end

local function humanize(value)
    local output = tostring(value or "")
    output = string.match(output, "([^%.]+)$") or output
    output = string.gsub(output, "[_%-]+", " ")
    if output == "" then return output end
    return string.upper(string.sub(output, 1, 1))
        .. string.sub(output, 2)
end

local function definitionFor(value)
    if type(value) == "table" and value.directWorkstation == true then
        return value
    end
    local definitions = PNC and PNC.FacilityDefinitions
    if not definitions or type(definitions.Get) ~= "function" then
        return nil
    end
    local candidates = {
        type(value) == "table" and value.definitionId or value,
        type(value) == "table" and value.facilityId or nil,
        type(value) == "table" and value.stationId or nil,
        type(value) == "table" and value.id or nil,
    }
    for _, candidate in ipairs(candidates) do
        local id = text(candidate)
        if id then
            local definition = definitions.Get(id)
            if definition then return definition end
        end
    end
    return nil
end

local function descriptorFor(definition)
    if not definition or definition.directWorkstation ~= true then
        return nil
    end
    local objectInfoName = definition.buildRecipeObjectInfoName
        or definition.entityScript
    local catalog = PNC and PNC.BuildRecipeCatalog
    if not catalog then return nil end
    local aliases = {
        objectInfoName,
        definition.entityScript,
        definition.stationId,
        definition.id,
        translated(definition.displayNameKey, humanize(definition.id)),
    }
    if catalog.Queries and catalog.Queries.FindForAliases then
        local descriptor = catalog.Queries.FindForAliases(aliases)
        if descriptor then return descriptor end
    end
    if catalog.Get and objectInfoName then
        local descriptor = catalog.Get(objectInfoName)
        if descriptor then return descriptor end
    end
    if catalog.Queries and catalog.Queries.FindForObjectInfo
        and objectInfoName
    then
        local descriptor = catalog.Queries.FindForObjectInfo(objectInfoName)
        if descriptor then return descriptor end
    end
    if catalog.Queries and catalog.Queries.FindNativeObjectInfo
        and objectInfoName
    then
        local info = catalog.Queries.FindNativeObjectInfo(objectInfoName)
        if info then
            return {
                objectInfoName = tostring(objectInfoName),
                displayName = translated(definition.displayNameKey,
                    humanize(definition.id)),
                category = definition.category,
                nativeObjectInfo = info,
                nativeOnly = true,
                requirements = {},
            }
        end
    end
    return nil
end

function Target.DescriptorFor(definition)
    return descriptorFor(definition)
end

function Target.Resolve(value)
    local definition = definitionFor(value)
    if not definition then return nil, "FACILITY_DEFINITION_UNAVAILABLE" end

    local facilityId = text(definition.id or definition.facilityId
        or definition.stationId)
    if not facilityId then return nil, "FACILITY_ID_UNAVAILABLE" end

    local descriptor = descriptorFor(definition)
    local objectInfoName = descriptor and descriptor.objectInfoName
        or text(definition.buildRecipeObjectInfoName or definition.entityScript)

    return {
        facilityId = facilityId,
        optionId = facilityId,
        objectInfoName = objectInfoName,
        searchText = facilityId,
        definition = definition,
        descriptor = descriptor,
    }
end

function Target.MatchesOption(option, targetOrId, objectInfoName)
    if not option then return false end
    local target = type(targetOrId) == "table" and targetOrId or nil
    local wantedId = target and (target.optionId or target.facilityId)
        or text(targetOrId)
    local wantedObject = target and target.objectInfoName
        or text(objectInfoName)
    if wantedId and tostring(option.id) == tostring(wantedId) then
        return true
    end
    if wantedObject and tostring(option.buildRecipeObjectInfoName or "")
        == tostring(wantedObject)
    then
        return true
    end
    return false
end

return Target
