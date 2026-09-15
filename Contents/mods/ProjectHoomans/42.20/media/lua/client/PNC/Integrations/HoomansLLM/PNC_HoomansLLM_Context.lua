-- Public context API facade.
require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_Runtime"
require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_ActorIdentity"
require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_ContextActors"
require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_ContextHistory"
require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_ContextNeeds"
require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_ContextTools"
require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_Identity"
require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_ContextPayload"

PNC = PNC or {}
PNC.HoomansLLM = PNC.HoomansLLM or {}
PNC.HoomansLLM.Context = PNC.HoomansLLM.Context or {}

local Context = PNC.HoomansLLM.Context
local Internal = PNC.HoomansLLM.Internal
local Actors = Internal.ContextActors
local Needs = Internal.ContextNeeds
local Tools = Internal.ContextTools
local Identity = PNC.HoomansLLM.Identity
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
