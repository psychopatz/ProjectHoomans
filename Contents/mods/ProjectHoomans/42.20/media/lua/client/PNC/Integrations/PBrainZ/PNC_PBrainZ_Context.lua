-- Public context API facade.
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_Runtime"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_ActorIdentity"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_ContextActors"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_ContextHistory"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_ContextNeeds"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_ContextTools"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_Identity"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_ContextPayload"

PNC = PNC or {}
PNC.PBrainZ = PNC.PBrainZ or {}
PNC.PBrainZ.Context = PNC.PBrainZ.Context or {}

local Context = PNC.PBrainZ.Context
local Internal = PNC.PBrainZ.Internal
local Actors = Internal.ContextActors
local Needs = Internal.ContextNeeds
local Tools = Internal.ContextTools
local Identity = PNC.PBrainZ.Identity
local Payload = Internal.ContextPayload

function Context.Build(view, message)
    return Payload.Build(view, message)
end

function Context.GetAudioPresentation(source)
    return Actors.AudioPresentation(source)
end

function Context.ResetTransientState()
    Needs.Reset()
end

function Context.GetMemoryIdentity()
    return Identity.Current()
end

function Context.GetToolDefinitions(entry)
    return Tools.GetDefinitions(entry)
end

return Context
