-- Contextual semantic variants for queued companion-command acknowledgements.
-- Conditions remain capability metadata; wording lives in Conversation content.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

require "PNC/Semantics/PNC_SemanticCommandAdapter_Registry"
local Adapter = PNC.Semantics.CommandAdapter

local TEMPLATE_BASE = {
    FOLLOW = "semantic.command.follow.queued",
    STAY = "semantic.command.stay.queued",
    STOP = "semantic.command.stop_following.queued",
    GO = "semantic.command.return_home.queued",
    CAMP = "semantic.command.camp.queued",
}

local function attachContextualQueuedResponses()
    for action, base in pairs(TEMPLATE_BASE) do
        local definition = Adapter.Actions[action]
        local response = definition and definition.responsePools
            and definition.responsePools.queued
        if response then
            response.variants = {
                {
                    id = "friendly",
                    templateID = base .. ".friendly",
                    when = { socialStyle = "friendly" },
                    priority = 2,
                },
                {
                    id = "trusted",
                    templateID = base .. ".trusted",
                    when = {
                        relationshipState = {
                            "Friend", "Trusted", "Ally", "Member", "Lover",
                        },
                    },
                    priority = 3,
                },
                {
                    id = "withdrawn",
                    templateID = base .. ".withdrawn",
                    when = { socialStyle = "withdrawn" },
                    priority = 1,
                },
                {
                    id = "repeated",
                    templateID = base .. ".repeated",
                    when = { previousAction = action },
                    priority = 4,
                },
            }
        end
    end
end

attachContextualQueuedResponses()

return Adapter
