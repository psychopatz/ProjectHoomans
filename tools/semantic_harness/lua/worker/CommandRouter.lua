-- JSON-lines command routing for one semantic worker session.

local CommandRouter = {}
local Session = require "worker/CommandRouter_Session"
local Conversation = require "worker/CommandRouter_Conversation"
local Projection = require "worker/CommandRouter_Projection"
local Authoring = require "worker/CommandRouter_Authoring"
local Knowledge = require "worker/CommandRouter_Knowledge"
local Persona = require "worker/CommandRouter_Persona"
local Simulation = require "worker/CommandRouter_Simulation"
local Talk = require "worker/CommandRouter_Talk"

local Handlers = {
    Session,
    Conversation,
    Projection,
    Authoring,
    Knowledge,
    Persona,
    Simulation,
    Talk,
}

function CommandRouter.hello(context)
    return Session.hello(context)
end

function CommandRouter.dispatch(context, request)
    local command = request.command
    local payload = request.payload
    for index = 1, #Handlers do
        local result, failure, shouldQuit = Handlers[index].handle(
            context,
            command,
            payload
        )
        if result ~= false then
            return result, failure, shouldQuit
        end
    end
    return nil, "unknown_command:" .. tostring(command)
end

return CommandRouter
