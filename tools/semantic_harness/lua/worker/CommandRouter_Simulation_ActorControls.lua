-- Composes actor identity and relationship control catalogs for the Semantic Lab.

local ActorControls = {}
local IdentityControls = require "worker/CommandRouter_Simulation_IdentityControls"
local RelationshipControls = require "worker/CommandRouter_Simulation_RelationshipControls"

function ActorControls.append(add, context, persona, roles, traits, playerTraitOptions, bondKinds)
    IdentityControls.append(add, context, persona, roles, traits, playerTraitOptions)
    RelationshipControls.append(add, context, persona, traits, bondKinds)
end

return ActorControls
