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
        friendly = { en = "Of course, I'll follow you.", tl = "Siyempre, susundan kita." },
        trusted = { en = "I know you. I'll follow.", tl = "Kilala kita. Susunod ako." },
        withdrawn = { en = "I'll follow.", tl = "Susunod ako." },
        repeated = { en = "I'm still following you.", tl = "Sinusundan pa rin kita." },
    },
    STAY = {
        friendly = { en = "Sure, I'll stay here.", tl = "Sige, mananatili ako rito." },
        trusted = { en = "All right, I'll stay.", tl = "Sige, mananatili ako." },
        withdrawn = { en = "Okay, I'll stay.", tl = "Sige, mananatili ako." },
        repeated = { en = "I'm already staying here.", tl = "Nananatili na ako rito." },
    },
    STOP = {
        friendly = { en = "Got it, I'll stop following.", tl = "Nakuha ko, titigil ako sa pagsunod." },
        trusted = { en = "Understood, I'll stop.", tl = "Naiintindihan ko, titigil ako." },
        withdrawn = { en = "Okay, I'll stop.", tl = "Sige, titigil ako." },
        repeated = { en = "I've already stopped following.", tl = "Tumigil na ako sa pagsunod." },
    },
    GO = {
        friendly = { en = "Sure, I'll head home.", tl = "Sige, uuwi ako." },
        trusted = { en = "All right, I'm heading home.", tl = "Sige, pauwi na ako." },
        withdrawn = { en = "I'll head home.", tl = "Uuwi ako." },
        repeated = { en = "I'm still heading home.", tl = "Pauwi pa rin ako." },
    },
    CAMP = {
        friendly = { en = "Sure, I'll set up camp there.", tl = "Sige, magse-set up ako ng kampo roon." },
        trusted = { en = "All right, I'll make camp there.", tl = "Sige, magtatayo ako ng kampo roon." },
        withdrawn = { en = "I'll set up camp there.", tl = "Magtatayo ako ng kampo roon." },
        repeated = { en = "I'm still setting up camp there.", tl = "Nagtatayo pa rin ako ng kampo roon." },
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
                    key = response.key .. "Friendly",
                    en = variants.friendly.en,
                    tl = variants.friendly.tl,
                    when = { socialStyle = "friendly" },
                    priority = 2,
                },
                {
                    id = "trusted",
                    key = response.key .. "Trusted",
                    en = variants.trusted.en,
                    tl = variants.trusted.tl,
                    when = {
                        relationshipState = {
                            "Friend", "Trusted", "Ally", "Member", "Lover",
                        },
                    },
                    priority = 3,
                },
                {
                    id = "withdrawn",
                    key = response.key .. "Withdrawn",
                    en = variants.withdrawn.en,
                    tl = variants.withdrawn.tl,
                    when = { socialStyle = "withdrawn" },
                    priority = 1,
                },
                {
                    id = "repeated",
                    key = response.key .. "Repeated",
                    en = variants.repeated.en,
                    tl = variants.repeated.tl,
                    when = { previousAction = action },
                    priority = 4,
                },
            }
        end
    end
end

attachContextualQueuedResponses()

return Adapter
