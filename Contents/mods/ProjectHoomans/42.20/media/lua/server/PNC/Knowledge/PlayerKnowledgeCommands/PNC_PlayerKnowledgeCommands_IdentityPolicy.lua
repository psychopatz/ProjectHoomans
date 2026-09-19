-- Server-only relationship consequences for semantic identity exchanges.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Identity = require "PNC/Semantics/PNC_SemanticIdentityExchange"
local Policy = {}

function Policy.EffectFor(kind, truthful)
    if kind == Identity.EVENT_CLAIM then
        if truthful == true then
            return {
                memoryType = "identity_introduction",
                interactionType = "identity_introduction",
                approval = 1,
                respect = 2,
                familiarity = 6,
                decayPerDay = 0.02,
                tags = { identity = true, truthful = true },
            }
        end
        if truthful == false then
            return {
                memoryType = "identity_deception",
                interactionType = "identity_deception",
                approval = -4,
                respect = -6,
                familiarity = 1,
                decayPerDay = 0.01,
                tags = {
                    identity = true,
                    deception = true,
                    untrustworthy = true,
                },
            }, Identity.TRUST_UNTRUSTWORTHY
        end
        return nil, nil, "identity_truth_unresolved"
    end

    if kind == Identity.EVENT_EVASION then
        return {
            memoryType = "identity_evasion",
            interactionType = "identity_evasion",
            approval = -2,
            respect = -3,
            familiarity = 0,
            decayPerDay = 0.01,
            tags = {
                identity = true,
                evasion = true,
                untrustworthy = true,
            },
        }, Identity.TRUST_UNTRUSTWORTHY
    end

    return nil, nil, "identity_event_invalid"
end

return Policy
