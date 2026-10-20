if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.NPCKnowledge = PNC.NPCKnowledge or {}
PNC.NPCKnowledge.Internal = PNC.NPCKnowledge.Internal or {}

local Knowledge = PNC.NPCKnowledge
local Definitions = PNC.KnowledgeDescriptors

local KIND_ALIASES = {
    job = "former_job", jobs = "former_job", occupation = "former_job",
    profession = "former_job", hometown = "hometown", home_town = "hometown",
    education = "education", hobby = "hobby", hobbies = "hobby",
    family = "family_background", family_background = "family_background",
    value = "value", values = "value", fear = "fear", fears = "fear",
    tragedy = "tragedy", event = "tragedy", personal_event = "tragedy",
    survival = "survival_origin", survival_origin = "survival_origin",
    birthday = "date_of_birth", date_of_birth = "date_of_birth",
}

local function normalizeKind(value)
    if type(value) == "table" then
        value = value.kind or value.id or value.key or value.value
    end
    value = string.lower(tostring(value or ""))
    value = string.gsub(value, "[^%w]+", "_")
    value = string.gsub(value, "^_+", "")
    value = string.gsub(value, "_+$", "")
    return value ~= "" and (KIND_ALIASES[value] or value) or nil
end

local function descriptorForKind(kind)
    kind = normalizeKind(kind)
    if not kind or not Definitions or type(Definitions.List) ~= "function" then
        return nil
    end
    for _, descriptor in ipairs(Definitions.List()) do
        local presentation = descriptor.presentation or {}
        if presentation.backstoryKind == kind then return descriptor end
    end
    return nil
end

function Knowledge.BackstoryDescriptorID(kind)
    local descriptor = descriptorForKind(kind)
    return descriptor and descriptor.id or nil
end

function Knowledge.BackstoryKindForTopic(topicID)
    local topic = tostring(topicID or "")
    local prefix = "backstory."
    if string.sub(topic, 1, #prefix) ~= prefix then return nil end
    return normalizeKind(string.sub(topic, #prefix + 1))
end

function Knowledge.PreviewBackstory(characterUUID, npcID, kind)
    kind = normalizeKind(kind)
    local descriptorID = Knowledge.BackstoryDescriptorID(kind)
    if not descriptorID then
        return { allowed = false, reason = "unknown_backstory_kind", kind = kind }
    end
    local result = Knowledge.PreviewDisclosure(
        characterUUID, npcID, descriptorID
    )
    result.kind = kind
    result.topicID = "backstory." .. kind
    return result
end

function Knowledge.DiscloseBackstory(characterUUID, npcID, kind, context)
    kind = normalizeKind(kind)
    local descriptorID = Knowledge.BackstoryDescriptorID(kind)
    if not descriptorID then return nil, "unknown_backstory_kind" end
    local existing = Knowledge.GetDescriptor
        and Knowledge.GetDescriptor(characterUUID, npcID, descriptorID) or nil
    if existing then
        return {
            kind = kind,
            topicID = "backstory." .. kind,
            descriptorID = descriptorID,
            alreadyKnown = true,
            changed = false,
        }
    end
    local result, reason = Knowledge.Disclose(
        characterUUID, npcID, descriptorID, context
    )
    if not result then return nil, reason end
    result.kind = kind
    result.topicID = "backstory." .. kind
    result.descriptorID = descriptorID
    return result
end

return Knowledge
