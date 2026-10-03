-- Validation and authored trait controls for the editor draft.
PNC = PNC or {}
PNC.UniqueNPCEditorModel = PNC.UniqueNPCEditorModel or {}

local Model = PNC.UniqueNPCEditorModel
local Internal = Model.Internal or {}
local Unique = PNC.UniqueNPCs
local Identity = PNC.Identity
local Appearance = Identity and Identity.Appearance
local text = Internal.text


local function knownSkill(skillID)
    local catalog = PNC.SkillCatalog
    if not catalog or not catalog.Find then return true end
    return catalog.Find(skillID) ~= nil
end

local function validateSkills(draft)
    for skillID, level in pairs(draft.skillLevels or {}) do
        if not knownSkill(skillID) then
            return false, "unknown_skill:" .. tostring(skillID)
        end
        level = tonumber(level)
        if not level or level < 0 or level > 10
            or level ~= math.floor(level)
        then
            return false, "invalid_skill_level:" .. tostring(skillID)
        end
    end
    return true
end

local function npcTraitRegistry()
    return PNC.NPCTraits
end

local function validateNPCTraitSet(source, label)
    local registry = npcTraitRegistry()
    if not registry or not registry.NormalizeID then return true end
    for rawID, selected in pairs(source or {}) do
        if selected then
            local candidate = type(rawID) == "number" and selected or rawID
            if not registry.NormalizeID(candidate) then
                return false, "unknown_" .. label .. ":" .. tostring(candidate)
            end
        end
    end
    if registry.ResolveSet then
        local _, conflicts = registry.ResolveSet(source)
        if conflicts and #conflicts > 0 then
            return false, "conflicting_" .. label
        end
    end
    return true
end

local function findVanillaTrait(id)
    if not CharacterTraitDefinition
        or not CharacterTraitDefinition.getTraits
    then
        return nil
    end
    local list = CharacterTraitDefinition.getTraits()
    if not list then return nil end
    for index = 0, list:size() - 1 do
        local trait = list:get(index)
        if trait and trait.getType then
            local traitType = trait:getType()
            if traitType and traitType.getName
                and tostring(traitType:getName()) == tostring(id)
            then
                return trait
            end
        end
    end
    return nil
end

local function vanillaTraitConflict(left, right)
    local leftDefinition = findVanillaTrait(left)
    local rightDefinition = findVanillaTrait(right)
    local leftType
    local rightType
    local excluded
    if not leftDefinition or not rightDefinition then return false end
    if leftDefinition.getType then
        leftType = leftDefinition:getType()
    end
    if rightDefinition.getType then
        rightType = rightDefinition:getType()
    end
    if leftDefinition.getMutuallyExclusiveTraits and rightType then
        excluded = leftDefinition:getMutuallyExclusiveTraits()
        if excluded and excluded.contains and excluded:contains(rightType) then
            return true
        end
    end
    if rightDefinition.getMutuallyExclusiveTraits and leftType then
        excluded = rightDefinition:getMutuallyExclusiveTraits()
        if excluded and excluded.contains and excluded:contains(leftType) then
            return true
        end
    end
    return false
end

local function validateVanillaTraits(source)
    local selected = {}
    for rawID, enabled in pairs(source or {}) do
        if enabled then
            local candidate = type(rawID) == "number" and enabled or rawID
            if not findVanillaTrait(candidate) then
                -- The base-game catalog is unavailable in headless tests and
                -- older worlds.  In that case retain the authored ID and let
                -- the normal runtime validator decide its compatibility.
                if CharacterTraitDefinition then
                    return false, "unknown_vanilla_trait:" .. tostring(candidate)
                end
            end
            for existing, _ in pairs(selected) do
                if vanillaTraitConflict(existing, candidate) then
                    return false, "conflicting_vanilla_traits"
                end
            end
            selected[tostring(candidate)] = true
        end
    end
    return true
end

