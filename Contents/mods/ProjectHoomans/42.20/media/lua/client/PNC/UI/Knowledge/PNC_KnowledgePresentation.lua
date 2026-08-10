-- Descriptor-driven presentation helpers. This module intentionally receives
-- no provider access and never formats or requests authoritative truth.

PNC = PNC or {}
PNC.KnowledgePresentation = PNC.KnowledgePresentation or {}
PNC.KnowledgeUIRenderers = PNC.KnowledgeUIRenderers or {}

local Presentation = PNC.KnowledgePresentation
local Renderers = PNC.KnowledgeUIRenderers

Presentation.DOSSIER_HIDDEN_CATEGORIES =
    Presentation.DOSSIER_HIDDEN_CATEGORIES or {
        capabilities = true,
    }

Renderers.byValueType = Renderers.byValueType or {}
function Renderers.Register(valueType, renderer)
    if type(valueType) ~= "string" or type(renderer) ~= "function" then return false end
    Renderers.byValueType[valueType] = renderer
    return true
end

local function words(value)
    -- Kahlua's string.gsub callback handling differs from stock Lua in some
    -- game builds. Keep this formatter callback-free so dossier refresh cannot
    -- fail while converting descriptor IDs such as personality.social_style.
    local text = tostring(value or "???")
    local output = {}
    local uppercaseNext = true
    for index = 1, #text do
        local character = string.sub(text, index, index)
        if character == "_" or character == "-" or character == "." then
            output[#output + 1] = " "
            uppercaseNext = true
        elseif uppercaseNext then
            output[#output + 1] = string.upper(character)
            uppercaseNext = false
        else
            output[#output + 1] = string.lower(character)
        end
    end
    return table.concat(output)
end

function Presentation.FormatValue(value)
    if value == nil then return "???" end
    if type(value) == "boolean" then return value and "Yes" or "No" end
    if type(value) == "number" then return string.format("%.2f", value) end
    if type(value) == "table" then return value.label or value.name or value.id or "???" end
    return words(value)
end

local function confidenceBand(confidence)
    confidence = tonumber(confidence) or 0
    if confidence < .30 then return "Maybe" end
    if confidence < .55 then return "Possibly" end
    if confidence < .80 then return "Seems" end
    return "Probably"
end

for _, valueType in ipairs({ "categorical", "boolean", "band", "scalar", "text_enum", "entity_reference" }) do
    Renderers.Register(valueType, function(model)
        return Presentation.FormatValue(model.value)
    end)
end

function Presentation.FormatFact(fact)
    if type(fact) ~= "table" then return "???" end
    local renderer = Renderers.byValueType[fact.valueType]
    local value = renderer and renderer(fact) or Presentation.FormatValue(fact.value)
    if fact.status == "suspected" then return confidenceBand(fact.confidence) .. " " .. value end
    if fact.status == "confirmed" then return value .. " • Confirmed" end
    return value
end

function Presentation.BuildDossierRows(snapshot)
    local rows = {}
    for _, category in ipairs(snapshot and snapshot.categories or {}) do
        if not Presentation.DOSSIER_HIDDEN_CATEGORIES[category.id] then
            local section = {
                id = category.id,
                title = words(category.id),
                rows = {},
            }
            for _, descriptor in ipairs(category.descriptors or {}) do
                section.rows[#section.rows + 1] = {
                    descriptorID = descriptor.descriptorID,
                    label = words(string.match(
                        descriptor.descriptorID, "%.(.+)$"
                    ) or descriptor.descriptorID),
                    value = Presentation.FormatFact(descriptor),
                    confidence = tonumber(descriptor.confidence) or 0,
                    status = descriptor.status,
                    sourceSummary = descriptor.primarySource,
                    tooltipLines = {
                        descriptor.descriptorID,
                        "Based on: " .. tostring(
                            descriptor.primarySource or "your observations"
                        ),
                    },
                }
            end
            if #section.rows > 0 then rows[#rows + 1] = section end
        end
    end
    return rows
end

local function knownFacts(snapshot)
    local output = {}
    for _, category in ipairs(snapshot and snapshot.categories or {}) do
        for _, descriptor in ipairs(category.descriptors or {}) do
            if descriptor.descriptorID then
                output[tostring(descriptor.descriptorID)] = descriptor
            end
        end
    end
    return output
end

function Presentation.GetNewFacts(previous, current)
    local output = {}
    if type(previous) ~= "table" or type(current) ~= "table" then
        return output
    end
    local before = knownFacts(previous)
    for descriptorID, descriptor in pairs(knownFacts(current)) do
        if not before[descriptorID] then
            output[#output + 1] = descriptor
        end
    end
    table.sort(output, function(left, right)
        return tostring(left.descriptorID) < tostring(right.descriptorID)
    end)
    return output
end

function Presentation.GetFactLabel(descriptor)
    local descriptorID = tostring(
        descriptor and descriptor.descriptorID or "information"
    )
    local skillID = string.match(descriptorID, "^skill%.(.+)$")
    local skill = skillID and PNC.SkillCatalog
        and PNC.SkillCatalog.Find and PNC.SkillCatalog.Find(skillID) or nil
    if skill and skill.display then return tostring(skill.display) end
    return words(string.match(descriptorID, "%.(.+)$") or descriptorID)
end

function Presentation.ShowLearnedFacts(previous, current)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    if not player or not HaloTextHelper
        or not HaloTextHelper.addTextWithArrow
    then return 0 end
    local facts = Presentation.GetNewFacts(previous, current)
    for _, descriptor in ipairs(facts) do
        local label = Presentation.GetFactLabel(descriptor)
        local message = getText
            and getText("UI_PNC_KnowledgeLearned", label) or nil
        if not message or message == ""
            or message == "UI_PNC_KnowledgeLearned"
        then message = "Learned: " .. label end
        HaloTextHelper.addTextWithArrow(
            player,
            message,
            true,
            HaloTextHelper.getColorGreen()
        )
    end
    return #facts
end

function Presentation.GetFact(snapshot, descriptorID)
    for _, category in ipairs(snapshot and snapshot.categories or {}) do
        for _, descriptor in ipairs(category.descriptors or {}) do
            if tostring(descriptor.descriptorID) == tostring(descriptorID)
                and descriptor.status ~= nil
            then return descriptor end
        end
    end
    return nil
end

function Presentation.GetKnownValue(snapshot, descriptorID, fallback)
    local fact = Presentation.GetFact(snapshot, descriptorID)
    return fact and fact.value ~= nil and fact.value or fallback
end

function Presentation.IsKnown(snapshot, descriptorID)
    return Presentation.GetFact(snapshot, descriptorID) ~= nil
end

function Presentation.BuildDossierModel(snapshot)
    local sections = Presentation.BuildDossierRows(snapshot)
    local tabs = { { id = "overview", title = "Overview" } }
    for _, section in ipairs(sections) do tabs[#tabs + 1] = { id = section.id, title = section.title } end
    if #(snapshot and snapshot.journalEntries or {}) > 0
        or #(snapshot and snapshot.manualNotes or {}) > 0
    then tabs[#tabs + 1] = { id = "notes", title = "Notes" } end
    return {
        identity = snapshot and snapshot.identity or {}, portrait = snapshot and snapshot.portrait or nil,
        relationship = snapshot and snapshot.relationship or nil, sections = sections, tabs = tabs,
        journalEntries = snapshot and snapshot.journalEntries or {}, manualNotes = snapshot and snapshot.manualNotes or {},
    }
end

function Presentation.BuildDebugRows(snapshot, filter)
    local rows = {}
    filter = filter or {}
    for _, row in ipairs(snapshot and snapshot.rows or {}) do
        local known = row.known or nil
        local status = known and known.status or "unknown"
        if (not filter.status or filter.status == "all" or status == filter.status)
            and (not filter.category or filter.category == "all" or row.category == filter.category)
            and (not filter.providerID or filter.providerID == "all" or row.providerID == filter.providerID)
        then
            rows[#rows + 1] = {
                descriptorID = row.descriptorID, category = row.category or "orphaned",
                providerID = row.providerID or "unknown", privacy = row.privacy or "unknown",
                truth = filter.showTruth == true and Presentation.FormatValue(row.truth) or "Hidden",
                known = Presentation.FormatFact(known), status = status,
                confidence = known and tonumber(known.confidence) or 0,
                evidenceCount = tonumber(row.evidenceCount) or #(row.evidence or {}), raw = row,
            }
        end
    end
    return rows
end

return Presentation
