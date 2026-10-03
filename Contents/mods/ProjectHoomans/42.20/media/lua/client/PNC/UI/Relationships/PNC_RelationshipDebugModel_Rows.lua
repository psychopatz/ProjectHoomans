local Model = require "PNC/UI/Relationships/PNC_RelationshipDebugModel_Core"
require "PNC/UI/Relationships/PNC_RelationshipDebugModel_Identity"
require "PNC/UI/Relationships/PNC_RelationshipDebugModel_Detail"

local Internal = Model.Internal or {}
local row = Internal.row
local conversationDeltaFor = Internal.conversationDeltaFor
local appendIdentityRows = Internal.appendIdentityRows
local appendGraphRows = Internal.appendGraphRows
local appendRelationshipStateRows = Internal.appendRelationshipStateRows
local appendPersonalityRows = Internal.appendPersonalityRows
local appendReverseRows = Internal.appendReverseRows
local appendMemoryRows = Internal.appendMemoryRows
local appendActionRows = Internal.appendActionRows

function Model.BuildRows(
    snapshot,
    authorized,
    reason,
    graphEvaluation,
    conversationDelta,
    conversationDeltas
)
    local rows = {}
    local observer
    local target
    local relationship
    local profile
    local reverse
    local action
    local detail
    if authorized ~= true then
        return {
            row("Access", "Admin/debug mode required", "danger"),
        }
    end
    if not snapshot then
        return {
            row("Status", reason or "Select an observer and target",
                reason and "warning" or "textMuted"),
        }
    end
    observer = snapshot.observer or {}
    target = snapshot.target or {}
    relationship = snapshot.relationship or {}
    conversationDelta = conversationDeltaFor(
        snapshot,
        conversationDelta,
        conversationDeltas
    )
    if type(conversationDelta) == "table" and conversationDelta.after
    then
        relationship = conversationDelta.after
    end
    profile = observer.personality or {}
    appendIdentityRows(rows, snapshot, observer, target)
    graphEvaluation = appendGraphRows(rows, snapshot, graphEvaluation)
    appendRelationshipStateRows(
        rows, snapshot, observer, relationship, conversationDelta
    )
    appendPersonalityRows(rows, observer, profile)
    appendReverseRows(rows, snapshot)
    appendMemoryRows(rows, snapshot)
    appendActionRows(rows, snapshot)
    return rows
end

-- Sections deliberately preserve the separation between personal
-- relationship, personality, memories, conduct, and faction/tactical context.
-- The full row builder remains the single source of presentation data.
function Model.FilterRows(rows, section)
    if section == nil or section == "all" then return rows or {} end
    local output = {}
    local mode = nil
    local relationshipLabels = {
        ["Observer"] = true, ["Observer key"] = true,
        ["Target"] = true, ["Target key"] = true,
        ["Derived attitude"] = true, ["Selected interaction"] = true,
        ["Interaction score"] = true, ["Inside green region"] = true,
        ["Score components"] = true, ["Stored record"] = true,
        ["Approval"] = true, ["Respect"] = true,
        ["Familiarity"] = true, ["State"] = true,
        ["Previous state"] = true, ["Baseline approval"] = true,
        ["Baseline respect"] = true, ["Morale"] = true,
        ["Morale baseline"] = true, ["Reverse direction"] = true,
        ["  scores"] = true, ["  state"] = true,
    }
    local personalityLabels = {
        ["Personality"] = true,
        ["  orientation"] = true, ["  food preference"] = true,
        ["  romance style"] = true, ["  jealousy style"] = true,
        ["  social style"] = true, ["  identity seed"] = true,
        ["  archetype"] = true,
        ["  compassion"] = true, ["  sociability"] = true,
        ["  forgiveness"] = true, ["  bravery"] = true,
        ["  materialism"] = true, ["  aggression"] = true,
        ["  loyalty"] = true,
    }
    local diagnosticsLabels = {
        ["Snapshot world age"] = true, ["Revisions"] = true,
        ["Last interaction"] = true, ["Last evaluated"] = true,
    }
    for _, item in ipairs(rows or {}) do
        local label = tostring(item.label or "")
        local include = false
        if section == "relationship" then
            include = relationshipLabels[label] == true
        elseif section == "personality" then
            include = personalityLabels[label] == true
        elseif section == "context" then
            include = string.find(label, "faction", 1, true) ~= nil
                or string.find(label, "Faction", 1, true) ~= nil
                or label == "Player pacification"
        elseif section == "conduct" then
            if label == "Observer conduct" or label == "Target conduct" then
                mode = "conduct"
            elseif mode == "conduct" and string.sub(label, 1, 2) ~= "  " then
                mode = nil
            end
            include = mode == "conduct"
        elseif section == "memories" then
            if label == "Memories" then
                mode = "memories"
            elseif mode == "memories" and label == "Last trigger" then
                mode = nil
            end
            include = mode == "memories"
        elseif section == "trace" then
            if label == "Last trigger" then mode = "trace" end
            include = mode == "trace"
        elseif section == "diagnostics" then
            include = diagnosticsLabels[label] == true
        end
        if include then output[#output + 1] = item end
    end
    if #output == 0 then
        output[1] = row("Status", "No data for this section", "textMuted")
    end
    return output
end


return Model
