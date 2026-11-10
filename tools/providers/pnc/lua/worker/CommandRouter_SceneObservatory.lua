-- Generic Interaction Scene Observatory worker commands.
local Handler = {}
local SceneObservatory = require "worker/SceneObservatory"

function Handler.handle(context, command, payload)
    if command == "SCENE_OBSERVATORY_FIXTURE" then
        if type(payload) ~= "table" then
            return nil, "scene_observatory_fixture_must_be_object"
        end
        return SceneObservatory.fixture(context, payload)
    elseif command == "SCENE_OBSERVATORY_INSPECT" then
        if payload ~= nil and type(payload) ~= "table" then
            return nil, "scene_observatory_inspect_must_be_object"
        end
        return SceneObservatory.inspect(context, payload or {})
    end
    return false
end

return Handler
