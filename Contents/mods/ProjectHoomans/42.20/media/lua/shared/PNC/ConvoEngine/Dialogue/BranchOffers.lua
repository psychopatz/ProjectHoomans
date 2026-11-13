-- Compatibility façade for the shared semantic affordance contract.
-- Core owns offer normalization; PNC keeps this path for existing callers.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Offers = require "PsychopatzCore/ConvoEngine/Offer"
PNC.ConvoEngine.DialogueBranchOffers = Offers

return Offers