local function combinedNPCTraits(draft)
    local output = {}
    for id, selected in pairs(draft.npcTraits or {}) do
        if selected then
            output[type(id) == "number" and selected or id] = true
        end
    end
    for id, selected in pairs(draft.dynamicTraits or {}) do
        if selected then
            output[type(id) == "number" and selected or id] = true
        end
    end
    return output
end

function Model.TryAddSkill(draft, skillID, level)
    local id = text(skillID)
    local numeric = tonumber(level)
    if not id or not knownSkill(id) then return false, "unknown_skill" end
    if not numeric or numeric < 0 or numeric > 10
        or numeric ~= math.floor(numeric)
    then
        return false, "invalid_skill_level"
    end
    draft.skillLevels = type(draft.skillLevels) == "table"
        and draft.skillLevels or {}
    if draft.skillLevels[id] ~= nil then return false, "skill_duplicate" end
    draft.skillLevels[id] = numeric
    draft.authoredFields = draft.authoredFields or {}
    draft.authoredFields.skillLevels = true
    draft._dirty = true
    return true, "skill_added", id
end

function Model.TryAddTrait(draft, kind, traitID)
    local id = text(traitID)
    local field = kind == "vanilla" and "vanillaTraits"
        or kind == "dynamic" and "dynamicTraits" or "npcTraits"
    local traits
    local combined
    local registry
    local _, conflicts
    if not id then return false, "trait_required" end
    registry = npcTraitRegistry()
    if kind ~= "vanilla" and registry and registry.NormalizeID then
        id = registry.NormalizeID(id)
        if not id then return false, "unknown_trait" end
    end
    traits = {}
    for rawID, selected in pairs(draft[field] or {}) do
        if selected then
            local candidate = type(rawID) == "number" and selected or rawID
            if kind ~= "vanilla" and registry and registry.NormalizeID then
                candidate = registry.NormalizeID(candidate) or candidate
            end
            traits[tostring(candidate)] = true
        end
    end
    if traits[id] then return false, "trait_duplicate" end
    if kind == "vanilla" then
        if not validateVanillaTraits({ [id] = true }) then
            return false, "unknown_vanilla_trait"
        end
        for existing, selected in pairs(draft.vanillaTraits or {}) do
            if selected and vanillaTraitConflict(existing, id) then
                return false, "trait_conflict"
            end
        end
    else
        combined = combinedNPCTraits(draft)
        combined[id] = true
        if registry and registry.NormalizeID
            and not registry.NormalizeID(id)
        then
            return false, "unknown_trait"
        end
        if registry and registry.ResolveSet then
            _, conflicts = registry.ResolveSet(combined)
            if conflicts and #conflicts > 0 then
                return false, "trait_conflict"
            end
        end
    end
    traits[id] = true
    draft[field] = traits
    draft.authoredFields = draft.authoredFields or {}
    draft.authoredFields[field] = true
    draft._dirty = true
    return true, "trait_added", id
end

function Model.Validate(draft)
    local forename
    local surname
    if not draft then return false, "name_required" end
    forename, surname = Model.NameParts(draft)
    if not text(forename) or not text(surname) then
        return false, "first_and_surname_required"
    end
    if type(draft.isFemale) ~= "boolean" then return false, "gender_required" end
    local valid, reason = validateSkills(draft)
    if not valid then return false, reason end
    valid, reason = validateNPCTraitSet(combinedNPCTraits(draft), "traits")
    if not valid then return false, reason end
    valid, reason = validateVanillaTraits(draft.vanillaTraits)
    if not valid then return false, reason end
    if Appearance and Appearance.Validate then
        valid, reason = Appearance.Validate(draft.appearance)
        if not valid then return false, reason end
    end
    local normalized, reason = Unique.NormalizeDefinition(Model.BuildDefinition(draft))
    if not normalized then return false, reason end
    return true, normalized
end

require "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorModel_Runtime"

return Model
