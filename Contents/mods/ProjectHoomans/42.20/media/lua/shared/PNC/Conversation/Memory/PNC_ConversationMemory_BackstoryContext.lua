-- Bounded localized facts derived from the NPC identity seed and birth date.
PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local Memory = PNC.Conversation.Memory
local MAX_FACTS = 10
local KIND_ORDER = {
    "former_job",
    "hometown",
    "date_of_birth",
    "education",
    "hobby",
    "family_background",
    "value",
    "survival_origin",
    "tragedy",
    "fear",
}

local function birthContent(fact)
    local year = tonumber(fact.year)
    local month = tonumber(fact.month)
    local day = tonumber(fact.day)
    if not year or not month or not day then return nil end
    local output = string.format("%04d-%02d-%02d", year, month, day)
    local age = tonumber(fact.age)
    if age then
        output = output .. "; age " .. tostring(math.floor(age))
    end
    return output
end

function Memory.BuildBackstoryFacts(record, limit, language)
    local profile
    local facts
    local identity
    local identitySeed
    local ok
    local output = {}
    local maximum = math.max(
        0,
        math.min(MAX_FACTS, math.floor(tonumber(limit) or MAX_FACTS))
    )
    local index
    local kind
    local fact
    local content
    if maximum <= 0 or type(Memory.GetBackstoryProfile) ~= "function" then
        return output
    end
    if type(record) ~= "table" then return output end
    identity = type(record.identity) == "table" and record.identity or {}
    identitySeed = tonumber(identity.seed)
    if not identitySeed or identitySeed <= 0 then
        identitySeed = tonumber(record.identitySeed)
    end
    if not identitySeed or identitySeed <= 0 then return output end
    ok, profile = pcall(Memory.GetBackstoryProfile, record)
    if not ok then return output end
    facts = profile and profile.facts or nil
    if type(facts) ~= "table" then return output end
    for index = 1, #KIND_ORDER do
        if #output >= maximum then break end
        kind = KIND_ORDER[index]
        fact = facts[kind]
        if fact then
            if kind == "date_of_birth" then
                content = birthContent(fact)
            else
                ok, content = pcall(Memory.GetBackstoryText, fact, language)
                if not ok then content = nil end
                content = content or tostring(fact.value or "")
                content = Memory.RenderText(content, fact)
            end
            if type(content) == "string" and content ~= "" then
                output[#output + 1] = {
                    kind = kind,
                    truth_status = "known",
                    content = content,
                }
            end
        end
    end
    return output
end

-- Build only from the already-authorized per-player dossier projection.
-- `record` is used solely to localize a kind that the snapshot names; this
-- function never enumerates the generated profile and never accepts a seed
-- as authorization.
function Memory.BuildAuthorizedBackstoryFacts(
    record, snapshot, limit, language
)
    local output = {}
    local maximum = math.max(
        0,
        math.min(MAX_FACTS, math.floor(tonumber(limit) or MAX_FACTS))
    )
    if maximum <= 0 or type(snapshot) ~= "table" then return output end
    for _, category in ipairs(snapshot.categories or {}) do
        for _, descriptor in ipairs(category.descriptors or {}) do
            if #output >= maximum then return output end
            local presentation = descriptor.presentation or {}
            local kind = presentation.backstoryKind
            local status = tostring(descriptor.status or "")
            if kind and (status == "known" or status == "confirmed"
                or status == "suspected")
            then
                local fact = type(record) == "table"
                    and Memory.GetBackstory
                    and Memory.GetBackstory(record, kind) or nil
                local content = descriptor.value
                if fact then
                    if kind == "date_of_birth" then
                        content = birthContent(fact)
                    else
                        content = Memory.GetBackstoryText
                            and Memory.GetBackstoryText(fact, language)
                            or fact.value
                        content = content and Memory.RenderText(
                            content, fact
                        ) or nil
                    end
                end
                if type(content) == "string" and content ~= "" then
                    output[#output + 1] = {
                        kind = kind,
                        truth_status = status,
                        content = content,
                        value = descriptor.value,
                        descriptorID = descriptor.descriptorID,
                        authorized = true,
                    }
                end
            end
        end
    end
    return output
end

return true
