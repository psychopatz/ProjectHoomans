-- Project Hoomans thin adopter shim for PsychopatzCore's shared actor-agnostic OfferRealizer.
PNC = PNC or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local CoreRealizer = require "PsychopatzCore/ConvoEngine/OfferRealizer"
local Lexicon = PNC.ConvoEngine.Lexicon or require "PNC/ConvoEngine/Lexicon"

local Realizer = PNC.ConvoEngine.OfferRealizer or {}
PNC.ConvoEngine.OfferRealizer = Realizer

function Realizer.BuildForPool(poolID, context, tokens, opts)
    opts = type(opts) == "table" and opts or {}
    local merged = {}
    for k, v in pairs(opts) do merged[k] = v end
    merged.lexicon = merged.lexicon or Lexicon
    merged.generatedOffers = merged.generatedOffers or PNC.ConvoEngine.GeneratedOffers
    merged.generatedOfferUses = merged.generatedOfferUses or PNC.ConvoEngine.GeneratedOfferUses
    merged.offerBlueprints = merged.offerBlueprints or PNC.ConvoEngine.OfferBlueprints
    return CoreRealizer.BuildForPool(poolID, context, tokens, merged)
end

function Realizer.ScoreOffer(offer, disposition, context)
    return CoreRealizer.ScoreOffer(offer, disposition, context)
end

function Realizer.PickAutonomous(offers, disposition, context, opts)
    return CoreRealizer.PickAutonomous(offers, disposition, context, opts)
end

return Realizer
