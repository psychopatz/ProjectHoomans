-- Contextual response variants for queued command acknowledgements.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

require "PNC/Semantics/PNC_SemanticCommandAdapter_Registry"
local Adapter = PNC.Semantics.CommandAdapter

-- Generated command flows use the shared response catalog selector. These
-- reviewed variants let the same generated template honor the registered
-- relationship/personality snapshot without putting branching or effects in
-- the generator or the command adapter.
local CONTEXTUAL_QUEUED_RESPONSES = {
    FOLLOW = {
        friendly = { when = { socialStyle = "friendly" }, priority = 2 },
        trusted = {
            when = { relationshipState = {
                "Friend", "Trusted", "Ally", "Member", "Lover",
            } },
            priority = 3,
        },
        withdrawn = { when = { socialStyle = "withdrawn" }, priority = 1 },
        repeated = { when = { previousAction = "FOLLOW" }, priority = 4 },
    },
    STAY = {
        friendly = { when = { socialStyle = "friendly" }, priority = 2 },
        trusted = {
            when = { relationshipState = {
                "Friend", "Trusted", "Ally", "Member", "Lover",
            } },
            priority = 3,
        },
        withdrawn = { when = { socialStyle = "withdrawn" }, priority = 1 },
        repeated = { when = { previousAction = "STAY" }, priority = 4 },
    },
    STOP = {
        friendly = { when = { socialStyle = "friendly" }, priority = 2 },
        trusted = {
            when = { relationshipState = {
                "Friend", "Trusted", "Ally", "Member", "Lover",
            } },
            priority = 3,
        },
        withdrawn = { when = { socialStyle = "withdrawn" }, priority = 1 },
        repeated = { when = { previousAction = "STOP" }, priority = 4 },
    },
    GO = {
        friendly = { when = { socialStyle = "friendly" }, priority = 2 },
        trusted = {
            when = { relationshipState = {
                "Friend", "Trusted", "Ally", "Member", "Lover",
            } },
            priority = 3,
        },
        withdrawn = { when = { socialStyle = "withdrawn" }, priority = 1 },
        repeated = { when = { previousAction = "GO" }, priority = 4 },
    },
    CAMP = {
        friendly = { when = { socialStyle = "friendly" }, priority = 2 },
        trusted = {
            when = { relationshipState = {
                "Friend", "Trusted", "Ally", "Member", "Lover",
            } },
            priority = 3,
        },
        withdrawn = { when = { socialStyle = "withdrawn" }, priority = 1 },
        repeated = { when = { previousAction = "CAMP" }, priority = 4 },
    },
}

local function attachContextualQueuedResponses()
    for action, variants in pairs(CONTEXTUAL_QUEUED_RESPONSES) do
        local definition = Adapter.Actions[action]
        local response = definition and definition.responsePools
            and definition.responsePools.queued
        if response then
            response.variants = {
                {
                    id = "friendly",
                    when = variants.friendly.when,
                    priority = variants.friendly.priority,
                },
                {
                    id = "trusted",
                    when = variants.trusted.when,
                    priority = variants.trusted.priority,
                },
                {
                    id = "withdrawn",
                    when = variants.withdrawn.when,
                    priority = variants.withdrawn.priority,
                },
                {
                    id = "repeated",
                    when = variants.repeated.when,
                    priority = variants.repeated.priority,
                },
            }
        end
    end
end

attachContextualQueuedResponses()

return Adapter
