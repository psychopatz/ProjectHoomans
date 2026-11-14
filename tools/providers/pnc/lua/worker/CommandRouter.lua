-- JSON-lines command routing for one semantic worker session.

local CommandRouter = {}
local Router = require "worker/Router"
local TransportEvidence = require "worker/TransportEvidence"
local Session = require "worker/CommandRouter_Session"
local Conversation = require "worker/CommandRouter_Conversation"
local Projection = require "worker/CommandRouter_Projection"
local Authoring = require "worker/CommandRouter_Authoring"
local Knowledge = require "worker/CommandRouter_Knowledge"
local Persona = require "worker/CommandRouter_Persona"
local Simulation = require "worker/CommandRouter_Simulation"
local Talk = require "worker/CommandRouter_Talk"
local CombatObservatory = require "worker/CommandRouter_CombatObservatory"
local SceneObservatory = require "worker/CommandRouter_SceneObservatory"
local InteractionLifecycle = require "worker/CommandRouter_InteractionLifecycle"
local ConvoProbe = require "worker/ConvoProbe"

local Handlers = {
    require "worker/EvidenceAcceptance",
    ConvoProbe,
    Session,
    Conversation,
    Projection,
    Authoring,
    Knowledge,
    Persona,
    Simulation,
    Talk,
    CombatObservatory,
    SceneObservatory,
    InteractionLifecycle,
}

function CommandRouter.hello(context)
    return Session.hello(context)
end

function CommandRouter.dispatch(context, request)
    return Router.dispatch(Handlers, context, request, TransportEvidence)
end

return CommandRouter
