-- Personality and directed relationship validation for the P0B planner.

local Utils = require
    "PNC/Core/Persistence/PNC_Persistence/PNC_Persistence_ImportPlan_Utils"

local Social = {}

local function add(decisions, ...)
    return Utils.AddDecision(decisions, ...)
end

function Social.Build(raw, source, decisions)
    local value = source and source.social or raw and raw.social
    local targetKey
    local relationship
    local entriesValid = true
    local personalityValid = true
    local overridesValid = true
    local historyValid = true
    local memoriesValid = true
    if type(value) ~= "table" then
        add(decisions, "relationships", "quarantined", "social",
            "relationship_state_missing")
        return nil
    end
    if type(value.relationships) ~= "table" then
        entriesValid = false
        memoriesValid = false
        add(decisions, "relationships.entries", "quarantined",
            "social.relationships", "relationship_entries_missing")
    end
    if type(value.personality) ~= "table" then
        personalityValid = false
        add(decisions, "relationships.personality", "quarantined",
            "social.personality", "personality_missing")
    end
    if type(value.personalityOverrides) ~= "table" then
        overridesValid = false
        add(decisions, "relationships.personalityOverrides", "quarantined",
            "social.personalityOverrides", "personality_overrides_missing")
    end
    if type(value.recentEventIDs) ~= "table" then
        historyValid = false
        add(decisions, "relationships.recentEventIDs", "quarantined",
            "social.recentEventIDs", "social_event_history_missing")
    end
    if type(value.relationships) == "table" then
        for targetKey, relationship in pairs(value.relationships) do
            if type(targetKey) ~= "string"
                or type(relationship) ~= "table"
            then
                entriesValid = false
                add(decisions, "relationships.entries", "quarantined",
                    "social.relationships", "relationship_entry_invalid")
            elseif type(relationship.memories) ~= "table" then
                memoriesValid = false
                add(decisions, "relationships.memory", "quarantined",
                    "social.relationships." .. targetKey .. ".memories",
                    "relationship_memory_missing")
            end
        end
    end
    if entriesValid then
        add(decisions, "relationships.entries", "copied",
            "social.relationships", nil)
    end
    if memoriesValid then
        add(decisions, "relationships.memory", "copied",
            "social.relationships.*.memories", nil)
    end
    if personalityValid then
        add(decisions, "relationships.personality", "copied",
            "social.personality", nil)
    end
    if overridesValid then
        add(decisions, "relationships.personalityOverrides", "copied",
            "social.personalityOverrides", nil)
    end
    if historyValid then
        add(decisions, "relationships.recentEventIDs", "copied",
            "social.recentEventIDs", nil)
    end
    return {
        state = Utils.Copy(value),
        entries = Utils.Copy(value.relationships),
        personality = Utils.Copy(value.personality),
        personalityOverrides = Utils.Copy(value.personalityOverrides),
        recentEventIDs = Utils.Copy(value.recentEventIDs),
        revision = value.revision,
    }
end

return Social
