-- Dynamic suggestion-button & actor-agnostic offer realizer.
-- Expands .convo offers and reusable OfferBlueprints through Lexicon + TokenFormatter
-- (supporting |list, pronouns, {end}, and context-gated `when` predicates).

PNC = PNC or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Realizer = PNC.ConvoEngine.OfferRealizer or {}
PNC.ConvoEngine.OfferRealizer = Realizer

local Lexicon = PNC.ConvoEngine.Lexicon
    or require "PNC/ConvoEngine/Lexicon"
local Formatter = PNC.ConvoEngine.TokenFormatter
    or require "PNC/ConvoEngine/TokenFormatter"

local function matchesWhen(when, ctx)
    if type(when) ~= "table" then return true end
    if type(ctx) ~= "table" then return false end
    for k, expected in pairs(when) do
        local actual = ctx[k]
        if type(expected) == "boolean" then
            if (actual == true) ~= expected then return false end
        elseif tostring(actual or "") ~= tostring(expected) then
            return false
        end
    end
    return true
end

local function expandOffer(offer, context, tokens, opts)
    local lang = type(opts) == "table" and opts.language or nil
    local salt = (type(opts) == "table" and opts.salt or "") .. ":" .. tostring(offer.id or "")
    local label = Lexicon.Expand(offer.label or "", context, tokens, { language = lang, salt = salt })
    local say = Lexicon.Expand(offer.say or "", context, tokens, { language = lang, salt = salt })
    return {
        id = offer.id,
        label = label,
        say = say,
        intent = offer.intent,
        subject = offer.subject,
        claim = offer.claim,
        style = offer.style,
        utility = offer.utility,
    }
end

function Realizer.BuildForPool(poolID, context, tokens, opts)
    opts = type(opts) == "table" and opts or {}
    local maxOffers = tonumber(opts.maxOffers) or 6
    local out = {}
    local seen = {}

    local function collectList(list)
        if type(list) ~= "table" then return end
        for i = 1, #list do
            if #out >= maxOffers then return end
            local offer = list[i]
            if type(offer) == "table" and offer.id and not seen[offer.id] then
                if matchesWhen(offer.when, context) then
                    seen[offer.id] = true
                    out[#out + 1] = expandOffer(offer, context, tokens, opts)
                end
            end
        end
    end

    local genOffers = PNC.ConvoEngine.GeneratedOffers or {}
    local genUses = PNC.ConvoEngine.GeneratedOfferUses or {}
    local blueprints = PNC.ConvoEngine.OfferBlueprints or {}

    collectList(genOffers[tostring(poolID or "")])
    local uses = genUses[tostring(poolID or "")]
    if type(uses) == "table" then
        for i = 1, #uses do
            collectList(blueprints[uses[i]])
        end
    end
    return out
end

-- Actor-agnostic autonomous offer picker for NPCs / Colonists.
function Realizer.PickAutonomous(offers, disposition, context)
    if type(offers) ~= "table" or #offers == 0 then return nil end
    disposition = type(disposition) == "table" and disposition or {}
    context = type(context) == "table" and context or {}
    local compassion = tonumber(disposition.compassion) or 0.5
    local sociability = tonumber(disposition.sociability) or 0.5
    local aggression = tonumber(disposition.aggression) or 0.4
    local bravery = tonumber(disposition.bravery) or 0.5

    local best, bestScore = nil, -math.huge
    for i = 1, #offers do
        local o = offers[i]
        local u = tostring(o.utility or "")
        local score = 0.5
        if u == "openness" or u == "compassion" then
            score = sociability * 0.55 + compassion * 0.45
        elseif u == "deception" then
            score = (1 - compassion) * 0.5 + aggression * 0.3 + bravery * 0.2
        elseif u == "caution" then
            score = (1 - sociability) * 0.5 + (context.isNightOrDusk and 0.25 or 0)
        elseif u == "assertive" then
            score = bravery * 0.55 + aggression * 0.45
        end
        if score > bestScore then
            best, bestScore = o, score
        end
    end
    return best
end

return Realizer
