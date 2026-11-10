-- Composes persona inputs and derived relationship controls for the Semantic Lab.

local RelationshipControls = {}
local PersonaControls = require "worker/CommandRouter_Simulation_PersonaControls"
local RelationshipStateControls = require "worker/CommandRouter_Simulation_RelationshipStateControls"

function RelationshipControls.append(add, context, persona, traits, bondKinds)
    PersonaControls.append(add, context, persona, traits, bondKinds)
    RelationshipStateControls.append(add, context, persona)
end

return RelationshipControls
