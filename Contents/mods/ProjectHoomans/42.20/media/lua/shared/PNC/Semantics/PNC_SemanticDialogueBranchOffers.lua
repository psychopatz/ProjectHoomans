-- Compatibility façade for the shared semantic affordance contract.
-- Core owns offer normalization; PNC keeps this path for existing callers.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Offers = require "PsychopatzCore/Semantics/PsychopatzSemanticOffer"
PNC.Semantics.DialogueBranchOffers = Offers

return Offers
