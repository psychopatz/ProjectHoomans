-- Declarative metadata for detailed relationship kinds used by dialogue.
--
-- This registry is deliberately not a persistence owner. Starting Companion
-- records continue to store their detailed relationshipKind; dialogue derives
-- a transient bond class and localized term keys from this metadata.
PNC = PNC or {}
PNC.RelationshipKinds = PNC.RelationshipKinds or {}

local Registry = PNC.RelationshipKinds

Registry.VERSION = 1
Registry.SCHEMA = "pnc.relationship.kind.v1"
Registry.MAX_DEFINITIONS = 64

local VALID_CLASSES = {
    friend = true,
    family = true,
    lover = true,
}

local definitions = Registry._definitions or {}
Registry._definitions = definitions

local function normalized(value)
    value = tostring(value or "")
    value = string.lower(value)
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    return value
end

local function copyDefinition(definition)
    if type(definition) ~= "table" then return nil end
    local terms = type(definition.termKeys) == "table"
        and definition.termKeys or {}
    return {
        kind = definition.kind,
        class = definition.class,
        termKeys = {
            reference = terms.reference,
            address = terms.address,
        },
    }
end

function Registry.Register(definition)
    if type(definition) ~= "table" then
        return false, "relationship_kind_definition_required"
    end
    local kind = normalized(definition.kind)
    local class = normalized(definition.class)
    local terms = definition.termKeys
    if kind == "" then return false, "relationship_kind_required" end
    if not VALID_CLASSES[class] then
        return false, "relationship_kind_class_invalid"
    end
    if type(terms) ~= "table"
        or normalized(terms.reference) == ""
        or normalized(terms.address) == ""
    then
        return false, "relationship_kind_terms_required"
    end
    local existing = definitions[kind]
    if existing then
        if existing.class == class
            and existing.termKeys.reference == terms.reference
            and existing.termKeys.address == terms.address
        then
            return true, "already_registered"
        end
        return false, "relationship_kind_duplicate"
    end
    local count = 0
    for _ in pairs(definitions) do count = count + 1 end
    if count >= Registry.MAX_DEFINITIONS then
        return false, "relationship_kind_limit"
    end
    definitions[kind] = {
        kind = kind,
        class = class,
        termKeys = {
            reference = tostring(terms.reference),
            address = tostring(terms.address),
        },
    }
    return true, "registered"
end

function Registry.GetDefinition(kind)
    return copyDefinition(definitions[normalized(kind)])
end

function Registry.GetDefinitions()
    local output = {}
    for kind, definition in pairs(definitions) do
        if #output < Registry.MAX_DEFINITIONS then
            output[#output + 1] = copyDefinition(definition)
        end
    end
    table.sort(output, function(left, right)
        return tostring(left.kind) < tostring(right.kind)
    end)
    return output
end

function Registry.Project(kind, source)
    local definition = Registry.GetDefinition(kind)
    if not definition then return nil end
    return {
        class = definition.class,
        kind = definition.kind,
        source = tostring(source or "starting_companion_trait"),
        term = {
            referenceKey = definition.termKeys.reference,
            addressKey = definition.termKeys.address,
        },
    }
end

local BUILTINS = {
    { kind = "friend", class = "friend" },
    { kind = "lover", class = "lover" },
    { kind = "partner", class = "lover" },
    { kind = "spouse", class = "lover" },
    { kind = "mother", class = "family" },
    { kind = "father", class = "family" },
    { kind = "sister", class = "family" },
    { kind = "brother", class = "family" },
    { kind = "cousin", class = "family" },
}

for index = 1, #BUILTINS do
    local definition = BUILTINS[index]
    Registry.Register({
        kind = definition.kind,
        class = definition.class,
        termKeys = {
            reference = "UI_PNC_Flavor_RelationshipTerm_"
                .. definition.kind:gsub("^%l", string.upper) .. "_Reference",
            address = "UI_PNC_Flavor_RelationshipTerm_"
                .. definition.kind:gsub("^%l", string.upper) .. "_Address",
        },
    })
end

return Registry
