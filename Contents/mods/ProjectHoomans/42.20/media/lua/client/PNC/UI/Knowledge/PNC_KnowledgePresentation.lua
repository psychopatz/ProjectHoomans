-- Descriptor-driven presentation helpers. This module intentionally receives
-- no provider access and never formats or requests authoritative truth.

PNC = PNC or {}
PNC.KnowledgePresentation = PNC.KnowledgePresentation or {}

local Presentation = PNC.KnowledgePresentation

local function words(value)
    value = tostring(value or "???")
    value = string.gsub(value, "[_%-%.]", " ")
    return string.gsub(value, "(%a)([%w']*)", function(first, rest)
        return string.upper(first) .. string.lower(rest)
    end)
end

function Presentation.FormatValue(value)
    if value == nil then return "???" end
    if type(value) == "boolean" then return value and "Yes" or "No" end
    if type(value) == "number" then return string.format("%.2f", value) end
    if type(value) == "table" then return value.label or value.name or value.id or "???" end
    return words(value)
end

function Presentation.FormatFact(fact)
    if type(fact) ~= "table" then return "???" end
    local value = Presentation.FormatValue(fact.value)
    if fact.status == "suspected" then return "Seems " .. value end
    if fact.status == "confirmed" then return value .. " • Confirmed" end
    return value
end

function Presentation.BuildDossierRows(snapshot)
    local rows = {}
    for _, category in ipairs(snapshot and snapshot.categories or {}) do
        local section = { id = category.id, title = words(category.id), rows = {} }
        for _, descriptor in ipairs(category.descriptors or {}) do
            section.rows[#section.rows + 1] = {
                descriptorID = descriptor.descriptorID,
                label = words(string.match(descriptor.descriptorID, "%.(.+)$") or descriptor.descriptorID),
                value = Presentation.FormatFact(descriptor),
                confidence = tonumber(descriptor.confidence) or 0,
                status = descriptor.status,
            }
        end
        if #section.rows > 0 then rows[#rows + 1] = section end
    end
    return rows
end

function Presentation.BuildDebugRows(snapshot, filter)
    local rows = {}
    filter = filter or {}
    for _, row in ipairs(snapshot and snapshot.rows or {}) do
        local known = row.known or nil
        local status = known and known.status or "unknown"
        if (not filter.status or filter.status == "all" or status == filter.status)
            and (not filter.category or filter.category == "all" or row.category == filter.category)
        then
            rows[#rows + 1] = {
                descriptorID = row.descriptorID, category = row.category or "orphaned",
                providerID = row.providerID or "unknown", privacy = row.privacy or "unknown",
                truth = filter.showTruth == true and Presentation.FormatValue(row.truth) or "Hidden",
                known = Presentation.FormatFact(known), status = status,
                confidence = known and tonumber(known.confidence) or 0,
                evidenceCount = #(row.evidence or {}), raw = row,
            }
        end
    end
    return rows
end

return Presentation
